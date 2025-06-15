import os
import subprocess
import json
import time
from typing import List, Dict, Any
import docker
from docker.client import DockerClient
from docker.models.containers import Container
import requests

from communication_handler import CommunicationHandler, DataType
from models.defines import InventoryType
from models.position import Position
from step_parser import StepParser
from docker_manager import ensure_docker_running

def wait_for_services(container: Container) -> str:
    """Wait for API service to be available for a container."""
    container.reload()  # ensure information is fresh
    ports_dict = container.attrs["NetworkSettings"]["Ports"]
    
    # Get API port mapping
    api_mapping = ports_dict.get("5000/tcp")
    if not api_mapping:
        raise ValueError(f"Container {container.name} has no 5000/tcp port mapping!")
    
    # Extract host and port
    host_ip = api_mapping[0]["HostIp"]
    if host_ip == "0.0.0.0":
        host_ip = "127.0.0.1"
    
    api_port = int(api_mapping[0]["HostPort"])
    api_url = f"http://{host_ip}:{api_port}"
    
    print(f"Waiting for API service on {container.name}:")
    print(f"  - API: {api_url}")
    
    # Wait for API
    communication_handler = CommunicationHandler(api_url, 1)
    if communication_handler.wait_for_api_ready(max_attempts=30, delay=1.0):
        print(f"✅ API is ready")
    else:
        raise RuntimeError(f"❌ API timeout for {container.name}")
    
    return api_url

