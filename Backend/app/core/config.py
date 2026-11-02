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
    # Para llamadas a Supabase Storage, se debe usar un JWT válido (eyJ...) o la clave publishable (sb_publishable_...).
    # Las claves de tipo sb_secret_... son tokens de gestión que la API de Storage rechaza con 'Invalid Compact JWS'.
    _svc_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    _pb_key = os.getenv("SUPABASE_KEY", "").strip()
    SUPABASE_KEY: str = _svc_key if _svc_key.startswith("eyJ") else (_pb_key if _pb_key else _svc_key)
    # Nombre del bucket donde se guardarán las imágenes de productos
    SUPABASE_BUCKET: str = os.getenv("SUPABASE_BUCKET", "images")

settings = Settings()
