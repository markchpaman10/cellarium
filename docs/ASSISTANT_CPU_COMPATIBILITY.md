# CPU compatibility evidence

Model: pinned MiniLM unsigned-int8 ONNX export, opset 14. No CUDA, DirectML or GPU provider is requested. Intra-op threads: 2. ORT API 17 against runtime 1.31.1. Actual native inference with 384-dimensional normalized mean-pooled output passed.

The official runtime source defaults to SSE2 float and unsigned/signed integer GEMM dispatch. It checks SSE 4.1 separately, then checks CPUID AVX/OSXSAVE plus OS state support before selecting AVX. Source inspected: https://github.com/microsoft/onnxruntime/blob/v1.31.1/onnxruntime/core/mlas/lib/platform.cpp#L419 . The inspected model uses standard ONNX integer matmul/dequantization and floating-point operations; it does not embed an AVX machine-code requirement.

This establishes the intended baseline fallback, not a physical non-AVX test result. No non-AVX machine or CPU emulator was available in this session. Do not label that check passed. Existing Windows/OpenGL requirements of the LÖVE game still apply.

Opsets: [[(2, 14)]]
Operators: [('', 'Add'), ('', 'Cast'), ('', 'Concat'), ('', 'Constant'), ('', 'ConstantOfShape'), ('', 'DequantizeLinear'), ('', 'Div'), ('', 'DynamicQuantizeLinear'), ('', 'Equal'), ('', 'Erf'), ('', 'Expand'), ('', 'Gather'), ('', 'MatMulInteger'), ('', 'Mul'), ('', 'Pow'), ('', 'ReduceMean'), ('', 'Reshape'), ('', 'Shape'), ('', 'Slice'), ('', 'Softmax'), ('', 'Sqrt'), ('', 'Sub'), ('', 'Transpose'), ('', 'Unsqueeze'), ('', 'Where')]