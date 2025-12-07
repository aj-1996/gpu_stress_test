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

# Detect if running from curl
if [[ "$0" == "bash" || "$0" == "-" ]]; then
    echo "🌍 Running from curl — cloning repo..."
    rm -rf "$REPO_DIR"
    git clone "$REPO_URL"
    cd "$REPO_DIR"
else
    echo "📁 Running locally inside repo."
fi

# Ensure python3-venv is installed
if ! python3 -m venv test_venv 2>/dev/null; then
    echo "⚠ python3-venv is missing. Installing..."
    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y python3-venv python3.12-venv
    else
        echo "❌ python3-venv installation not supported automatically on this OS."
        echo "Please install Python venv package for your distribution."
        exit 1
    fi
else
    rm -rf test_venv
fi

# Create virtual env
if [ ! -d "$VENV_DIR" ]; then
    echo "🐍 Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate venv
echo "📌 Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Ensure pip exists
if ! command -v pip >/dev/null 2>&1; then
    echo "⚠ pip missing inside venv — installing ensurepip..."
    python3 -m ensurepip --default-pip
fi

echo "📦 Installing required dependencies..."
pip install --upgrade pip
pip install numpy

# Install PyTorch (auto CUDA fallback)
pip install torch --index-url https://download.pytorch.org/whl/cu118 || pip install torch

# Write Python stress script
echo "📝 Writing smart_random_stress.py..."
cat << 'EOF' > $PY_SCRIPT
### PYTHON SCRIPT CONTENT HERE (same as before) ###
EOF

# Run the script
echo "🚀 Running stress test..."
python3 $PY_SCRIPT

echo ""
echo "=========================================="
echo "   Stress test finished!"
echo "=========================================="
echo ""
