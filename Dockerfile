# LTX 2.3 serverless worker for Itihasik.
# Official RunPod ComfyUI worker + the ComfyUI-LTXVideo custom nodes baked in.
# Models live on the attached network volume (mounted at /runpod-volume at runtime).
#
# CUDA pin: the plain :5.8.6-base ships a PyTorch built for a CUDA newer than the
# RunPod GPU host driver (CUDA 12.8), so torch fails its GPU check and the worker
# exits(1). The -cuda12.8.1 variant's torch matches the 12.8 driver.
FROM runpod/worker-comfyui:5.8.6-base-cuda12.8.1

# LTX 2.3 nodes (guide/keyframe + extras). Base graph itself is core-only.
RUN comfy-node-install comfyui-ltxvideo

# worker-comfyui's auto-detect of /runpod-volume/models is unreliable on this base
# image (see the upstream fix-network-volume-model-paths branch). ComfyUI ALWAYS
# scans /comfyui/models/<type>, so symlink those folders straight at the volume —
# the links resolve once the network volume mounts at /runpod-volume at runtime.
RUN for d in checkpoints text_encoders latent_upscale_models loras; do \
      rm -rf "/comfyui/models/$d"; \
      ln -sfn "/runpod-volume/models/$d" "/comfyui/models/$d"; \
    done
