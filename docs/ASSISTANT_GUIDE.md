# Jenny: offline laboratory assistant

## Turn her on

Right-click Cellarium's system-tray icon and check **Enable Assistant**. Jenny appears just above the Windows taskbar. Click her to open help; left-drag to move her to another monitor. Her feet snap above that monitor's taskbar. Right-click her for walking, outfit, idle pose, facing, sarcasm, depth, reset and Disable controls. Hiding the laboratory leaves Jenny independently available. Her enabled state and placement follow the existing desktop save.

Enter one English question and press Enter or Ask Jenny. Select a laboratory item first, or include its #ID for a particular specimen. The selected vial/organism remains selected when you click Jenny. If the topic or specimen is unclear, choose a clarification topic or rephrase. The topic buttons also provide verified help when the English model is unavailable.

## Answers and personality

The CPU MiniLM model produces sentence embeddings. A local intent index, scope checks, action/entity slots and confidence/margin rules identify a supported topic. Related preservation, transfer and culture intents share explanations to avoid artificial distinctions. Questions about post-installation steps request phase clarification rather than guessing. This is an intent matcher, not a conversational generative model.

Facts are authored from Cellarium's current rules and read from the live main-thread game state when the answer is delivered. Movement questions rerun the actual locomotion controller on a read-only clone, recompute capabilities from current tissues, inspect physiological limits, and rerun navigation when a recorded target exists. Genome analysis runs the actual expression and anatomical generator as a forecast, without rewriting the specimen. Installation diagnostics reuse the actual read-only installation validator. Culture status uses the actual culture-growth function. Death explanations use the recorded cause, not a guessed biological story. Missing IDs, incomplete records and multiple unselected specimens require clarification. Answers cannot run Lua, purchase supplies, consume cells or change experiments.

Sarcasm has Off, Dry and Sharp levels. The reviewed factual answer is kept intact; predefined, rotating remarks are appended separately. Repeated questions can get a mildly impatient line. Off gives the factual answer alone. Personality never supplies a diagnosis. The system may misunderstand a question or ask for clarification; finite query tests do not prove perfect English understanding.

## Artwork and idle behavior

The supplied sheets provide 111 retained frames in 18 cleaned atlases. Backgrounds and bright synthetic edge flecks were removed deterministically, with original subject pixels retained. No replacement character was generated. The clean first six frames of the combined montage were retained; its noisy duplicate panels were replaced by the separately supplied clean pose sheets. Adjacent merged chair-frame silhouettes were separated at their original middle boundary. Source-file and atlas hashes are recorded in assistant_assets/sprites/SOURCE.json.

Office appearance supports the supplied five-frame idle walking strip, standing stretches, original/reclined chairs, stool and seated reactions. Walking starts after an idle interval, stays near the taskbar and stops when help opens or the character is dragged. Casual supports standing, reaching, stretching and wide resting poses; it stays stationary between those sequences because no matching casual walking strip was supplied. The selected outfit is preserved. One body-scale control and a shared ground baseline apply across all frames. Per-sequence reference geometry preserves crouching and reclining; the oversized lying reference photos are calibrated to the standing scale rather than stretched to fill the character height. Pixel-bound checks and the scale contact sheet verify this. Wide poses expand the native window while transparent pixels continue to pass mouse input through. Atlases are at most 2048 by 2048 pixels.

## Runtime and installation

Keep **assistant_assets** beside the executable. The package contains the quantized MiniLM model (23,046,789 bytes), tokenizer vocabulary, ONNX Runtime 1.31.1 CPU libraries, Microsoft C++ runtime dependencies, cleaned sprites, licenses and hashes. No Python, separate server, account, API key, GPU inference provider or first-launch download is required. Model startup and embedding run on a background LÖVE thread. ORT telemetry is explicitly disabled. Conversation text is held in session memory and is not written into the experiment save.

The model's upstream filename includes avx2 because of its quantization tuning. Its graph uses standard ONNX opset-14 operators, not encoded AVX instructions. The bundled runtime's MLAS source initializes SSE2 kernels and checks CPU/OS AVX support before choosing faster kernels. Target: Windows 10 1809+ / Windows 11 x64 with SSE2. Inference was run with the bundled C++ DLLs preloaded, so it did not rely on a newer system copy. Physical non-AVX hardware was not available; that hardware test remains unverified.

Primary sources: [MiniLM model](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2), [ONNX Runtime CPU distribution](https://github.com/microsoft/onnxruntime/releases/tag/v1.31.1), [SSE2/CPUID dispatch](https://github.com/microsoft/onnxruntime/blob/v1.31.1/onnxruntime/core/mlas/lib/platform.cpp#L419), [Windows runtime requirements](https://onnxruntime.ai/docs/install/).

## Verification commands

With LÖVE 11.5: `love . --assistant-test`, `love . --assistant-native-test`, `love . --assistant-eval`, `love . --assistant-holdout`. Native tests require an interactive desktop. Regenerate the checked-in example embedding index with `love . --assistant-index` after changing examples. Do not treat the question audits as a general guarantee of classification accuracy. Keep the confidence and out-of-scope behavior visible in the report.
