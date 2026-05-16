from starlette.responses import JSONResponse
from utils.zaaak import encode, decode

async def encode_data(request):
    data = await request.json()
    return JSONResponse({"encoded": encode(data.get("text", ""))})

async def decode_data(request):
    data = await request.json()
    return JSONResponse({"decoded": decode(data.get("blob", ""))})
