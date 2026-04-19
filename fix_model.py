"""
Verify and re-export a clean, Flutter-compatible ONNX model.

Step 1: Test if ai/models/nakhlah_v2.onnx (IR9, opset11) runs correctly in onnxruntime.
Step 2: If yes, export a fresh model with opset=11 from the .pth weights.
Step 3: Copy the working model to assets.
"""
import sys
import numpy as np

# ── Step 1: Test existing IR9 model with onnxruntime ─────────────────────────
print("=" * 60)
print("Testing ai/models/nakhlah_v2.onnx with onnxruntime...")
print("=" * 60)

try:
    import onnxruntime as ort

    sess_opts = ort.SessionOptions()
    sess_opts.intra_op_num_threads = 2
    sess_opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL

    sess = ort.InferenceSession(
        "ai/models/nakhlah_v2.onnx",
        sess_opts=sess_opts,
        providers=["CPUExecutionProvider"],
    )

    dummy = np.random.randn(1, 3, 260, 260).astype(np.float32)
    out = sess.run(None, {"input": dummy})
    print(f"✅ Inference succeeded! Output shape: {out[0].shape}")
    print(f"   Sample logits: {out[0][0][:5]}")
    IR9_WORKS = True
except Exception as e:
    print(f"❌ Inference failed: {e}")
    IR9_WORKS = False

print()

# ── Step 2: Re-export cleanly with opset=11 if IR9 is broken ─────────────────
if not IR9_WORKS:
    print("=" * 60)
    print("Re-exporting from .pth weights with opset=11...")
    print("=" * 60)
    try:
        import torch
        import torch.nn as nn
        from torchvision import models
        from pathlib import Path

        def build_model():
            net = models.efficientnet_b2(weights=None)
            in_features = net.classifier[1].in_features
            net.classifier = nn.Sequential(
                nn.Dropout(p=0.3, inplace=True),
                nn.Linear(in_features, 512),
                nn.BatchNorm1d(512),
                nn.SiLU(),
                nn.Dropout(p=0.2),
                nn.Linear(512, 9),
            )
            return net

        MODEL_PTH = Path("ai/models/nakhlah_model_v2_final.pth")
        OUT_PATH  = Path("ai/models/nakhlah_v2_opset11.onnx")

        net = build_model()
        ckpt = torch.load(MODEL_PTH, map_location="cpu", weights_only=False)
        state = (
            ckpt.get("model_state_dict") or ckpt.get("model_state")
            or ckpt.get("state_dict") or ckpt
        ) if isinstance(ckpt, dict) else ckpt
        net.load_state_dict(state, strict=True)
        net.eval()
        print("✅ Checkpoint loaded")

        dummy_pt = torch.zeros(1, 3, 260, 260)
        with torch.no_grad():
            torch.onnx.export(
                net,
                dummy_pt,
                str(OUT_PATH),
                opset_version=11,           # opset 11 = widely supported
                input_names=["input"],
                output_names=["logits"],
                dynamic_axes={"input": {0: "batch_size"}, "logits": {0: "batch_size"}},
                do_constant_folding=True,
            )
        print(f"✅ Exported to {OUT_PATH}")

        # Verify the new export
        import onnx
        m = onnx.load(str(OUT_PATH))
        print(f"   IR={m.ir_version}, opset={m.opset_import[0].version}")

        sess2 = ort.InferenceSession(str(OUT_PATH), providers=["CPUExecutionProvider"])
        out2 = sess2.run(None, {"input": dummy})
        print(f"✅ New export inference OK! Shape: {out2[0].shape}")

        # Copy to assets
        import shutil
        dest = Path("NakhlahApp/assets/models/nakhlah_v2_compat.onnx")
        shutil.copy(OUT_PATH, dest)
        print(f"✅ Copied to {dest}")

    except Exception as e:
        print(f"❌ Re-export failed: {e}")
        sys.exit(1)
else:
    # IR9 model works fine — just copy it to assets
    import shutil
    from pathlib import Path
    src  = Path("ai/models/nakhlah_v2.onnx")
    dest = Path("NakhlahApp/assets/models/nakhlah_v2_compat.onnx")
    shutil.copy(src, dest)
    size_mb = dest.stat().st_size / 1_000_000
    print(f"✅ Copied working IR9 model to assets: {dest.name} ({size_mb:.1f} MB)")
    print()
    print("🎯 FINAL SUMMARY")
    print(f"   Use model file : nakhlah_v2_compat.onnx")
    print(f"   IR version     : 9")
    print(f"   Opset          : 11")
    print(f"   Size           : {size_mb:.1f} MB")
