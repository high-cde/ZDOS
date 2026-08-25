from starlette.applications import Starlette
from starlette.middleware import Middleware
from starlette.responses import JSONResponse
from starlette.routing import Mount

from cortex.middleware import RequestLogger
from cortex.router import cortex_routes

app = Starlette(
    debug=True,
    routes=[Mount("/", routes=cortex_routes)],
    middleware=[Middleware(RequestLogger)]
)

@app.route("/")
async def root(request):
    return JSONResponse({"status": "CORTEX OK"})
