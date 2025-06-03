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
            data1 = rcon_client.send_command('/sc remote.call("AICommands", "reset", 1)')
            data2 = rcon_client.send_command('/sc remote.call("AICommands", "electricity_data")')
            data3 = rcon_client.send_command('/sc remote.call("AICommands", "building_data")')
            data4 = rcon_client.send_command('/sc remote.call("AICommands", "resource_data")')
            data5 = rcon_client.send_command('/sc remote.call("AICommands", "character_data")')
            data18 = rcon_client.send_command('/sc remote.call("AICommands", "production_data")')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "coal", 500, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "burner-mining-drill", 50, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "stone-furnace", 50, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "transport-belt", 500, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "small-electric-pole", 100, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "assembling-machine-1", 20, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "pipe", 100, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "pipe-to-ground", 50, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "pumpjack", 5, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "oil-refinery", 5, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "chemical-plant", 5, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "inserter", 50, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "burner-inserter", 50, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "wooden-chest", 10, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "boiler", 2, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "steam-engine", 2, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"take", {0.5, -7.5}, "offshore-pump", 2, defines.inventory.fuel})')
            data10 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"craft", "boiler", 2})')

            # data6 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"walk", {25, 15}})')
            # # data7 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 2, {"walk", {25, -15}})')
            # # data8 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 3, {"walk", {-25, -15}})')
            # # data9 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 4, {"walk", {-25, 15}})')
            # # data11 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 2, {"take", {0.5, -7.5}, "coal", 50, defines.inventory.fuel})')
            # # data12 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 3, {"take", {0.5, -7.5}, "coal", 50, defines.inventory.fuel})')
            # # data13 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 4, {"take", {0.5, -7.5}, "coal", 50, defines.inventory.fuel})')
            # data13 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"build", {30.0, 21.0}, "burner-mining-drill", defines.direction.west})')
            # data13 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"put", {30.0, 21.0}, "coal", 5, defines.inventory.fuel})')
            # data13 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"build", {28.0, 21.0}, "stone-furnace", defines.direction.north})')
            # data13 = rcon_client.send_command('/sc remote.call("AICommands", "add_step", 1, {"put", {28.0, 21.0}, "coal", 3, defines.inventory.fuel})')
            data14 = rcon_client.send_command('/sc remote.call("AICommands", "execute_steps")')
            data11 = rcon_client.send_command('/sc remote.call("AICommands", "character_data")')


            steps_path = os.path.join(os.path.dirname(__file__), "steps.lua")
            if os.path.exists(steps_path):
                with open(steps_path, "r", encoding="utf-8") as steps_file:
                    steps = "{"

                    for line in steps_file:
                        line = line.strip()
                        if not line or line.startswith("--"):  # skip empty lines and Lua comments
                            continue
                        else:
                            steps = steps + line + ","

                    steps = steps + "}"
                    try:
                        response = rcon_client.send_command(
                            f'/sc remote.call("AICommands", "add_steps", 1, {steps})'
                        )
                        print(f"Sent steps\nResponse: {response}")
                    except Exception as e:
                        print(f"Failed to send steps: {e}")
            else:
                print(f"steps.lua not found at {steps_path}")

            data14 = rcon_client.send_command('/sc remote.call("AICommands", "execute_steps")')
            data15 = rcon_client.send_command('/sc remote.call("AICommands", "character_data")')
            data16 = rcon_client.send_command('/sc remote.call("AICommands", "building_data")')
            data17 = rcon_client.send_command('/sc remote.call("AICommands", "electricity_data")')
            data18 = rcon_client.send_command('/sc remote.call("AICommands", "production_data")')
            data19 = rcon_client.send_command('/sc remote.call("AICommands", "production_data")')

            data_dict1 = json.loads(data4)
            data_dict2 = json.loads(data15)
            data_dict3 = json.loads(data16)
            data_dict4 = json.loads(data17)
            data_dict5 = json.loads(data19)
    except Exception as e:
        print(f"Error during RCON communication: {e}")
        shutdown_factorio_instances(containers)
        client.images.remove(IMAGE, force=True)
        exit(1)

    shutdown_factorio_instances(containers)
    print("All Factorio instances have been shut down.")

    client.images.remove(IMAGE, force=True)
    print(f"Image {IMAGE} has been removed.")