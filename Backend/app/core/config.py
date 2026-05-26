# app/core/config.py
import os
from dotenv import load_dotenv

# Carga las variables desde el archivo .env
load_dotenv()

class Settings:
    PROJECT_NAME: str = "Tienda Virtual API"
    PROJECT_VERSION: str = "2.0.0"
    
    # Extrae las credenciales con un valor por defecto seguro si no existieran
    DATABASE_URL: str = os.getenv("DATABASE_URL")
    SECRET_KEY: str = os.getenv("SECRET_KEY")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60))

# Instancia global para importar en todo el proyecto
settings = Settings()