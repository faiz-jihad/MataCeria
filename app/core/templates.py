import os
from fastapi.templating import Jinja2Templates

# Use absolute path for the templates directory to ensure reliability in Docker
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
templates_dir = os.path.join(BASE_DIR, "templates")

templates = Jinja2Templates(directory=templates_dir)
