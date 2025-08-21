from fastapi import FastAPI, Request
from mem0 import Memory
import os

app = FastAPI()

memory = Memory.from_config({
    "vector_store": {
        "provider": "qdrant",
        "config": {"url": os.getenv("QDRANT_URL", "http://qdrant:6333")}
    }
})

@app.post("/webhook")
async def receive_webhook(req: Request):
    payload = await req.json()
    user_id = payload.get("user_id", "webhook")
    content = f"Received webhook data: {payload}"
    memory.add({"memory": content, "user_id": user_id})
    return {"status": "stored"}
