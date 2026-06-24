# LTX 2.3 serverless worker for Itihasik.
# The LTX nodes we use — the T2V graph AND the LTXVAddGuide conditioning node —
# are ALL in ComfyUI core (comfy_extras/nodes_lt.py + nodes_lt_audio.py), so NO
# custom-node pack is needed. Proven: T2V *and* keyframe conditioning both
# generate video on this base image with zero custom nodes. Models live on the
# attached network volume (mounted at /runpod-volume at runtime).
#
# CUDA pin: plain :5.8.6-base ships a PyTorch built for a CUDA newer than the
# RunPod GPU host driver (CUDA 12.8) -> torch fails its GPU check, worker exits(1).
FROM runpod/worker-comfyui:5.8.6-base-cuda12.8.1

# worker-comfyui's /runpod-volume/models auto-detect is unreliable on this base;
# symlink ComfyUI's always-scanned model dirs straight at the volume (resolved at
# runtime once the network volume mounts).
RUN for d in checkpoints text_encoders latent_upscale_models loras; do \
      rm -rf "/comfyui/models/$d"; \
      ln -sfn "/runpod-volume/models/$d" "/comfyui/models/$d"; \
    done
