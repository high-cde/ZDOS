from starlette.routing import Route
from controllers.add import add_item
from controllers.query import query_item
from controllers.rooms import list_rooms
from controllers.zaaak import encode_data, decode_data

cortex_routes = [
    Route("/add", add_item, methods=["POST"]),
    Route("/query", query_item, methods=["POST"]),
    Route("/rooms", list_rooms, methods=["GET"]),
    Route("/zaaak/encode", encode_data, methods=["POST"]),
    Route("/zaaak/decode", decode_data, methods=["POST"]),
]
