# app/database.py
# Este archivo define la conexión a la base de datos Supabase utilizando psycopg2, y proporciona una función de dependencia para inyectar el cursor en los endpoints de FastAPI.
import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
from Backend.app.core.config import settings

@contextmanager
def get_db_connection():
    """Abre y cierra la conexión física con Supabase de forma segura"""
    conn = psycopg2.connect(settings.DATABASE_URL) # <-- Usamos la variable centralizada
    try:
        yield conn
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()

def get_db():
    """Dependencia para inyectar el cursor en los endpoints de FastAPI"""
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            yield cursor
        finally:
            cursor.close()