import onnx

for fname in ['ai/models/nakhlah_v2_int8.onnx', 'ai/models/nakhlah_v2.onnx', 'ai/models/nakhlah_v2_ir9.onnx']:
    try:
        m = onnx.load(fname)
        print(f"\n=== {fname} ===")
        print(f"  IR version : {m.ir_version}")
        print(f"  Opset      : {m.opset_import[0].version}")
        for inp in m.graph.input:
            shape = [d.dim_value if d.dim_value else d.dim_param for d in inp.type.tensor_type.shape.dim]
            print(f"  Input  {inp.name}: {shape}")
        for out in m.graph.output:
            shape = [d.dim_value if d.dim_value else d.dim_param for d in out.type.tensor_type.shape.dim]
            print(f"  Output {out.name}: {shape}")
    except Exception as e:
        print(f"\n=== {fname} === ERROR: {e}")
