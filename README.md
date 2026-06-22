# LTX-RunpodTemplate

RunPod **serverless** worker image for **LTX 2.3** video generation, used by
Itihasik's `runpod_ltx` provider.

It extends the official [`runpod/worker-comfyui`](https://github.com/runpod-workers/worker-comfyui)
image and bakes in the **ComfyUI-LTXVideo** custom nodes. The actual model
weights are not in the image — they live on a RunPod **network volume** mounted
at `/runpod-volume`, in the standard ComfyUI layout:

```
/runpod-volume/models/checkpoints/ltx-2.3-22b-dev.safetensors
/runpod-volume/models/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors
/runpod-volume/models/latent_upscale_models/ltx-2.3-spatial-upscaler-x2-1.0.safetensors
```

## Deploy

1. RunPod → Serverless → **Custom deployment** → **GitHub repo** → this repo.
2. GPU: **A100 80GB / H100**. Container disk ~30 GB. Flashboot ON.
   Execution timeout ~900s. Max workers 1, active 0.
3. Advanced → **Network Volumes** → attach the `ltx-models` volume.
4. (Production) set `BUCKET_ENDPOINT_URL` / `BUCKET_ACCESS_KEY_ID` /
   `BUCKET_SECRET_ACCESS_KEY` to upload results to S3 instead of base64.

See `infra/runpod-ltx/README.md` in the main repo for the full runbook.
