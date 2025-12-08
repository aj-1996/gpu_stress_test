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


# -------------------------------
# Parse CLI Arguments
# -------------------------------
DURATION_MIN=1   # default
MODE="all"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --time)
            DURATION_MIN="$2"
            shift
            ;;
        --mode)
            MODE="$2"
            shift
            ;;
        --help)
            echo ""
            echo "Usage:"
            echo "  bash run.sh [--time MINUTES] [--mode all|gpu|cpu]"
            echo ""
            echo "Examples:"
            echo "  bash run.sh --time 5 --mode all"
            echo "  bash run.sh --time 2 --mode gpu"
            echo "  bash run.sh --time 10 --mode cpu"
            echo ""
            exit 0
            ;;
        *)
            echo "❌ Unknown flag: $1"
            exit 1
            ;;
    esac
    shift
done

# Convert minutes → seconds
DURATION_SEC=$(( DURATION_MIN * 60 ))


# -------------------------------
# Clone repo if running via curl
# -------------------------------
if [[ "$0" == "bash" || "$0" == "-" ]]; then
    echo "🌍 Running via curl — cloning repo..."
    rm -rf "$REPO_DIR"
    git clone "$REPO_URL"
    cd "$REPO_DIR"
else
    echo "📁 Running from local repo."
fi


# -------------------------------
# Install Python & pip & venv automatically
# -------------------------------
install_python_debian() {
    echo "📦 Installing Python + pip + venv (Debian/Ubuntu)..."
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv python3.12-venv
}

install_python_rhel() {
    echo "📦 Installing Python + pip + venv (RHEL/AmazonLinux)..."
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
        echo "❌ Unsupported OS — install Python manually."
        exit 1
    fi
fi

if ! command -v pip3 >/dev/null 2>&1; then
    echo "⚠ pip missing — installing ensurepip..."
    python3 -m ensurepip --upgrade
fi


# -------------------------------
# Create venv
# -------------------------------
if [ ! -d "$VENV_DIR" ]; then
    echo "🐍 Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

echo "📌 Activating virtual environment..."
source "$VENV_DIR/bin/activate"


# -------------------------------
# Install Python packages
# -------------------------------
echo "📦 Installing required Python packages..."
pip install --upgrade pip
pip install numpy
pip install torch --index-url https://download.pytorch.org/whl/cu118 \
    || pip install torch


# -------------------------------
# Generate smart_random_stress.py with CLI support
# -------------------------------
echo "📝 Writing Python stress engine..."

cat << EOF > $PY_SCRIPT
import time
import random
import threading
import argparse
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
        print("⚠ GPU not available — skipping GPU load.")
        return

    gpu = get_gpu_info()
    print(f"🎮 GPU Detected: {gpu['name']} ({gpu['total_gb']} GB VRAM)")
    print(f"🔥 Dynamic Base Tensor Size: {gpu['max_tensor_size']}")

    start = time.time()
    while time.time() - start < duration:
        size = max(512, int(gpu["max_tensor_size"] * random.uniform(0.3, 0.8)))

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


def stress(duration, mode):
    print(f"\n🔥 Starting Stress Test for {duration//60} minutes (Mode: {mode})\n")

    threads = []

    if mode in ["all", "cpu"]:
        t_cpu = threading.Thread(target=random_cpu_ram_load, args=(duration,))
        threads.append(t_cpu)
        t_cpu.start()

    if mode in ["all", "gpu"] and GPU_AVAILABLE:
        t_gpu = threading.Thread(target=random_gpu_load, args=(duration,))
        threads.append(t_gpu)
        t_gpu.start()

    for t in threads:
        t.join()

    print("\n🎉 Stress Test Finished!\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--time", type=int, default=60, help="Duration in seconds")
    parser.add_argument("--mode", type=str, choices=["all", "gpu", "cpu"], default="all")
    args = parser.parse_args()

    stress(args.time, args.mode)
EOF


# -------------------------------
# Run the stress test
# -------------------------------
echo "🚀 Running stress test..."
python3 $PY_SCRIPT --time "$DURATION_SEC" --mode "$MODE"

echo ""
echo "=========================================="
echo "     Stress Test Completed!"
echo "=========================================="
echo ""
