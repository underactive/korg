# korg — Self-Hosted Image-to-Video on RunPod

Generate 6-second videos from images using **Wan 2.2 14B I2V** via **Wan2GP** on RunPod spot instances.

## Quick Start

### 1. Create RunPod Resources
- **Network Volume**: 50GB, in a datacenter with L40S availability
- **Pod**: L40S 48GB spot instance
  - Template: `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
  - Container disk: 20GB
  - Volume mount: `/workspace`

### 2. First Boot (one-time, ~15 min)
```bash
cd /workspace
git clone https://github.com/esison/korg.git   # or upload scripts manually
bash /workspace/korg/scripts/setup.sh
bash /workspace/start.sh
```

### 3. Every Restart
```bash
bash /workspace/start.sh        # foreground
bash /workspace/start.sh --bg   # background
```

### 4. Generate Video
1. Open `https://{pod-id}-7860.proxy.runpod.net`
2. Select **I2V** mode
3. Upload image, enter prompt, set 6s duration
4. Generate (480p: ~5-7 min, 720p: ~10-15 min on L40S)

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/setup.sh` | First-boot: clone Wan2GP, install deps, download models (~21GB) |
| `scripts/start.sh` | Launch Wan2GP (foreground or `--bg` for background) |
| `scripts/status.sh` | Show GPU, disk, models, and process status |
| `scripts/download-lora.sh` | Download a LoRA from URL to models directory |

## GPU Options

| GPU | VRAM | Offloading | 6s @ 720p | Spot $/hr |
|-----|------|------------|-----------|-----------|
| **L40S** | **48GB** | **None** | **~12 min** | **$0.52** |
| A6000 | 48GB | None | ~15 min | $0.44 |
| RTX 3090 | 24GB | Heavy | ~42 min | $0.22 |

L40S recommended: 48GB VRAM = zero offloading, Ada Lovelace fp8 tensor cores, best $/video.

## Models (~21GB total)

| File | Size |
|------|------|
| wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors | 16.4 GB |
| umt5_xxl_fp8_e4m3fn_scaled.safetensors | 6.7 GB |
| clip_vision_h.safetensors | ~1 GB |
| wan_2.1_vae.safetensors | ~0.5 GB |

Total: ~25 GB on disk. Models persist on the network volume across pod restarts.

## Tips
- **Stop your pod after every session** — you only pay for active GPU hours
- 480p is ~2x faster than 720p — use 480p for drafts
- Descriptive motion prompts work best ("slowly turning head", "walking forward")
- LoRAs from CivitAI can improve motion quality for specific content types

## Cost Estimates (L40S)

| Usage | GPU/mo | Storage | Total |
|-------|--------|---------|-------|
| Light (2/day) | ~$6 | $3.50 | ~$10 |
| Moderate (4/day) | ~$13 | $3.50 | ~$16 |
| Heavy (10/day) | ~$32 | $3.50 | ~$36 |

## Directory Layout (on RunPod)

```
/workspace/
├── korg/                    # this repo
│   └── scripts/
├── Wan2GP/                  # cloned by setup.sh
│   └── ckpts/               # symlinks → /workspace/models/
├── models/
│   ├── *.safetensors        # Wan 2.2 model files
│   └── loras/               # optional LoRA files
├── hf_cache/                # HuggingFace cache
├── start.sh                 # convenience copy
├── wan2gp.log               # runtime logs
└── setup.log                # setup logs
```
