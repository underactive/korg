# RunPod Pod Setup — Step by Step

## 1. Create Pod

- Go to RunPod → Pods → **+ Deploy**
- Select your saved template (Runpod Pytorch 2.4.0)
- **GPU**: A40 48GB (or L40S/A6000 if available)
- **GPU count**: 1
- **Instance pricing**: On-Demand
- **SSH terminal access**: Check (your SSH key is already saved)
- **Start Jupyter notebook**: Uncheck
- Click **Deploy**

## 2. Pod Template Overrides (if prompted)

- **Container image**: `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
- **Container Disk**: 20 GB
- **Volume Disk**: 50 GB
- **Volume Mount Path**: `/workspace`
- **Expose HTTP Ports**: `7860`
- **Expose TCP Ports**: `22, 443`
- Click **Set Overrides**

## 3. SSH In

From the RunPod dashboard, click **Connect** → copy the SSH command. It looks like:

```bash
ssh PODID@ssh.runpod.io -i ~/.ssh/id_ed25519
```

## 4. First Boot Setup (~15-20 min)

```bash
cd /workspace
git clone https://github.com/underactive/korg.git
bash /workspace/korg/scripts/setup.sh
```

This clones Wan2GP, upgrades PyTorch to 2.6, installs deps, and downloads ~25GB of models.

## 5. Launch Wan2GP

```bash
bash /workspace/start.sh
```

Access the UI at: `https://{pod-id}-7860.proxy.runpod.net`
(Find the full URL under **Connect** → **HTTP Service [Port 7860]** in the RunPod dashboard)

## 6. Every Restart (after pod stop/start)

```bash
ssh PODID@ssh.runpod.io -i ~/.ssh/id_ed25519
bash /workspace/start.sh
```

The start script auto-reinstalls pip packages if the container was reset, recreates symlinks, and launches Wan2GP.

## 7. Download LoRAs from CivitAI

### Get your API token (one-time)

1. Go to [civitai.com](https://civitai.com) → click profile icon → **Account Settings**
2. Scroll to **API Keys** → generate a new key
3. Save it somewhere — you'll need it for every download

### Find the download URL

1. Go to the model page on CivitAI (e.g. a Wan 2.2 NSFW LoRA)
2. **Right-click** the download button → **Copy Link Address**
3. The URL looks like: `https://civitai.com/api/download/models/2847561`
4. Append your token: `?token=YOUR_TOKEN`

### Download to your pod

```bash
bash /workspace/korg/scripts/download-lora.sh \
  "https://civitai.com/api/download/models/VERSION_ID?token=YOUR_TOKEN" \
  lora_name.safetensors
```

This puts the file in `/workspace/Wan2GP/loras_i2v/`. For T2V LoRAs, add `--t2v`.

### Load in Wan2GP

1. Click **Refresh** in the UI (or restart Wan2GP if it doesn't appear)
2. Select the LoRA from the dropdown
3. Set the **weight/multiplier** (check the CivitAI page for recommended value, usually 0.8-1.0)
4. Add the **trigger word** to your prompt if the model requires one (listed on the CivitAI page)
5. Generate

### Notable LoRAs

| Name | Type | Notes |
|------|------|-------|
| WAN General NSFW (CubeyAI) | Style/Concept | Trigger: `nsfwsks`, weight: 0.8 |
| Instagirl WAN 2.2 | Style | Realistic style |
| SingularUnity MotionCraft | Motion | Better motion quality, stackable |

## 8. Download Output Videos

Stop Wan2GP, serve files over HTTP, download in browser:

```bash
pkill -f wgp.py
cd /workspace/output && python -m http.server 7860
```

Browse to `https://{pod-id}-7860.proxy.runpod.net`, click files to download.

When done, Ctrl+C and restart:

```bash
bash /workspace/start.sh
```

## 9. Check Status

```bash
bash /workspace/korg/scripts/status.sh
```

Shows GPU info, disk usage, models, and process status.

## 10. When Done for the Day

**Stop** (not terminate) the pod from the RunPod dashboard. This preserves your volume disk with all models and outputs. You stop paying for GPU hours.

## Recommended I2V Settings

| Setting | Value |
|---------|-------|
| Resolution | 720p (better motion than 480p) |
| Frame count | 81 frames (~5s at 16fps) |
| CFG / Guidance | ~3.5 |
| Steps | 25-30 |
| Motion amplitude | 1.15+ (Quality tab) |

Add speed words to prompts: "quickly", "briskly", "energetically".

## Troubleshooting

| Problem | Fix |
|---------|-----|
| torch.nn.Buffer error | `pip install torch==2.6.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126` |
| CUDA busy/unavailable | Stop pod, restart from dashboard. If persists, terminate and deploy new pod. |
| LoRA not showing in UI | Restart Wan2GP: `pkill -f wgp.py && bash /workspace/start.sh` |
| Port 7860 not accessible | Check HTTP ports in pod template includes 7860 |
