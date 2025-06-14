import os
import socket
import subprocess
import json
import time
from typing import List, Dict, Any
import docker
from docker.client import DockerClient
from docker.models.containers import Container
from factorio_rcon import RCONClient
import requests

from communication_handler import CommunicationHandler, DataType
from models.defines import InventoryType
from models.position import Position
from step_parser import StepParser
from docker_manager import ensure_docker_running

class FleApiClient:
    """Client for accessing the Factorio Learning Environment API."""
    
    def __init__(self, base_url: str, timeout: int = 30):
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.session = requests.Session()
    
    def get_meta_data(self, agent_id: int) -> Dict[str, Any]:
        """Get meta data for the specified agent."""
        response = self.session.get(
            f"{self.base_url}/data/meta/{agent_id}",
            timeout=self.timeout
        )
        response.raise_for_status()
        return response.json()
    
    def get_state_data(self, agent_id: int) -> Dict[str, Any]:
        """Get state data for the specified agent."""
        response = self.session.get(
            f"{self.base_url}/data/state/{agent_id}",
            timeout=self.timeout
        )
        response.raise_for_status()
        return response.json()
    
    def get_map_data(self, agent_id: int) -> Dict[str, Any]:
        """Get map data for the specified agent."""
        response = self.session.get(
            f"{self.base_url}/data/map/{agent_id}",
            timeout=self.timeout
        )
        response.raise_for_status()
        return response.json()
    
    def wait_for_api_ready(self, max_attempts: int = 30, delay: float = 1.0) -> bool:
        """Wait for the API to become available."""
        for attempt in range(max_attempts):
            try:
                response = self.session.get(f"{self.base_url}/openapi/v1.json", timeout=5)
                if response.status_code == 200:
                    return True
            except (requests.ConnectionError, requests.Timeout):
                pass
            
            if attempt < max_attempts - 1:
                time.sleep(delay)
        
        return False

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

def wait_for_services(container: Container) -> tuple[str, int, str]:
    """Wait for both RCON and API services to be available for a container."""
    container.reload()  # ensure information is fresh
    ports_dict = container.attrs["NetworkSettings"]["Ports"]
    
    # Get RCON port mapping
    rcon_mapping = ports_dict.get("27015/tcp")
    if not rcon_mapping:
        raise ValueError(f"Container {container.name} has no 27015/tcp port mapping!")
    
    # Get API port mapping
    api_mapping = ports_dict.get("5000/tcp")
    if not api_mapping:
        raise ValueError(f"Container {container.name} has no 5000/tcp port mapping!")
    
    # Extract host and ports
    host_ip = rcon_mapping[0]["HostIp"]
    if host_ip == "0.0.0.0":
        host_ip = "127.0.0.1"
    
    rcon_port = int(rcon_mapping[0]["HostPort"])
    api_port = int(api_mapping[0]["HostPort"])
    api_url = f"http://{host_ip}:{api_port}"
    
    print(f"Waiting for services on {container.name}:")
    print(f"  - RCON: {host_ip}:{rcon_port}")
    print(f"  - API: {api_url}")
    
    # Wait for RCON
    if wait_for_rcon(host=host_ip, port=rcon_port, password="factorio", timeout=30.0):
        print(f"✅ RCON is ready")
    else:
        raise RuntimeError(f"❌ RCON timeout for {container.name}")
    
    # Wait for API
    api_client = FleApiClient(api_url)
    if api_client.wait_for_api_ready(max_attempts=30, delay=1.0):
        print(f"✅ API is ready")
    else:
        raise RuntimeError(f"❌ API timeout for {container.name}")
    
    return host_ip, rcon_port, api_url

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
    )

    # Wait for both RCON and API services to be ready
    host_ip, rcon_port, api_url = wait_for_services(container=containers[0])

    try:
        # Setup RCON client for commands and actions
        rcon_client = RCONClient(host_ip, rcon_port, "factorio")
        communication_handler = CommunicationHandler(rcon_client, 1)
        
        # Setup API client for data retrieval
        api_client = FleApiClient(api_url)

        # Initialize the game
        reset_response = rcon_client.send_command('/sc remote.call("FLE", "reset", 1)')
        setup_game_items(communication_handler)
        
        # Parse and execute steps
        steps_path = os.path.join(os.path.dirname(__file__), "steps_lab.lua")
        step_parser = StepParser(steps_path, communication_handler)
        step_parser.parse()

        # Get initial game data via API
        print("Fetching initial game data via API...")
        meta_data = api_client.get_meta_data(agent_id=1)
        map_data = api_client.get_map_data(agent_id=1)
        state_data = api_client.get_state_data(agent_id=1)

        # Execute actions via RCON
        execute_actions_response = rcon_client.send_command('/sc remote.call("FLE", "execute_actions")')
        print("Waiting 20 seconds for actions to be executed...")
        time.sleep(20)  # Wait for actions to be executed

        # Get final state data via API
        print("Fetching final game state via API...")
        final_state_data = api_client.get_state_data(agent_id=1)

        # meta = json.loads(meta_data)
        # game_map = json.loads(map_data)
        # state = json.loads(state_data)
        # final_state = json.loads(final_state_data)

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