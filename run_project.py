import subprocess
import time
import webbrowser
import os
import sys
import platform

def run_command(command, cwd=None, new_window=False):
    """Runs a command in a new process."""
    if new_window and platform.system() == 'Windows':
        # Use CREATE_NEW_CONSOLE if available, otherwise default to 16 (0x10)
        creationflags = getattr(subprocess, 'CREATE_NEW_CONSOLE', 16)
    else:
        creationflags = 0
    
    return subprocess.Popen(
        command, 
        cwd=cwd, 
        shell=True, 
        creationflags=creationflags
    )

def main():
    print("🚀 Starting Civic Grievance System...")
    root_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 1. Determine paths
    backend_dir = os.path.join(root_dir, 'backend')
    
    # Check for mobile_app or mobile_web_app
    if os.path.exists(os.path.join(root_dir, 'mobile_app')):
        frontend_dir = os.path.join(root_dir, 'mobile_app')
    elif os.path.exists(os.path.join(root_dir, 'mobile_web_app')):
        frontend_dir = os.path.join(root_dir, 'mobile_web_app')
    else:
        print("❌ Could not find frontend directory (mobile_app or mobile_web_app)")
        sys.exit(1)

    venv_python = os.path.join(root_dir, 'venv', 'Scripts', 'python.exe')
    if not os.path.exists(venv_python):
        print("⚠️ Virtual environment not found. Using system python.")
        venv_python = sys.executable

    # 2. Start Backend (Flask)
    print("Starting Backend Server on port 5000...")
    backend_cmd = [venv_python, 'app.py']
    backend_process = run_command(backend_cmd, cwd=backend_dir, new_window=True)
    
    # Wait a moment for backend to initialize
    time.sleep(2)

    # 3. Start Frontend (HTTP Server)
    print("Starting Frontend Server on port 8000...")
    # Using python -m http.server
    frontend_process = run_command(
        [sys.executable, '-m', 'http.server', '8000'], 
        cwd=frontend_dir, 
        new_window=True
    )

    print("✅ System works!")
    print("Frontend: http://localhost:8000")
    print("Backend:  http://localhost:5000")
    print("Press Ctrl+C in this terminal to stop (you may need to close the external windows manually).")

    # 4. Open Browser
    time.sleep(1)
    webbrowser.open('http://localhost:8000')

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nStopping services...")
        backend_process.terminate()
        frontend_process.terminate()
        print("Done.")

if __name__ == "__main__":
    main()
