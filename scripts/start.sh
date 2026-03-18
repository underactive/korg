#!/bin/bash
# ============================================================================
# Wan2GP Start Script for RunPod
# ============================================================================
# Launches Wan2GP after a pod restart. Models must already be downloaded
# (run setup.sh first on a fresh pod).
#
# Usage:
#   bash /workspace/start.sh          # foreground (see logs live)
#   bash /workspace/start.sh --bg     # background (detached, logs to file)
#
# Access: https://{pod-id}-7860.proxy.runpod.net
# ============================================================================

set -euo pipefail

WORKSPACE="/workspace"
WAN2GP_DIR="${WORKSPACE}/Wan2GP"
LOG_FILE="${WORKSPACE}/wan2gp.log"
PORT=7860

export HF_HOME="${WORKSPACE}/hf_cache"

# --- Preflight checks -------------------------------------------------------

if [ ! -d "$WAN2GP_DIR" ]; then
    echo "ERROR: Wan2GP not found at ${WAN2GP_DIR}"
    echo "Run setup.sh first: bash /workspace/korg/scripts/setup.sh"
    exit 1
fi

# Check if already running
if pgrep -f "wgp.py" > /dev/null 2>&1; then
    echo "Wan2GP is already running (PID: $(pgrep -f 'wgp.py'))"
    echo "Access: https://{pod-id}-${PORT}.proxy.runpod.net"
    echo ""
    echo "To restart: kill $(pgrep -f 'wgp.py') && bash $0"
    exit 0
fi

# Reinstall deps if needed (container is ephemeral, pip packages may be gone)
if ! python -c "import gradio" 2>/dev/null; then
    echo "Reinstalling Python dependencies (container was reset)..."

    # Detect Blackwell GPUs (sm_120) which need PyTorch nightly with cu128
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    if echo "$GPU_NAME" | grep -qi "blackwell\|RTX PRO 6000\|B200\|B100\|GB200"; then
        echo "Blackwell GPU detected (${GPU_NAME}) — installing PyTorch nightly..."
        pip install --pre --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128 2>&1 | tail -3
    else
        pip install torch==2.6.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126 2>&1 | tail -3
    fi

    cd "$WAN2GP_DIR"
    pip install -r requirements.txt 2>&1 | tail -3
fi

# Ensure model symlinks exist
if [ -d "${WORKSPACE}/models" ]; then
    CKPTS_DIR="${WAN2GP_DIR}/ckpts"
    mkdir -p "$CKPTS_DIR"
    for model in "${WORKSPACE}/models/"*.safetensors; do
        filename=$(basename "$model")
        if [ ! -L "${CKPTS_DIR}/${filename}" ]; then
            ln -sf "$model" "${CKPTS_DIR}/${filename}"
        fi
    done
fi

cd "$WAN2GP_DIR"

# --- Launch ------------------------------------------------------------------

if [[ "${1:-}" == "--bg" ]]; then
    echo "Starting Wan2GP in background..."
    nohup python wgp.py --listen --server-port "$PORT" > "$LOG_FILE" 2>&1 &
    echo "PID: $!"
    echo "Logs: tail -f ${LOG_FILE}"
    echo "Access: https://{pod-id}-${PORT}.proxy.runpod.net"
else
    echo "Starting Wan2GP (foreground)..."
    echo "Access: https://{pod-id}-${PORT}.proxy.runpod.net"
    echo "Press Ctrl+C to stop"
    echo ""
    python wgp.py --listen --server-port "$PORT" 2>&1 | tee "$LOG_FILE"
fi
