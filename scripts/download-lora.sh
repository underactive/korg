#!/bin/bash
# ============================================================================
# Download a LoRA to the shared models directory
# ============================================================================
# Downloads a LoRA file from a URL (CivitAI, HuggingFace, etc.) into
# /workspace/models/loras/ for use with Wan2GP.
#
# Usage:
#   bash download-lora.sh <url> [filename]
#
# Examples:
#   bash download-lora.sh "https://civitai.com/api/download/models/12345"
#   bash download-lora.sh "https://huggingface.co/.../lora.safetensors" my_lora.safetensors
# ============================================================================

set -euo pipefail

LORA_DIR="/workspace/models/loras"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <url> [filename]"
    echo ""
    echo "Downloads a LoRA file to ${LORA_DIR}/"
    exit 1
fi

URL="$1"
FILENAME="${2:-$(basename "$URL" | sed 's/?.*//')}"

mkdir -p "$LORA_DIR"

echo "Downloading LoRA: ${FILENAME}"
echo "  From: ${URL}"
echo "  To:   ${LORA_DIR}/${FILENAME}"

wget --progress=bar:force:noscroll -O "${LORA_DIR}/${FILENAME}.tmp" "$URL"
mv "${LORA_DIR}/${FILENAME}.tmp" "${LORA_DIR}/${FILENAME}"

echo ""
echo "Downloaded: ${LORA_DIR}/${FILENAME}"
echo "Load it in Wan2GP's LoRA settings panel."
