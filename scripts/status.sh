#!/bin/bash
# ============================================================================
# Wan2GP Status Check
# ============================================================================
# Quick diagnostic: GPU, disk, process status, and model inventory.
#
# Usage:
#   bash /workspace/korg/scripts/status.sh
# ============================================================================

WORKSPACE="/workspace"
MODELS_DIR="${WORKSPACE}/models"
LORA_DIR="${MODELS_DIR}/loras"
WAN2GP_DIR="${WORKSPACE}/Wan2GP"
PORT=7860

echo "=== Wan2GP Status ==="
echo ""

# GPU
echo "--- GPU ---"
if command -v nvidia-smi &>/dev/null; then
    nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free,temperature.gpu \
        --format=csv,noheader | while IFS=',' read -r name total used free temp; do
        echo "  GPU:  ${name}"
        echo "  VRAM: ${used} used / ${total} total (${free} free)"
        echo "  Temp: ${temp}"
    done
else
    echo "  nvidia-smi not available"
fi
echo ""

# Disk
echo "--- Disk ---"
df -h "$WORKSPACE" 2>/dev/null | awk 'NR==2 {printf "  Volume: %s used / %s total (%s free, %s)\n", $3, $2, $4, $5}'
echo ""

# Models
echo "--- Models ---"
if [ -d "$MODELS_DIR" ]; then
    for f in "$MODELS_DIR"/*.safetensors; do
        [ -f "$f" ] || continue
        size=$(du -h "$f" | cut -f1)
        echo "  ✓ $(basename "$f") (${size})"
    done
else
    echo "  No models found. Run setup.sh first."
fi
echo ""

# LoRAs
echo "--- LoRAs ---"
if [ -d "$LORA_DIR" ] && ls "$LORA_DIR"/*.safetensors &>/dev/null 2>&1; then
    for f in "$LORA_DIR"/*.safetensors; do
        size=$(du -h "$f" | cut -f1)
        echo "  ✓ $(basename "$f") (${size})"
    done
else
    echo "  No LoRAs installed"
fi
echo ""

# Process
echo "--- Wan2GP Process ---"
if pgrep -f "wgp.py" > /dev/null 2>&1; then
    PID=$(pgrep -f "wgp.py")
    echo "  Running (PID: ${PID})"
    echo "  Access: https://{pod-id}-${PORT}.proxy.runpod.net"
else
    echo "  Not running"
    echo "  Start: bash /workspace/start.sh"
fi
echo ""
