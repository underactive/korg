#!/bin/bash
# ============================================================================
# Wan2GP First-Boot Setup Script for RunPod
# ============================================================================
# Run this ONCE on a fresh pod with a network volume mounted at /workspace.
# It installs Wan2GP, downloads models (~21GB), and prepares the environment.
#
# Usage:
#   bash /workspace/korg/scripts/setup.sh
#
# Prerequisites:
#   - RunPod pod with network volume at /workspace
#   - Template: runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
#   - GPU: L40S (48GB) recommended, A6000/3090 also supported
# ============================================================================

set -euo pipefail

WORKSPACE="/workspace"
WAN2GP_DIR="${WORKSPACE}/Wan2GP"
MODELS_DIR="${WORKSPACE}/models"
HF_CACHE_DIR="${WORKSPACE}/hf_cache"
LOG_FILE="${WORKSPACE}/setup.log"

# HuggingFace base URL for Wan 2.1 repackaged models
HF_BASE="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files"

# Model files to download
declare -A MODELS=(
    ["diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors"]="16.4GB - Wan 2.2 14B I2V diffusion model (fp8)"
    ["clip_vision/clip_vision_h.safetensors"]="~1GB - CLIP vision encoder"
    ["vae/wan_2.1_vae.safetensors"]="~0.5GB - VAE decoder"
    ["text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"]="6.7GB - UMT5-XXL text encoder (fp8)"
)

# --- Helpers -----------------------------------------------------------------

log() {
    local msg="[$(date '+%H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

die() {
    log "ERROR: $1"
    exit 1
}

check_disk_space() {
    local available_gb
    available_gb=$(df -BG "$WORKSPACE" | awk 'NR==2 {print $4}' | tr -d 'G')
    if (( available_gb < 25 )); then
        die "Only ${available_gb}GB free on ${WORKSPACE}. Need at least 25GB for models (~21GB) + Wan2GP."
    fi
    log "Disk space OK: ${available_gb}GB available"
}

# --- Step 1: Validate environment --------------------------------------------

log "=== Wan2GP Setup Starting ==="
log "Workspace: ${WORKSPACE}"

if [ ! -d "$WORKSPACE" ]; then
    die "Network volume not mounted at ${WORKSPACE}. Attach a volume and retry."
fi

check_disk_space

# Check GPU
if command -v nvidia-smi &>/dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
    GPU_VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -1)
    log "GPU detected: ${GPU_NAME} (${GPU_VRAM})"
else
    log "WARNING: nvidia-smi not found. Proceeding anyway."
fi

# --- Step 2: Clone/update Wan2GP ---------------------------------------------

if [ -d "$WAN2GP_DIR" ]; then
    log "Wan2GP already cloned, pulling latest..."
    cd "$WAN2GP_DIR"
    git pull --ff-only || log "WARNING: git pull failed, using existing version"
else
    log "Cloning Wan2GP..."
    cd "$WORKSPACE"
    git clone https://github.com/deepbeepmeep/Wan2GP.git
fi

# --- Step 3: Install Python dependencies ------------------------------------

log "Upgrading PyTorch to 2.5+ (required for torch.nn.Buffer)..."
pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 2>&1 | tail -3

log "Installing Python dependencies..."
cd "$WAN2GP_DIR"
pip install -r requirements.txt 2>&1 | tail -5
log "Dependencies installed"

# --- Step 4: Download models -------------------------------------------------

mkdir -p "$MODELS_DIR"
mkdir -p "$HF_CACHE_DIR"

log "Downloading models to ${MODELS_DIR} (~21GB total)..."

for model_path in "${!MODELS[@]}"; do
    filename=$(basename "$model_path")
    target="${MODELS_DIR}/${filename}"
    description="${MODELS[$model_path]}"

    if [ -f "$target" ]; then
        log "  ✓ ${filename} already exists, skipping"
    else
        log "  ↓ Downloading ${filename} (${description})..."
        wget --progress=bar:force:noscroll -O "${target}.tmp" \
            "${HF_BASE}/${model_path}" 2>&1 | tail -1
        mv "${target}.tmp" "$target"
        log "  ✓ ${filename} downloaded"
    fi
done

log "All models downloaded"

# --- Step 5: Create symlinks for Wan2GP model discovery ----------------------

# Wan2GP looks for models in its own directory structure or via HF cache.
# We create a ckpts directory with our pre-downloaded models for direct access.
CKPTS_DIR="${WAN2GP_DIR}/ckpts"
mkdir -p "$CKPTS_DIR"

for model_path in "${!MODELS[@]}"; do
    filename=$(basename "$model_path")
    if [ ! -L "${CKPTS_DIR}/${filename}" ]; then
        ln -sf "${MODELS_DIR}/${filename}" "${CKPTS_DIR}/${filename}"
        log "  Linked: ckpts/${filename} → models/${filename}"
    fi
done

# --- Step 6: Create LoRA directory -------------------------------------------

mkdir -p "${WORKSPACE}/models/loras"
log "LoRA directory ready at ${WORKSPACE}/models/loras/"

# --- Step 7: Copy start script to workspace root for convenience -------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "${SCRIPT_DIR}/start.sh" "${WORKSPACE}/start.sh"
chmod +x "${WORKSPACE}/start.sh"
log "Start script copied to ${WORKSPACE}/start.sh"

# --- Done --------------------------------------------------------------------

log "=== Setup Complete ==="
log ""
log "To launch Wan2GP:"
log "  bash ${WORKSPACE}/start.sh"
log ""
log "Or manually:"
log "  cd ${WAN2GP_DIR}"
log "  export HF_HOME=${HF_CACHE_DIR}"
log "  python wgp.py --listen --server-port 7860"
log ""
log "Access via: https://{pod-id}-7860.proxy.runpod.net"
