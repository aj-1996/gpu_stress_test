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

# Detect if running from CURL
if [[ "$0" == "bash" || "$0" == "-" ]]; then
    echo "🌍 Running from curl — cloning repo..."
    rm -rf "$REPO_DIR"
    git clone "$REPO_URL"
    cd "$REPO_DIR"
else
    echo "📁 Running locally inside repo."
fi

# 1. Ensure we're inside repo folder
if [ ! -f "run.sh" ]; then
    echo "❌ ERROR: run.sh must be run inside gpu_stress_test folder."
    exit 1
fi

# 2. Ensure virtual env
if [ ! -d "$VENV_DIR" ]; then
    echo "🐍 Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
else
    echo "🐍 Virtual environment exists."
fi

source "$VENV_DIR/bin/activate"

echo "📦 Installing required dependencies..."
pip install --upgrade pip
pip install numpy

# Install PyTorch (auto CUDA)
pip install torch --index-url https://download.pytorch.org/whl/cu118 || pip install torch

# 3. Create/overwrite Python stress script
echo "📝 Writing smart_random_stress.py..."

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
        print("⚠ GPU not available")
        return

    gpu = get_gpu_info()
    print(f"🎮 GPU: {gpu['name']} ({gpu['total_gb']} GB)")
    print(f"🔥 Base tensor size: {gpu['max_tensor_size']}")

    start = time.time()
    while time.time() - start < duration:
        size = int(gpu["max_tensor_size"] * random.uniform(0.3, 0.8))
        size = max(512, size)
        a = torch.randn((size, size), device="cuda")
        b = torch.randn((size, size), device="cuda")
        iters = random.randint(2, 8)
        for _ in range(iters):
            torch.matmul(a, b)
            torch.cuda.synchronize()
        time.sleep(random.uniform(0.1, 0.5))

    print("✔ GPU load done.")

def random_cpu_ram_load(duration):
    print("🧠 CPU/RAM load started…")
    start = time.time()
    while time.time() - start < duration:
        mb = random.randint(50, 400)
        elements = (mb * 1024 * 1024) // 8
        arr = np.random.rand(elements)
        loops = random.randint(2, 6)
        for _ in range(loops):
            arr * random.uniform(1.1, 4.0)
        time.sleep(random.uniform(0.05, 0.3))
    print("✔ CPU/RAM load done.")

def stress(duration=60):
    print(f"\n🔥 Starting RANDOMIZED STRESS ({duration}s)\n")
    t_cpu = threading.Thread(target=random_cpu_ram_load, args=(duration,))
    t_cpu.start()
    if GPU_AVAILABLE:
        t_gpu = threading.Thread(target=random_gpu_load, args=(duration,))
        t_gpu.start()
        t_gpu.join()
    t_cpu.join()
    print("\n🎉 Stress test complete.\n")

if __name__ == "__main__":
    stress(60)
EOF

# 4. Run the script
echo "🚀 Running stress test..."
python3 $PY_SCRIPT

echo ""
echo "=========================================="
echo "   Stress test finished!"
echo "=========================================="
echo ""
