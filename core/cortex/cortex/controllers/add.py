from starlette.responses import JSONResponse
from utils.palace import palace_add

async def add_item(request):
    data = await request.json()
    room = data.get("room_id")
    content = data.get("content")
    palace_add(room, content)
    return JSONResponse({"status": "ok", "added": content})
