from starlette.responses import JSONResponse

async def list_rooms(request):
    return JSONResponse({"rooms": ["W1-H1-R1", "W1-H1-R2"]})
