# app/database.py
# Este archivo define la conexión a la base de datos Supabase utilizando psycopg2, y proporciona una función de dependencia para inyectar el cursor en los endpoints de FastAPI.
import psycopg2
from psycopg2.extras import RealDictCursor
from psycopg2.pool import ThreadedConnectionPool
from contextlib import contextmanager
from Backend.app.core.config import settings

# Inicializamos el Pool de Conexiones al arrancar el backend.
# Mantiene conexiones persistentes listas para usar, evitando el retardo de conexión física (handshake TCP/SSL) en cada petición.
db_pool = ThreadedConnectionPool(1, 10, settings.DATABASE_URL)

@contextmanager
def get_db_connection():
    """Obtiene una conexión reutilizable del Pool de Conexiones en lugar de abrir una nueva"""
    conn = db_pool.getconn()
    try:
        yield conn
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        db_pool.putconn(conn) # Devuelve la conexión al pool para su reutilización

def get_db():
    """Dependencia para inyectar el cursor en los endpoints de FastAPI"""
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            yield cursor
        finally:
            cursor.close()