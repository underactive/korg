#!/bin/bash
# ============================================================================
# Download a LoRA for Wan2GP
# ============================================================================
# Downloads a LoRA file from a URL (CivitAI, HuggingFace, etc.) into
# the appropriate Wan2GP LoRA directory.
#
# Usage:
#   bash download-lora.sh <url> [filename] [--t2v]
#
# By default, downloads to loras_i2v/ (I2V mode). Use --t2v for T2V LoRAs.
#
# Examples:
#   bash download-lora.sh "https://civitai.com/api/download/models/12345?token=KEY"
#   bash download-lora.sh "https://civitai.com/api/download/models/12345?token=KEY" my_lora.safetensors
#   bash download-lora.sh "https://huggingface.co/.../lora.safetensors" my_lora.safetensors --t2v
# ============================================================================

set -euo pipefail

WAN2GP_DIR="/workspace/Wan2GP"
LORA_DIR="${WAN2GP_DIR}/loras_i2v"

# Check for --t2v flag
for arg in "$@"; do
    if [[ "$arg" == "--t2v" ]]; then
        LORA_DIR="${WAN2GP_DIR}/loras/14B"
    fi
done

# Filter out flags from positional args
ARGS=()
for arg in "$@"; do
    [[ "$arg" != --* ]] && ARGS+=("$arg")
done

if [ ${#ARGS[@]} -lt 1 ]; then
    echo "Usage: $0 <url> [filename] [--t2v]"
    echo ""
    echo "Downloads a LoRA to Wan2GP's I2V LoRA directory."
    echo "Use --t2v to download to the T2V LoRA directory instead."
    exit 1
fi

URL="${ARGS[0]}"
FILENAME="${ARGS[1]:-$(basename "$URL" | sed 's/?.*//')}"

mkdir -p "$LORA_DIR"

echo "Downloading LoRA: ${FILENAME}"
echo "  From: ${URL}"
echo "  To:   ${LORA_DIR}/${FILENAME}"

wget --progress=bar:force:noscroll -O "${LORA_DIR}/${FILENAME}.tmp" "$URL"
mv "${LORA_DIR}/${FILENAME}.tmp" "${LORA_DIR}/${FILENAME}"

echo ""
echo "Downloaded: ${LORA_DIR}/${FILENAME}"
echo "Click Refresh in Wan2GP to load it — no restart needed."
