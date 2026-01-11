from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from starlette.templating import Jinja2Templates

from app.web.routes.home import router as home_router
from app.web.routes.upload import router as upload_router
from app.web.routes.paste import router as paste_router
from app.web.routes.paste_text import router as paste_text_router

# Default: Maybe move app/fastapi to this structure
# def main():
#     print("Hello from pastebin!")
#
#
# if __name__ == "__main__":
#     main()
#

def create_app() -> FastAPI:
    app = FastAPI(title="myapp")

    app.mount("/static", StaticFiles(directory="app/static"), name="static")

    # *** REGISTER ROUTERS ***
    # GET "/" home/index.html
    app.include_router(home_router)
    # POST "/upload" 
    app.include_router(upload_router)
    # GET "/p/{id}"
    # GET "/f/{id}"
    app.include_router(paste_router)
    # POST "/paste"
    app.include_router(paste_text_router)
    return app

app = create_app()
templates = Jinja2Templates(directory="app/templates")

