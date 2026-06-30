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

# Bucket output for large videos. A 10s/720p LTX clip overflows RunPod's inline
# base64 status payload and comes back empty ("COMPLETED but no output"); routing it
# to a bucket fixes that (the provider re-hosts the returned URL into our own GCS).
# Stock worker-comfyui calls `rp_upload.upload_image(job_id, temp_file_path)` with NO
# bucket name, so the runpod SDK defaults to a "%m-%y" bucket (e.g. 06-30) — never
# ours. There is no BUCKET_NAME env hook, so patch the single call site to pass it
# (os is already imported in handler.py @5.8.6). The grep guard FAILS the build if a
# worker-comfyui bump ever changes that call site, so a silent no-match can't ship a
# broken upload. Set on the endpoint: BUCKET_ENDPOINT_URL=https://storage.googleapis.com,
# BUCKET_NAME=itihasik-greenrain, BUCKET_ACCESS_KEY_ID/SECRET = a GCS HMAC key.
RUN sed -i 's|rp_upload.upload_image(job_id, temp_file_path)|rp_upload.upload_image(job_id, temp_file_path, bucket_name=os.environ.get("BUCKET_NAME"))|' /handler.py \
 && grep -q 'bucket_name=os.environ.get("BUCKET_NAME")' /handler.py

# botocore >=1.36 adds default flexible-checksum headers to PutObject that GCS's
# S3-compatible API rejects -> SignatureDoesNotMatch. Disable them so the HMAC upload
# to storage.googleapis.com signs cleanly. (Verified: GCS PUT works only with these off.)
ENV AWS_REQUEST_CHECKSUM_CALCULATION=when_required \
    AWS_RESPONSE_CHECKSUM_VALIDATION=when_required
