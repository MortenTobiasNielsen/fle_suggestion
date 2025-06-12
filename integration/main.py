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

def create_factorio_instances(
    image_name: str,
    scenario_name: str,
    instance_count: int = 3,
    first_udp_port: int = 34197,
    first_rcon_port: int = 27015,
) -> List[Container]:
    
    containers: List[Container] = []

    for i in range(0, instance_count):
        container_name = f'{image_name}-{i + 1}',
        udp_port = first_udp_port + i
        rcon_port = first_rcon_port + i

        command = [
            "/opt/factorio/bin/x64/factorio",
            "--start-server-load-scenario", scenario_name,
            "--server-settings", "/opt/factorio/config/server-settings.json",
            "--port", "34197",
            "--rcon-port", "27015",
            "--rcon-password", "factorio", # This needs to be the same as in the rconpw file
            "--mod-directory", "/opt/factorio/mods"
        ]
        ports = {
            "34197/udp": udp_port,
            "27015/tcp": rcon_port
        }
        container = client.containers.run(
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
            platform="linux/amd64",
        )

        print(f"Created Factorio instance: {container.name} (ID: {container.short_id})")

        containers.append(container)
    
    return containers

def shutdown_factorio_instances(containers: List[Container]) -> None:
    for container in containers:
        try:
            container.remove(force=True)
            print(f"Removed container {container.name} ( ID: {container.short_id})")
        except Exception as e:
            print(f"Failed to remove container {container.name} ( ID: {container.short_id}): {e}")

