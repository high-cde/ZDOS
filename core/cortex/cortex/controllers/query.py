from starlette.responses import JSONResponse
from utils.palace import palace_query

async def query_item(request):
    data = await request.json()
    text = data.get("text")
    results = palace_query(text)
    return JSONResponse({"status": "ok", "results": results})
