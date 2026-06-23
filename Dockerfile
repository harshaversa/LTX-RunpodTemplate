# LTX 2.3 serverless worker for Itihasik.
# Official RunPod ComfyUI worker + the Lightricks ComfyUI-LTXVideo nodes.
# Models live on the attached network volume (mounted at /runpod-volume at runtime).
#
# CUDA pin: plain :5.8.6-base ships a PyTorch built for a CUDA newer than the
# RunPod GPU host driver (CUDA 12.8) -> torch fails its GPU check, worker exits(1).
# The -cuda12.8.1 variant's torch matches the 12.8 driver.
FROM runpod/worker-comfyui:5.8.6-base-cuda12.8.1

# LTX 2.3 nodes. comfy-node-install places the pack, but ComfyUI-Manager
# BLACKLISTS `kornia` (build log: "skip black listed pip installation: 'kornia'"),
# which the pack imports at top level (pyramid_blending.py). The missing import
# makes ComfyUI mark the WHOLE pack IMPORT FAILED -> every node
# (LTXVAddGuideAdvanced, LTXVTiledVAEDecode, ...) returns missing_node_type.
# Fix = install kornia into the worker venv (/comfyui/.venv, uv-managed).
RUN comfy-node-install comfyui-ltxvideo
RUN /comfyui/.venv/bin/python -m uv pip install kornia \
 || /comfyui/.venv/bin/python -m pip install kornia

# Build-time self-check: load the pack exactly like ComfyUI does (by file path, so
# the hyphenated dir name + relative imports resolve) and assert the guide node
# registers. Fail the build with a full traceback otherwise, so a silently-broken
# pack never reaches the running endpoint.
RUN /comfyui/.venv/bin/python - <<'PYCHECK'
import importlib.util, sys, os, traceback
base = "/comfyui/custom_nodes"
try:
    import kornia
    print(">>> [self-check] kornia OK", kornia.__version__, flush=True)
except Exception:
    print("!!! [self-check] kornia import FAILED", flush=True); traceback.print_exc(); sys.exit(1)
dirs = [d for d in os.listdir(base) if "ltx" in d.lower() and os.path.isdir(os.path.join(base, d))]
print(">>> [self-check] LTX pack dirs:", dirs, flush=True)
ok = False
for d in dirs:
    init = os.path.join(base, d, "__init__.py")
    if not os.path.exists(init):
        continue
    name = "pkg_" + "".join(c if c.isalnum() else "_" for c in d)
    try:
        spec = importlib.util.spec_from_file_location(name, init, submodule_search_locations=[os.path.join(base, d)])
        mod = importlib.util.module_from_spec(spec); sys.modules[name] = mod
        spec.loader.exec_module(mod)
        mappings = getattr(mod, "NODE_CLASS_MAPPINGS", {}) or {}
        print(">>> [self-check]", d, ":", len(mappings), "node classes", flush=True)
        if "LTXVAddGuideAdvanced" in mappings:
            ok = True; print(">>> [self-check] LTXVAddGuideAdvanced registered in", d, flush=True)
    except Exception:
        print("!!! [self-check] import of", d, "FAILED:", flush=True); traceback.print_exc()
if not ok:
    print("!!! [self-check] LTXVAddGuideAdvanced NOT registered -> FAILING BUILD", flush=True); sys.exit(1)
print(">>> [self-check] PASS", flush=True)
PYCHECK

# worker-comfyui's /runpod-volume/models auto-detect is unreliable on this base;
# symlink ComfyUI's always-scanned model dirs straight at the volume (they resolve
# once the network volume mounts at /runpod-volume at runtime).
RUN for d in checkpoints text_encoders latent_upscale_models loras; do \
      rm -rf "/comfyui/models/$d"; \
      ln -sfn "/runpod-volume/models/$d" "/comfyui/models/$d"; \
    done
