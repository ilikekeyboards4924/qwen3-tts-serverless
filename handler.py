import torch
import soundfile as sf
import base64
import runpod
import os
from datetime import datetime
from qwen_tts import Qwen3TTSModel
from pathlib import Path

# --- MINIMAL CONFIG ---
MODEL_ID = "Qwen/Qwen3-TTS-12Hz-1.7B-Base"
# Ensure this matches your actual folder on RunPod
EMBED_DIR = "/workspace/qwen3_tts/embedding" 
model = None

def load_assets():
    global model
    if model is None:
        model = Qwen3TTSModel.from_pretrained(
            MODEL_ID,
            device_map="cuda:0",
            torch_dtype=torch.bfloat16,
            attn_implementation="sdpa"
        )

def handler(job):
    load_assets()
    
    # 1. Get the current time as a readable string
    current_time = datetime.now().strftime("%I:%M %p")
    text_to_say = f"The current time is {current_time}."

    # 2. Hardcode a voice name from your embedding folder
    # Replace 'glados' with whatever .pt file you actually have
    voice_name = "brantley" 
    voice_path = Path(EMBED_DIR) / f"{voice_name}.pt"
    
    voice_embedding = torch.load(voice_path, map_location="cuda:0", weights_only=False)

    # 3. Generate Audio
    wavs, sr = model.generate_voice_clone(
        text=text_to_say,
        language="English",
        voice_clone_prompt=voice_embedding
    )

    # 4. Convert to Base64
    temp_file = "/tmp/out.wav"
    sf.write(temp_file, wavs[0], sr)
    
    with open(temp_file, "rb") as f:
        audio_b64 = base64.b64encode(f.read()).decode("utf-8")

    return {"audio_base64": audio_b64}

runpod.serverless.start({"handler": handler})