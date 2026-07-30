# app/core/config.py
import os
# pyrefly: ignore [missing-import]
from dotenv import load_dotenv

# Obtiene la ruta del directorio donde está este archivo 'config.py' (Backend/app/core/)
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
dotenv_path = os.path.join(CURRENT_DIR, ".env")

# Carga las variables desde el .env ubicado en la misma carpeta que config.py
load_dotenv(dotenv_path=dotenv_path)

class Settings:
    PROJECT_NAME: str = "Tienda Virtual API"
    PROJECT_VERSION: str = "2.0.0"

    DATABASE_URL: str = os.getenv("DATABASE_URL")
    SECRET_KEY: str = os.getenv("SECRET_KEY")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60))

    # Configuración de Supabase Storage
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://tyrxhfpmthuulifuropu.supabase.co")
    # Usa preferentemente la clave service_role para uploads desde backend
    SUPABASE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_KEY")
    # Nombre del bucket donde se guardarán las imágenes de productos
    SUPABASE_BUCKET: str = os.getenv("SUPABASE_BUCKET", "Images")

settings = Settings()
