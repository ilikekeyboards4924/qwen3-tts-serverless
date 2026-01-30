import runpod

def handler(job):
    job_input = job['input']
    voice = job_input.get("voice")
    text = job_input.get("prompt")    

    return {
        "status": "ok", 
        "message": f"received request to use the voice ({voice}) and prompt ({text})"
    }

runpod.serverless.start({"handler": handler})