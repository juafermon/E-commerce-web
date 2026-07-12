# app/core/config.py
import os
# pyrefly: ignore [missing-import]
from dotenv import load_dotenv

# Obtiene la ruta del directorio actual donde está este archivo 'config.py'
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
dotenv_path = os.path.join(CURRENT_DIR, ".env")

# Carga las variables desde la ruta específica (.env en la misma carpeta)
load_dotenv(dotenv_path=dotenv_path)

class Settings:
    PROJECT_NAME: str = "Tienda Virtual API"
    PROJECT_VERSION: str = "2.0.0"
    
    DATABASE_URL: str = os.getenv("DATABASE_URL")
    SECRET_KEY: str = os.getenv("SECRET_KEY")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60))

settings = Settings()
