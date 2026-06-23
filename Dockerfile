# LTX 2.3 serverless worker for Itihasik.
# Official RunPod ComfyUI worker + the ComfyUI-LTXVideo custom nodes baked in.
# Models (DiT checkpoint, Gemma text encoder, spatial upscaler) are NOT baked
# here — they live on the attached network volume at /runpod-volume/models/...
# and ComfyUI auto-detects them.
#
# CUDA pin: the plain :5.8.6-base ships a PyTorch built for a CUDA newer than
# the RunPod GPU hosts' driver (driver reports CUDA 12.8 / "found version 12080"),
# so torch fails its GPU check ("driver too old" / "no kernel image") and the
# worker exits(1) crash-looping. The -cuda12.8.1 variant's torch matches the
# 12.8 driver, so the GPU initialises.
FROM runpod/worker-comfyui:5.8.6-base-cuda12.8.1

# LTX 2.3 nodes (T2V/I2V, audio, latent upscale + refine).
RUN comfy-node-install comfyui-ltxvideo
