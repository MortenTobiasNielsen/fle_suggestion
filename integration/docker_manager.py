"""
Docker Desktop Manager - Cross-platform utility for managing Docker Desktop
Handles waking Docker Desktop from Resource Saver Mode and checking Docker status
"""

import os
import sys
import time
import subprocess
import platform
from typing import Tuple
import docker
from docker.client import DockerClient


class DockerManager:
    """Cross-platform Docker Desktop manager."""
    
    def __init__(self, timeout: int = 60):
        self.timeout = timeout
        self.system = platform.system().lower()
        
    def is_docker_running(self) -> bool:
        """Check if Docker daemon is running."""
        try:
            client = docker.from_env(timeout=5)
            client.ping()
            return True
        except Exception:
            return False
    
    def is_docker_desktop_installed(self) -> bool:
        """Check if Docker Desktop is installed on the system."""
        if self.system == "windows":
            # Check for Docker Desktop executable
            docker_paths = [
                os.path.expandvars(r"%ProgramFiles%\Docker\Docker\Docker Desktop.exe"),
                os.path.expandvars(r"%LocalAppData%\Programs\Docker\Docker\Docker Desktop.exe")
            ]
            return any(os.path.exists(path) for path in docker_paths)
        
        elif self.system == "darwin":  # macOS
            return os.path.exists("/Applications/Docker.app")
        
        elif self.system == "linux":
            # Docker Desktop for Linux
            return (
                os.path.exists("/opt/docker-desktop") or
                subprocess.run(["which", "docker-desktop"], capture_output=True).returncode == 0
            )
        
        return False
    
    def wake_docker_desktop_windows(self) -> bool:
        """Wake Docker Desktop on Windows."""
        try:
            # Try to start Docker Desktop executable
            docker_paths = [
                os.path.expandvars(r"%ProgramFiles%\Docker\Docker\Docker Desktop.exe"),
                os.path.expandvars(r"%LocalAppData%\Programs\Docker\Docker\Docker Desktop.exe")
            ]
            
            for docker_path in docker_paths:
                if os.path.exists(docker_path):
                    print(f"Starting Docker Desktop: {docker_path}")
                    subprocess.Popen([docker_path], shell=False)
                    return True
            
            # Alternative: Try PowerShell approach
            powershell_cmd = '''
            $dockerDesktop = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
            if (-not $dockerDesktop) {
                Start-Process "Docker Desktop" -WindowStyle Hidden
            }
            '''
            subprocess.run(["powershell", "-Command", powershell_cmd], check=True)
            return True
            
        except Exception as e:
            print(f"Failed to start Docker Desktop on Windows: {e}")
            return False
    
    def wake_docker_desktop_macos(self) -> bool:
        """Wake Docker Desktop on macOS."""
        try:
            # Use open command to start Docker Desktop
            subprocess.run(["open", "/Applications/Docker.app"], check=True)
            return True
        except Exception as e:
            print(f"Failed to start Docker Desktop on macOS: {e}")
            return False
    
    def wake_docker_desktop_linux(self) -> bool:
        """Wake Docker Desktop on Linux."""
        try:
            # Try different approaches for Linux
            commands_to_try = [
                ["docker-desktop"],
                ["systemctl", "--user", "start", "docker-desktop"],
                ["/opt/docker-desktop/bin/docker-desktop"]
            ]
            
            for cmd in commands_to_try:
                try:
                    subprocess.run(cmd, check=True, capture_output=True)
                    return True
                except (subprocess.CalledProcessError, FileNotFoundError):
                    continue
                    
            return False
        except Exception as e:
            print(f"Failed to start Docker Desktop on Linux: {e}")
            return False
    
    def wake_docker_desktop(self) -> bool:
        """Wake Docker Desktop from Resource Saver Mode."""
        if not self.is_docker_desktop_installed():
            print("Docker Desktop is not installed on this system.")
            return False
        
        if self.is_docker_running():
            print("Docker is already running.")
            return True
        
        print("Docker Desktop appears to be in Resource Saver Mode or stopped. Attempting to wake it...")
        
        success = False
        if self.system == "windows":
            success = self.wake_docker_desktop_windows()
        elif self.system == "darwin":
            success = self.wake_docker_desktop_macos()
        elif self.system == "linux":
            success = self.wake_docker_desktop_linux()
        else:
            print(f"Unsupported operating system: {self.system}")
            return False
        
        if not success:
            print("Failed to start Docker Desktop programmatically.")
            return False
        
        return self.wait_for_docker()
    
    def wait_for_docker(self) -> bool:
        """Wait for Docker daemon to become available."""
        print("Waiting for Docker daemon to start...")
        start_time = time.time()
        
        while time.time() - start_time < self.timeout:
            if self.is_docker_running():
                print("✅ Docker daemon is now running!")
                return True
            
            print("⏳ Docker daemon not ready yet, waiting...")
            time.sleep(3)
        
        print(f"❌ Timeout: Docker daemon did not start within {self.timeout} seconds.")
        return False
    
    def get_docker_status(self) -> Tuple[bool, str]:
        """Get detailed Docker status information."""
        if self.is_docker_running():
            try:
                client = docker.from_env(timeout=5)
                info = client.info()
                return True, f"Docker is running (Version: {info.get('ServerVersion', 'Unknown')})"
            except Exception as e:
                return True, f"Docker is running but info unavailable: {e}"
        
        if self.is_docker_desktop_installed():
            return False, "Docker Desktop is installed but not running (possibly in Resource Saver Mode)"
        
        return False, "Docker Desktop is not installed"


def ensure_docker_running(timeout: int = 60) -> DockerClient:
    """
    Ensure Docker is running and return a Docker client.
    Will attempt to wake Docker Desktop if it's in Resource Saver Mode.
    """
    manager = DockerManager(timeout=timeout)
    
    # Check current status
    is_running, status = manager.get_docker_status()
    print(f"Docker status: {status}")
    
    # Warn about ARM64 hardware
    if platform.machine().lower() in ['arm64', 'aarch64']:
        print("⚠️  Warning: Running on ARM64 hardware. Factorio containers will run via x86_64 emulation.")
        print("   Performance may be reduced. Consider using x86_64 hardware for optimal performance.")
    
    if is_running:
        return docker.from_env(timeout=5)
    
    # Try to wake Docker Desktop
    if manager.wake_docker_desktop():
        return docker.from_env(timeout=5)
    else:
        raise RuntimeError(
            "Failed to start Docker Desktop. Please start it manually:\n"
            f"Windows: Start 'Docker Desktop' from Start Menu\n"
            f"macOS: Open Docker Desktop from Applications\n"
            f"Linux: Run 'docker-desktop' or check systemctl status"
        )
