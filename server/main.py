import os
import subprocess
import json
from typing import List
import docker
from docker.models.containers import Container
from factorio_rcon import RCONClient

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

if __name__ == "__main__":
    IMAGE = "factorio_0.2.0"
    SCENARIO_NAME = "FLE_Lab_Easy"
    INSTANCE_COUNT = 1

    cmd = ["bash", "image_check.sh", IMAGE]
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

    try:
        with RCONClient("127.0.0.1", 27015, "factorio") as rcon_client:
            data1 = rcon_client.send_command('/sc remote.call("AICommands", "reset", 4)')
            data2 = rcon_client.send_command('/sc remote.call("AICommands", "electricity_data")')
            data3 = rcon_client.send_command('/sc remote.call("AICommands", "building_data")')
            data4 = rcon_client.send_command('/sc remote.call("AICommands", "resource_data")')
            data5 = rcon_client.send_command('/sc remote.call("AICommands", "character_data")')
            data6 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"walk", {25, -15}})')
            data7 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 2, {"walk", {25, 15}})')
            data8 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 3, {"walk", {-25, -15}})')
            data9 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 4, {"walk", {-25, 15}})')
            data6 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "coal", 50, defines.inventory.fuel})')
            data7 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 2, {"walk", {25, 15}})')
            data8 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 3, {"walk", {-25, -15}})')
            data9 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 4, {"walk", {-25, 15}})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "execute_steps"')
            data11 = rcon_client.send_command('/sc remote.call("AICommands", "character_data")')
            data12 = rcon_client.send_command('/sc remote.call("AICommands", "building_data")')
    except Exception as e:
        print(f"Error during RCON communication: {e}")
        shutdown_factorio_instances(containers)
        client.images.remove(IMAGE, force=True)
        exit(1)

    data_dict = json.loads(data4)

    shutdown_factorio_instances(containers)
    print("All Factorio instances have been shut down.")

    client.images.remove(IMAGE, force=True)
    print(f"Image {IMAGE} has been removed.")