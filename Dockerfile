# LTX 2.3 serverless worker for Itihasik.
# Official RunPod ComfyUI worker + the ComfyUI-LTXVideo custom nodes baked in.
# Models (DiT checkpoint, Gemma text encoder, spatial upscaler) are NOT baked
# here — they live on the attached network volume at /runpod-volume/models/...
# and ComfyUI auto-detects them.
FROM runpod/worker-comfyui:5.1.0-base

# LTX 2.3 nodes (T2V/I2V, audio, latent upscale + refine).
RUN comfy-node-install comfyui-ltxvideo
