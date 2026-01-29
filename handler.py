import torch
import soundfile as sf
import os
import base64
import runpod
from qwen_tts import Qwen3TTSModel
from pathlib import Path

# --- CONFIGURATION ---
MODEL_ID = "Qwen/Qwen3-TTS-12Hz-1.7B-Base"
EMBED_DIR = "/workspace/qwen3_tts/embedding"
OUT_DIR = "/tmp"  # Use /tmp for serverless ephemeral storage

# Global variables to store loaded assets
model = None
voice_cache = {}

def load_assets():
    """Initializes the model and voice cache once per worker."""
    global model, voice_cache
    
    if model is None:
        print("Loading model into VRAM...")
        torch.set_float32_matmul_precision('high')
        model = Qwen3TTSModel.from_pretrained(
            MODEL_ID,
            device_map="cuda:0",
            dtype=torch.bfloat16,
            attn_implementation="sdpa"
        )
        model.model = torch.compile(model.model, mode="reduce-overhead")

    if not voice_cache:
        print("Caching voice embeddings...")
        for pt_file in Path(EMBED_DIR).glob("*.pt"):
            voice_cache[pt_file.stem] = torch.load(
                pt_file, 
                map_location="cuda:0", 
                weights_only=False
            )
        print(f"System Ready. Cached {len(voice_cache)} voices.")

def handler(job):
    """
    Standard RunPod handler. 
    Expects input: {"character": "voice_name", "prompt": "text to say"}
    """
    load_assets()
    
    job_input = job['input']
    name = job_input.get("character")
    text = job_input.get("prompt")

    if name not in voice_cache:
        return {"error": f"Voice '{name}' not found in cache."}

    # Generate audio
    wavs, sr = model.generate_voice_clone(
        text=text,
        language="English",
        voice_clone_prompt=voice_cache[name]
    )

    # Save to a temporary file
    temp_filename = f"{OUT_DIR}/output.wav"
    sf.write(temp_filename, wavs[0], sr)

    # Convert audio to base64 for the JSON response
    with open(temp_filename, "rb") as audio_file:
        encoded_string = base64.b64encode(audio_file.read()).decode("utf-8")

    return {
        "audio_base64": encoded_string,
        "format": "wav",
        "sampling_rate": sr
    }

# Start the serverless worker
runpod.serverless.start({"handler": handler})