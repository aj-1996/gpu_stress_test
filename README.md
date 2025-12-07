# gpu_stress_testBelow is a clean, professional **README.md** you can place directly in your repo `gpu_stress_test`.
It explains usage, architecture, requirements, curl-based execution, and safety notes.

---

# ✅ **README.md (Final Version)**

```markdown
# GPU & CPU Randomized Stress Test  
A lightweight, auto-adaptive system stress tool designed to generate **realistic, randomized load** on GPU, CPU, and RAM.  
Perfect for **thermal testing**, **inference/server load testing**, **autoscaler behavior analysis**, or **benchmarking hardware stability**.

---

## 🚀 Features
- **Randomized load** instead of constant 100% utilization  
- **Automatically detects GPU type + VRAM** and adjusts load safely  
- **Random tensor sizes** based on 30–60% of GPU memory  
- **Random CPU + RAM bursts** (50–400MB allocations)  
- **No configuration needed** — works out of the box  
- **Single one-command runner using `curl`**  
- **Self-contained** (creates venv, installs deps, runs test)  
- Works on **any Linux GPU server**

---

## 📦 Repository Structure

```

gpu_stress_test/
│
├── run.sh                    # Main executable shell script (via curl)
├── smart_random_stress.py    # Auto-generated adaptive stress script
├── stress-env/               # Virtual environment (auto-created)
└── README.md                 # Documentation

````

---

## 🧪 What This Stress Tool Does

### ✔ GPU Stress  
- Detects GPU VRAM  
- Uses dynamic tensor size (adaptive)  
- Random multiplications per cycle  
- Random cooldown  
- Mimics real ML workload burst patterns  

### ✔ CPU & RAM Stress  
- Random memory allocations  
- Random CPU-heavy math operations  
- Random cooldowns  
- Avoids flat, synthetic load — behaves like real-world application traffic

---

## 🖥️ Requirements
- **Linux**
- **Python 3.8+**
- **NVIDIA GPU (optional)**  
  - If no GPU is detected, GPU load is automatically skipped  
- **curl / wget**

---

## ⚡ Quick Start (Run with Curl)

To run the stress test directly from GitHub:

```bash
curl -s https://raw.githubusercontent.com/aj-1996/gpu_stress_test/main/run.sh | bash
````

Or using `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/aj-1996/gpu_stress_test/main/run.sh | bash
```

This will:

1. Clone the repo
2. Create Python venv
3. Install PyTorch + NumPy
4. Generate the adaptive stress script
5. Run the stress test for 60 seconds

---

## 📝 Running Locally

Clone manually:

```bash
git clone https://github.com/aj-1996/gpu_stress_test.git
cd gpu_stress_test
chmod +x run.sh
./run.sh
```

---

## 🔧 How It Works Internally

### 1️⃣ GPU Detection

The script reads:

```python
props = torch.cuda.get_device_properties(0)
total_mem = props.total_memory
```

### 2️⃣ Dynamic Tensor Sizing

Tensor size is chosen based on:

```
30–60% of VRAM → Safe Tensor Size Formula
```

This avoids OOM while still pushing the GPU.

### 3️⃣ Randomized Load Pattern

Randomization on:

* Tensor size
* Number of multiplications
* CPU loops
* RAM allocations
* Rest intervals

This makes the load pattern realistic and unpredictable.

---

## ⚠ Safety Notes

* **Monitor temperatures**

  ```bash
  watch -n1 nvidia-smi
  ```

* Avoid running long duration tests on laptops without cooling

* Servers with proper cooling can run indefinitely

* The script *never* uses 100% of VRAM—always keeps buffer space

* Safe for production hardware testing

---

## 🛠 Future Enhancements (Planned)

* CLI options

  ```
  run.sh --time 120 --mode gpu-only
  ```

* Logging GPU temp + load

* Multi-GPU parallel stress

* Dockerized version

* Power-capped stress mode

---

## 👨‍💻 Author

Developed by **Aniket Jire**
GitHub: [aj-1996](https://github.com/aj-1996)

---

## 💬 Contributions

PRs and improvements are welcome!

---