def create_factorio_instance(
    docker_client: DockerClient,
    instance_id: int,
    image_name: str,
    scenario_name: str,
    udp_port: int,
    rcon_port: int,
    api_port: int = None,
    platform: str = "linux/amd64"
) -> Container:
    """Create a single Factorio instance container with both Factorio server and API."""
    container_name = f'{image_name}-{instance_id}'
    
    # Calculate API port if not provided
    if api_port is None:
        api_port = 5000 + (instance_id - 1)
    
    # Use environment variables to configure the services
    environment = {
        "SCENARIO_NAME": scenario_name,
        "FACTORIO_PORT": "34197",  # Internal port (always 34197 inside container)
        "RCON_PORT": "27015",      # Internal port (always 27015 inside container) 
        "RCON_PASSWORD": "factorio",
        "API_PORT": "5000"         # Internal port (always 5000 inside container)
    }
    
    ports = {
        "34197/udp": udp_port,     # Map internal 34197 to external udp_port
        "27015/tcp": rcon_port,    # Map internal 27015 to external rcon_port
        "5000/tcp": api_port       # Map internal 5000 to external api_port
    }
    
    container = docker_client.containers.run(
        image=image_name,
        detach=True,
        ports=ports,
        environment=environment,
        name=container_name,
        labels={"group": "FLE"},
        user="factorio",
        mem_limit="1024m",
        nano_cpus=1_000_000_000,  # 1 CPU
        restart_policy={"Name": "unless-stopped"},
        platform=platform,
    )

    print(f"Created Factorio+API instance: {container.name} (ID: {container.short_id})")
    print(f"  - Factorio: localhost:{udp_port} (UDP)")
    print(f"  - RCON: localhost:{rcon_port} (TCP)")
    print(f"  - API: http://localhost:{api_port}")
    
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
    first_api_port: int = 5000,
    platform: str = "linux/amd64"
) -> List[Container]:
    """Create multiple Factorio instance containers with both Factorio server and API."""
    containers: List[Container] = []

    for i in range(instance_count):
        instance_id = i + 1
        udp_port = first_udp_port + i
        rcon_port = first_rcon_port + i
        api_port = first_api_port + i

        container = create_factorio_instance(
            docker_client=docker_client,
            instance_id=instance_id,
            image_name=image_name,
            scenario_name=scenario_name,
            udp_port=udp_port,
            rcon_port=rcon_port,
            api_port=api_port,
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
    script_path = os.path.join(os.path.dirname(__file__), "..", "image_check.sh")
    script_path = os.path.abspath(script_path)
    
    commands = []
    
    if os.name == 'nt':  # Windows
        commands = [
            ["bash", script_path, image_name],
            ["C:\\Program Files\\Git\\bin\\bash.exe", script_path, image_name],
            ["C:\\Program Files (x86)\\Git\\bin\\bash.exe", script_path, image_name],
            ["wsl", "bash", script_path, image_name]
        ]
    else:
        # Unix-like systems
        commands = [
            f"zsh {script_path} {image_name}",
            f"bash {script_path} {image_name}",
            f"sh {script_path} {image_name}",
            ["zsh", script_path, image_name],
            ["bash", script_path, image_name],
            ["sh", script_path, image_name]
        ]
    
    last_error = None
    for cmd in commands:
        try:
            if isinstance(cmd, str):
                print(f"Trying to run: {cmd}")
                completed = subprocess.run(
                    cmd,
                    shell=True,
                    check=True,
                    cwd=os.path.dirname(__file__),
                    timeout=300  # Increased timeout for Docker builds
                )
            else:
                print(f"Trying to run: {' '.join(cmd)}")
                completed = subprocess.run(
                    cmd,
                    check=True,
                    cwd=os.path.dirname(__file__),
                    timeout=300  # Increased timeout for Docker builds
                )
            print("✅ Build script completed successfully!")
            return  # Success, exit the function
            
        except FileNotFoundError as e:
            print(f"❌ Command not found: {e}")
            last_error = e
            continue
        except subprocess.TimeoutExpired as e:
            print(f"❌ Command timed out after 300 seconds: {e}")
            last_error = e
            continue
        except subprocess.CalledProcessError as e:
            print(f"❌ Command failed with exit code {e.returncode}")
            last_error = e
            continue
    
    # If we get here, all attempts failed
    print("\n❌ Failed to run image check script with any available interpreter.")
    print("Please ensure one of the following is available:")
    print("  - zsh (default on macOS)")
    print("  - bash")
    print("  - sh")
    print("  - Git Bash (for Windows)")
    print("  - WSL (Windows Subsystem for Linux)")
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
    communication_handler.craft("boiler", 10)
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
        first_api_port = 5000,
    )

    # Wait for API service to be ready
    api_url = wait_for_services(container=containers[0])

    try:
        # Setup API-based communication handler for agent 1
        communication_handler = CommunicationHandler(api_url, 1)

        # Initialize the game
        print("Resetting game state via API...")
        reset_response = communication_handler.reset(agent_count=1)
        print(f"Reset response: {reset_response}")

        # Get initial game data via API
        print("Fetching initial game data via API...")
        meta_data = communication_handler.get_data(DataType.META)
        map_data = communication_handler.get_data(DataType.MAP)
        state_data = communication_handler.get_data(DataType.STATE)

        setup_game_items(communication_handler)
        # Parse and queue additional steps
        steps_path = os.path.join(os.path.dirname(__file__), "steps_lab.lua")
        step_parser = StepParser(steps_path, communication_handler)
        step_parser.parse()
        
        # Send parsed actions via API
        print("Sending parsed actions via API...")
        parsed_actions_response = communication_handler.send_actions()
        print(f"Parsed actions sent: {parsed_actions_response}")

        # Execute all queued actions
        print("Executing all queued actions...")
        execute_response = communication_handler.execute_actions()
        print(f"Actions executed: {execute_response}")

        # Get final state data via API
        print("Fetching final game state via API...")
        final_state_data = communication_handler.get_data(DataType.STATE)

        print("Game session completed successfully.") # Put a breakpoint here to inspect the data
        
    except requests.RequestException as e:
        print(f"❌ Error during API communication: {e}")
        shutdown_factorio_instances(containers)
        docker_client.images.remove(IMAGE, force=True)
        exit(1)
    except Exception as e:
        print(f"❌ Error during execution: {e}")
        shutdown_factorio_instances(containers)
        docker_client.images.remove(IMAGE, force=True)
        exit(1)

    shutdown_factorio_instances(containers)
    print("All Factorio instances have been shut down.")

    docker_client.images.remove(IMAGE, force=True)
    print(f"Image {IMAGE} has been removed.")