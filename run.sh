#!/bin/bash

echo ""
echo "=========================================="
echo "   GPU + CPU RANDOMIZED STRESS RUNNER"
echo "=========================================="
echo ""

REPO_URL="https://github.com/aj-1996/gpu_stress_test.git"
REPO_DIR="gpu_stress_test"
VENV_DIR="stress-env"
PY_SCRIPT="smart_random_stress.py"


# -------------------------------------------
# 0. Clone repo if executed via curl
# -------------------------------------------
if [[ "$0" == "bash" || "$0" == "-" ]]; then
    echo "🌍 Running via curl — cloning repo..."
    rm -rf "$REPO_DIR"
    git clone "$REPO_URL"
    cd "$REPO_DIR"
else
    echo "📁 Running from local repo."
fi


# -------------------------------------------
# 1. Install Python, pip, venv automatically
# -------------------------------------------

install_python_debian() {
    echo "📦 Installing Python + pip + venv (Debian/Ubuntu)..."
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv python3.12-venv
}

install_python_rhel() {
    echo "📦 Installing Python + pip + venv (RHEL/CentOS/AmazonLinux)..."
    sudo yum install -y python3 python3-pip python3-virtualenv
}

install_python_arch() {
    echo "📦 Installing Python + pip + venv (Arch Linux)..."
    sudo pacman -Sy --noconfirm python python-pip python-virtualenv
}

if ! command -v python3 >/dev/null 2>&1; then
    echo "⚠ Python not found — installing..."

    if command -v apt >/dev/null 2>&1; then
        install_python_debian
    elif command -v yum >/dev/null 2>&1; then
        install_python_rhel
    elif command -v pacman >/dev/null 2>&1; then
        install_python_arch
    else
        echo "❌ Unsupported Linux distribution — install Python manually."
        exit 1
    fi
fi

# Ensure pip exists
if ! command -v pip3 >/dev/null 2>&1; then
    echo "⚠ pip missing — installing ensurepip..."
    python3 -m ensurepip --upgrade
fi


# -------------------------------------------
# 2. Create virtual environment
# -------------------------------------------

if [ ! -d "$VENV_DIR" ]; then
    echo "🐍 Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

echo "📌 Activating virtual environment..."
source "$VENV_DIR/bin/activate"


# -------------------------------------------
# 3. Install Python dependencies
# -------------------------------------------

echo "📦 Installing required Python packages..."
pip install --upgrade pip
pip install numpy

# Install CUDA-enabled torch if possible, fallback to CPU torch
pip install torch --index-url https://download.pytorch.org/whl/cu118 \
    || pip install torch


# -------------------------------------------
# 4. Generate the Python stress script
# -------------------------------------------

echo "📝 Generating stress script... $PY_SCRIPT"

cat << 'EOF' > $PY_SCRIPT
import time
import random
import threading
import numpy as np

try:
    import torch
    GPU_AVAILABLE = torch.cuda.is_available()
except:
    GPU_AVAILABLE = False


def get_gpu_info():
    if not GPU_AVAILABLE:
        return None

    props = torch.cuda.get_device_properties(0)
    total_mem = props.total_memory
    total_gb = total_mem / (1024**3)

    max_use_bytes = total_mem * random.uniform(0.30, 0.60)
    approx_size = int((max_use_bytes / 8) ** 0.5)

    return {
        "name": props.name,
        "total_gb": round(total_gb, 2),
        "max_tensor_size": approx_size,
    }


def random_gpu_load(duration):
    if not GPU_AVAILABLE:
        print("⚠ GPU not available — skipping GPU load")
        return

    gpu = get_gpu_info()
    print(f"🎮 GPU Detected: {gpu['name']} ({gpu['total_gb']} GB VRAM)")
    print(f"🔥 Dynamic Base Tensor Size: {gpu['max_tensor_size']}")

    start = time.time()

    while time.time() - start < duration:
        size = int(gpu["max_tensor_size"] * random.uniform(0.3, 0.8))
        size = max(512, size)

        a = torch.randn((size, size), device="cuda")
        b = torch.randn((size, size), device="cuda")

        for _ in range(random.randint(2, 8)):
            torch.matmul(a, b)
            torch.cuda.synchronize()

        time.sleep(random.uniform(0.1, 0.5))

    print("✔ GPU stress complete.")


def random_cpu_ram_load(duration):
    print("🧠 CPU/RAM load started…")
    start = time.time()

    while time.time() - start < duration:
        mb = random.randint(50, 400)
        elements = (mb * 1024 * 1024) // 8

        arr = np.random.rand(elements)

        for _ in range(random.randint(2, 6)):
            arr * random.uniform(1.1, 4.0)

        time.sleep(random.uniform(0.05, 0.3))

    print("✔ CPU/RAM stress complete.")


def stress(duration=60):
    print(f"\n🔥 Starting Randomized Stress Test ({duration}s)\n")

    t_cpu = threading.Thread(target=random_cpu_ram_load, args=(duration,))
    t_cpu.start()

    if GPU_AVAILABLE:
        t_gpu = threading.Thread(target=random_gpu_load, args=(duration,))
        t_gpu.start()
        t_gpu.join()

    t_cpu.join()

    print("\n🎉 Stress Test Finished!\n")


if __name__ == "__main__":
    stress(60)
EOF


# -------------------------------------------
# 5. Run stress test
# -------------------------------------------

echo "🚀 Running stress test..."
python3 $PY_SCRIPT

echo ""
echo "=========================================="
echo "   Stress Test Completed!"
echo "=========================================="
echo ""