def wait_for_rcon(host: str, port: int, timeout: float = 30.0) -> bool:
    """
    Try to connect to (host, port) every second until timeout seconds elapse.
    Returns True if connection succeeded within timeout, False otherwise.
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            # Try a very short timeout on the socket connect itself so we retry quickly on REFUSED
            with socket.create_connection((host, port), timeout=1.0):
                return True
        except (ConnectionRefusedError, socket.timeout):
            # Not up yet: sleep a bit and retry
            time.sleep(1.0)
        except Exception as e:
            # Any other socket error (e.g. network unreachable) we also retry until timeout
            time.sleep(1.0)

    return False  # timed out

def wait_for_connection(container: Container):
        container.reload()  # ensure information is fresh
        ports_dict = container.attrs["NetworkSettings"]["Ports"]
        # Docker publishes container's internal 27015/tcp to some host port. It looks like:
        #   { "27015/tcp": [ { "HostIp": "0.0.0.0", "HostPort": "27015" } ], ... }
        mapping = ports_dict.get("27015/tcp")
        if not mapping:
            print(f"⚠️  Container {container.name} has no 27015/tcp port mapping! Skipping.")
            return

        host_ip   = mapping[0]["HostIp"]

        if host_ip == "0.0.0.0":
            host_ip = "127.0.0.1"

        host_port = int(mapping[0]["HostPort"])
        print(f"Waiting for RCON on {container.name} → {host_ip}:{host_port} ...")

        # (4) Actually wait (with a 30-second timeout, for example)
        if wait_for_rcon(host=host_ip, port=host_port, timeout=30.0):
            print(f"✅ Container {container.name} RCON is now up ({host_ip}:{host_port}).")
        else:
            print(f"❌ Timeout: container {container.name} RCON did not come up within 30s.")

class FLE:
    def __init__(self, image_name: str, scenario_name: str, docker_client: DockerClient, instance_id: int, udp_port: int, rcon_port: int, platform: str):
        self.docker_client: DockerClient = docker_client
        self.instance: Container = self.create_factorio_instance(instance_id, image_name, scenario_name, udp_port, rcon_port, platform)
        self.rcon_client: RCONClient = RCONClient("127.0.0.1", rcon_port, "factorio")

    def create_factorio_instance(
        self,
        id: int,
        image_name: str,
        scenario_name: str,
        udp_port: int,
        rcon_port: int,
        platform: str
    ) -> Container:
        
        container_name = f'{image_name}-{id}',

        command = [
            "/opt/factorio/bin/x64/factorio",
            "--start-server-load-scenario", scenario_name,
            "--server-settings", "/opt/factorio/config/server-settings.json",
            "--port", "34197",
            "--rcon-port", "27015",
            "--rcon-password", "factorio", # This needs to be the same as in the rconpw file
            "--mod-directory", "/opt/factorio/mods"
        ]
        ports = {
            "34197/udp": udp_port,
            "27015/tcp": rcon_port
        }
        container: Container = self.docker_client.containers.run(
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

        return container

    def shutdown_factorio_instance(container: Container) -> None:
        try:
            container.remove(force=True)
            print(f"Removed container {container.name} ( ID: {container.short_id})")
        except Exception as e:
            print(f"Failed to remove container {container.name} ( ID: {container.short_id}): {e}")

if __name__ == "__main__":
    IMAGE = "factorio_0.2.0"
    SCENARIO_NAME = "FLE_Lab_Easy"
    INSTANCE_COUNT = 1

    cmd = ["bash", "../server/image_check.sh", IMAGE]
    try:
        completed = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
            cwd=os.path.dirname(__file__),
            timeout=10
        )
        print("Build script output:\n", completed.stdout)
    except subprocess.TimeoutExpired as e:
        print(f"⏰ Command timed out after {e.timeout} s")
        print("This usually means that docker isn't running or is in a bad state. This might be solved by restarting your computer.")
        exit(1)
    except subprocess.CalledProcessError as e:
        print("❌ build.sh failed!") 
        print("Command:", " ".join(e.cmd))
        print("Exit code:", e.returncode)
        print("stdout:\n", e.stdout or "<no stdout>")
        print("stderr:\n", e.stderr or "<no stderr>")
        exit(1)

    client = docker.from_env(timeout=5)
    
    containers = create_factorio_instances(
        image_name = IMAGE,
        scenario_name = SCENARIO_NAME,
        instance_count= INSTANCE_COUNT, 
        first_udp_port = 34197,
        first_rcon_port = 27015,
    )

    # wait_for_connection(container=containers[0])


    try:
        rcon_client = RCONClient("127.0.0.1", 27015, "factorio")
        communication_handler = CommunicationHandler(rcon_client, 1)

        data1 = rcon_client.send_command('/sc remote.call("AICommands", "reset", 1)')
        
        steps_path = os.path.join(os.path.dirname(__file__), "steps_lab.lua")
        communication_handler.research("steel-axe")
        communication_handler.take(Position(0.5, -7.5), "coal", 500, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "burner-mining-drill", 50, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "stone-furnace", 50, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "transport-belt", 500, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "small-electric-pole", 100, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "assembling-machine-1", 20, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "pipe", 100, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "pipe-to-ground", 50, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "pumpjack", 5, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "oil-refinery", 5, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "chemical-plant", 5, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "inserter", 50, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "burner-inserter", 50, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "wooden-chest", 10, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "boiler", 2, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "steam-engine", 2, InventoryType.CHEST)
        communication_handler.take(Position(0.5, -7.5), "offshore-pump", 2, InventoryType.CHEST)
        step_parser = StepParser(steps_path, communication_handler)
        step_parser.parse()
    #     communication_handler.walk(Position(30.0, -20.0))
    #     communication_handler.mine(Position(30.5, -20.5), 121)
    #     communication_handler.walk(Position(0.0, 0.0))
        data2 = communication_handler.get_data(DataType.STATE, 150)
        data3 = communication_handler.get_data(DataType.META, 150)
        data4 = communication_handler.get_data(DataType.MAP, 150)

        data5 = rcon_client.send_command('/sc remote.call("AICommands", "execute_steps")')
        data6 = communication_handler.get_data(DataType.STATE, 150)

        meta = json.loads(data3)
        map = json.loads(data4)
        state = json.loads(data6)

        test = 1
    except Exception as e:
        print(f"Error during RCON communication: {e}")
        shutdown_factorio_instances(containers)
        client.images.remove(IMAGE, force=True)
        exit(1)

    shutdown_factorio_instances(containers)
    print("All Factorio instances have been shut down.")

    client.images.remove(IMAGE, force=True)
    print(f"Image {IMAGE} has been removed.")