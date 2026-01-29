import runpod

def handler(job):
    """
    Minimal handler that ignores specific inputs 
    and returns a success message.
    """
    # job['input'] contains your request data, 
    # but we are purposefully ignoring it.
    
    return {"status": "ok", "message": "Request received and processed."}

# Start the serverless worker
runpod.serverless.start({"handler": handler})