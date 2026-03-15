# RunPod Pod Configuration Reference

Use these settings when creating the pod on RunPod.

## Template Settings

- **Container Image**: `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
- **Container Disk**: 20 GB
- **Volume Disk**: Attach existing 50GB network volume
- **Volume Mount Path**: `/workspace`
- **Expose HTTP Ports**: `7860`
- **Expose TCP Ports**: (none needed)

## GPU Selection (in order of preference)

1. **L40S 48GB** — $0.52/hr spot — recommended
2. **A6000 48GB** — $0.44/hr spot — slightly slower, slightly cheaper
3. **RTX 3090 24GB** — $0.22/hr spot — budget, needs offloading

## Environment Variables

```
HF_HOME=/workspace/hf_cache
```

## Docker Command (optional, for auto-start)

If you want Wan2GP to auto-start when the pod boots, set this as the Docker command:

```
bash -c "bash /workspace/start.sh --bg && sleep infinity"
```

This launches Wan2GP in the background and keeps the container alive.

## Network Volume

- **Size**: 50 GB
- **Region**: Same as your preferred GPU (check L40S availability)
- **Cost**: $3.50/month

The volume stores:
- Models (~21GB)
- Wan2GP installation
- LoRAs and generated videos
- HuggingFace cache

## Spot vs On-Demand

Spot instances are ~60-70% cheaper but can be preempted. For video generation:
- Spot is fine — if preempted mid-render, you lose only that one video
- Network volume preserves everything between pod restarts
- Re-launching a spot pod typically takes <60 seconds
