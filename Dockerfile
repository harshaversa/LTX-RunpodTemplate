# LTX 2.3 serverless worker for Itihasik.
# Official RunPod ComfyUI worker + the Lightricks ComfyUI-LTXVideo nodes.
# Models live on the attached network volume (mounted at /runpod-volume at runtime).
#
# CUDA pin: plain :5.8.6-base ships a PyTorch built for a CUDA newer than the
# RunPod GPU host driver (CUDA 12.8) -> torch fails its GPU check, worker exits(1).
FROM runpod/worker-comfyui:5.8.6-base-cuda12.8.1

# LTX 2.3 nodes. comfy-node-install places the pack, but ComfyUI-Manager
# BLACKLISTS `kornia` (build log: "skip black listed pip installation: 'kornia'"),
# which the pack imports at top level -> the whole pack fails to register. The
# real fix is installing kornia into the worker venv (/comfyui/.venv, uv-managed).
RUN comfy-node-install comfyui-ltxvideo
RUN /comfyui/.venv/bin/python -m uv pip install kornia \
 || /comfyui/.venv/bin/python -m pip install kornia

# Verify ONLY that kornia now imports (the dep that was missing). We do NOT import
# the pack itself at build time: it also imports ComfyUI's `comfy` module, which
# only resolves inside the running ComfyUI (not a standalone build shell), so a
# build-time pack import is a false negative. Node registration is verified by a
# live probe after the image deploys.
RUN /comfyui/.venv/bin/python -c "import kornia; print('[build] kornia', kornia.__version__)"

# worker-comfyui's /runpod-volume/models auto-detect is unreliable on this base;
# symlink ComfyUI's always-scanned model dirs straight at the volume (resolved at
# runtime once the network volume mounts).
RUN for d in checkpoints text_encoders latent_upscale_models loras; do \
      rm -rf "/comfyui/models/$d"; \
      ln -sfn "/runpod-volume/models/$d" "/comfyui/models/$d"; \
    done
