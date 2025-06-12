import os
import socket
import subprocess
import json
import time
from typing import List
import docker
from docker.client import DockerClient
from docker.models.containers import Container
from factorio_rcon import RCONClient

from communication_handler import CommunicationHandler, DataType
from models.defines import InventoryType
from models.position import Position
from step_parser import StepParser
from docker_manager import ensure_docker_running

def wait_for_rcon(host: str, port: int, password: str = "factorio", timeout: float = 30.0) -> bool:
    """
    Try to connect and authenticate to RCON every few seconds until timeout seconds elapse.
    Returns True if RCON authentication succeeded within timeout, False otherwise.
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            # Try to create an RCON client and authenticate
            rcon_client = RCONClient(host, port, password)
            # Test with a simple command to verify RCON is working
            rcon_client.send_command("/time")
            return True
        except (ConnectionRefusedError, socket.timeout, OSError):
            # Connection refused or timeout - RCON not ready yet
            time.sleep(1.0)
        except Exception as e:
            # Any other error (authentication, protocol, etc.) - RCON not ready yet
            print(f"RCON not ready yet: {e}")
            time.sleep(1.0)

    return False  # timed out

def wait_for_connection(container: Container) -> None:
    """Wait for RCON connection to be available for a container."""
    container.reload()  # ensure information is fresh
    ports_dict = container.attrs["NetworkSettings"]["Ports"]
    # Docker publishes container's internal 27015/tcp to some host port. It looks like:
    #   { "27015/tcp": [ { "HostIp": "0.0.0.0", "HostPort": "27015" } ], ... }
    mapping = ports_dict.get("27015/tcp")
    if not mapping:
        print(f"⚠️  Container {container.name} has no 27015/tcp port mapping! Skipping.")
        return

    host_ip = mapping[0]["HostIp"]
    if host_ip == "0.0.0.0":
        host_ip = "127.0.0.1"

    host_port = int(mapping[0]["HostPort"])
    print(f"Waiting for RCON on {container.name} → {host_ip}:{host_port} ...")

    # Actually wait (with a 30-second timeout)
    if wait_for_rcon(host=host_ip, port=host_port, password="factorio", timeout=30.0):
        print(f"✅ Container {container.name} RCON is now up ({host_ip}:{host_port}).")
    else:
        print(f"❌ Timeout: container {container.name} RCON did not come up within 30s.")

def create_factorio_instance(
    docker_client: DockerClient,
    instance_id: int,
    image_name: str,
    scenario_name: str,
    udp_port: int,
    rcon_port: int,
    platform: str = "linux/amd64"
) -> Container:
    """Create a single Factorio instance container."""
    container_name = f'{image_name}-{instance_id}'

    command = [
        "/opt/factorio/bin/x64/factorio",
        "--start-server-load-scenario", scenario_name,
        "--server-settings", "/opt/factorio/config/server-settings.json",
        "--port", "34197",
        "--rcon-port", "27015",
        "--rcon-password", "factorio",  # This needs to be the same as in the rconpw file
        "--mod-directory", "/opt/factorio/mods"
    ]
    
    ports = {
        "34197/udp": udp_port,
        "27015/tcp": rcon_port
    }
    
    container = docker_client.containers.run(
        image=image_name,
        detach=True,
        ports=ports,
        name=container_name,
        entrypoint=[],
        command=command,
        labels={"group": "FLE"},
        user="factorio",
        mem_limit="1024m",
        nano_cpus=1_000_000_000,  # 1 CPU
        restart_policy={"Name": "unless-stopped"},
        platform=platform,
    )

    print(f"Created Factorio instance: {container.name} (ID: {container.short_id})")
    
    # Give the container a moment to start and check its status
    time.sleep(2)
    container.reload()
    
    status = container.status
    print(f"Container {container.name} status: {status}")
    
    if status == "exited":
        print(f"⚠️  Container {container.name} exited immediately. Checking logs...")
        logs = container.logs().decode('utf-8')
        print(f"Container logs:\n{logs}")
        print("This usually indicates a configuration or startup error.")
    
    return container

def create_factorio_instances(
    docker_client: DockerClient,
    image_name: str,
    scenario_name: str,
    instance_count: int = 3,
    first_udp_port: int = 34197,
    first_rcon_port: int = 27015,
    platform: str = "linux/amd64"
) -> List[Container]:
    """Create multiple Factorio instance containers."""
    containers: List[Container] = []

    for i in range(instance_count):
        instance_id = i + 1
        udp_port = first_udp_port + i
        rcon_port = first_rcon_port + i

        container = create_factorio_instance(
            docker_client=docker_client,
            instance_id=instance_id,
            image_name=image_name,
            scenario_name=scenario_name,
            udp_port=udp_port,
            rcon_port=rcon_port,
            platform=platform
        )
        containers.append(container)
    
    return containers

def shutdown_factorio_instances(containers: List[Container]) -> None:
    """Shutdown and remove multiple Factorio instance containers."""
    for container in containers:
        try:
            container.remove(force=True)
            print(f"Removed container {container.name} (ID: {container.short_id})")
        except Exception as e:
            print(f"Failed to remove container {container.name} (ID: {container.short_id}): {e}")

def run_image_check(image_name: str) -> None:
    """Run the image check script to ensure the Docker image exists."""
    script_path = os.path.join(os.path.dirname(__file__), "..", "server", "image_check.sh")
    script_path = os.path.abspath(script_path)
    
    # Try different ways to run bash on Windows
    bash_commands = []
    
    if os.name == 'nt':  # Windows
        # Try different bash locations on Windows
        bash_commands = [
            ["bash", script_path, image_name],
            ["C:\\Program Files\\Git\\bin\\bash.exe", script_path, image_name],
            ["C:\\Program Files (x86)\\Git\\bin\\bash.exe", script_path, image_name],
            ["wsl", "bash", script_path, image_name]
        ]
    else:
        # Unix-like systems
        bash_commands = [["bash", script_path, image_name]]
    
    last_error = None
    for cmd in bash_commands:
        try:
            print(f"Trying to run: {' '.join(cmd)}")
            completed = subprocess.run(
                cmd,
                check=True,
                cwd=os.path.dirname(__file__),
                timeout=30,
                capture_output=True,
                text=True
            )
            if completed.stdout:
                print("Build script output:\n", completed.stdout)
            if completed.stderr:
                print("Build script stderr:\n", completed.stderr)
            return  # Success, exit the function
            
        except FileNotFoundError as e:
            last_error = e
            continue
        except subprocess.TimeoutExpired as e:
            last_error = e
            continue
        except subprocess.CalledProcessError as e:
            last_error = e
            continue
    
    # If we get here, all attempts failed
    print("\n❌ Failed to run image check script with any available bash interpreter.")
    print("Please ensure one of the following is available:")
    print("  - Git Bash (recommended for Windows)")
    print("  - WSL (Windows Subsystem for Linux)")
    print("  - bash in your system PATH")
    print("\nAlternatively, you can run the image check manually:")
    print(f"  docker image inspect {image_name} || docker build -t {image_name} ../server")
    
    if last_error:
        raise last_error
    else:
        exit(1)

def setup_game_items(communication_handler: CommunicationHandler) -> None:
    """Setup initial game items and research."""
    # Research
    communication_handler.research("steel-axe")
    communication_handler.cancel_research()
    communication_handler.research("steel-axe")
    
    # Take items from chest
    chest_position = Position(0.5, -7.5)
    items_to_take = [
        ("coal", 500),
        ("burner-mining-drill", 50),
        ("stone-furnace", 50),
        ("transport-belt", 500),
        ("small-electric-pole", 100),
        ("assembling-machine-1", 20),
        ("pipe", 100),
        ("pipe-to-ground", 50),
        ("pumpjack", 5),
        ("oil-refinery", 5),
        ("chemical-plant", 5),
        ("inserter", 50),
        ("burner-inserter", 50),
        ("wooden-chest", 10),
        ("steam-engine", 2),
        ("offshore-pump", 2),
    ]
    
    for item_name, quantity in items_to_take:
        communication_handler.take(chest_position, item_name, quantity, InventoryType.CHEST)
    
    # Craft items
    communication_handler.craft("boiler", 2)
    communication_handler.cancel_craft("boiler", 1)

if __name__ == "__main__":
    IMAGE = "factorio_0.2.0"
    SCENARIO_NAME = "FLE_Lab"
    INSTANCE_COUNT = 1

    # Ensure Docker Desktop is running and get client
    docker_client = ensure_docker_running(timeout=60)

    run_image_check(IMAGE)

    containers = create_factorio_instances(
        docker_client = docker_client,
        image_name = IMAGE,
        scenario_name = SCENARIO_NAME,
        instance_count= INSTANCE_COUNT, 
        first_udp_port = 34197,
        first_rcon_port = 27015,
    )

    wait_for_connection(container=containers[0])

    try:
        rcon_client = RCONClient("127.0.0.1", 27015, "factorio")
        communication_handler = CommunicationHandler(rcon_client, 1)

        reset_response = rcon_client.send_command('/sc remote.call("FLE", "reset", 1)')
        setup_game_items(communication_handler)
        
        steps_path = os.path.join(os.path.dirname(__file__), "steps_lab.lua")
        step_parser = StepParser(steps_path, communication_handler)
        step_parser.parse()

        state_data = communication_handler.get_data(DataType.STATE, 150)
        meta_data = communication_handler.get_data(DataType.META, 150)
        map_data = communication_handler.get_data(DataType.MAP, 150)

        execute_actions_response = rcon_client.send_command('/sc remote.call("FLE", "execute_actions")')
        print("Waiting 20 seconds for actions to be executed...")
        time.sleep(20) # Wait for actions to be executed

        final_state_data = communication_handler.get_data(DataType.STATE, 150)

        meta = json.loads(meta_data)
        game_map = json.loads(map_data)
        state = json.loads(state_data)
        final_state = json.loads(final_state_data)

        print("Game session completed successfully.") # Put a breakpoint here to inspect the data
        
    except Exception as e:
        print(f"Error during RCON communication: {e}")
        shutdown_factorio_instances(containers)
        docker_client.images.remove(IMAGE, force=True)
        exit(1)

    shutdown_factorio_instances(containers)
    print("All Factorio instances have been shut down.")

    docker_client.images.remove(IMAGE, force=True)
    print(f"Image {IMAGE} has been removed.")