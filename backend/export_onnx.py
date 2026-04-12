import torch
from app.model_loader import NakhlahModel

# حمّل المودل (نفس loader الحالي)
model_wrapper = NakhlahModel.instance()
model = model_wrapper.model  # هذا مهم

# dummy input (نفس preprocessing)
dummy = torch.randn(1, 3, 260, 260)

# export
torch.onnx.export(
    model,
    dummy,
    "models/nakhlah_v2.onnx",
    input_names=["image"],
    output_names=["logits"],
    dynamic_axes={"image": {0: "batch"}},
    opset_version=17,
)

print("✅ ONNX exported to models/nakhlah_v2.onnx")