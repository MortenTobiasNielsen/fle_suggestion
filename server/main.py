import os
import subprocess
from typing import List
import docker
from docker.models.containers import Container

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
            # stdout=subprocess.PIPE,
            # stderr=subprocess.PIPE,
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
    
    # 2. Create instances
    containers = create_factorio_instances(
        image_name = IMAGE,
        scenario_name = SCENARIO_NAME,
        instance_count= INSTANCE_COUNT, 
        first_udp_port = 34197,
        first_rcon_port = 27015,
    )

    def run_rcon(container_id, cmd):
        proc = subprocess.Popen(
            ['docker', 'exec',container_id,'rcon','/c',cmd],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        out, err = proc.communicate()
        return out

    # cmd1 = ['docker', 'exec', containers[0].short_id, 'rcon', '/c', 'remote.call("AICommands", "reset", 9)']
    result1 = run_rcon(containers[0].short_id, 'remote.call("AICommands", "reset", 9)')
    result2 = run_rcon(containers[0].short_id, 'remote.call("AICommands", "electricity_data")')
    result3 = run_rcon(containers[0].short_id, 'remote.call("AICommands", "building_data")')
    result4 = run_rcon(containers[0].short_id, 'remote.call("AICommands", "resource_data")')
    result5 = run_rcon(containers[0].short_id, 'remote.call("AICommands", "character_data")')

    # cmd1 = ['docker', 'exec', containers[0].short_id, 'rcon', '/c', '']
    # result2 = subprocess.run(cmd1, capture_output=True, text=True)

    # cmd1 = ['docker', 'exec', containers[0].short_id, 'rcon', '/c', 'remote.call("AICommands", "building_data")']
    # result3 = subprocess.run(cmd1, capture_output=True, text=True)

    # cmd1 = ['docker', 'exec', containers[0].short_id, 'rcon', '/c', 'remote.call("AICommands", "resource_data")']
    # result4 = subprocess.run(cmd1, capture_output=True, text=True)

    # cmd1 = ['docker', 'exec', containers[0].short_id, 'rcon', '/c', 'remote.call("AICommands", "character_data")']
    # result5 = subprocess.run(cmd1, capture_output=True, text=True)

    # print(result1.stdout)

    shutdown_factorio_instances(containers)
    print("All Factorio instances have been shut down.")