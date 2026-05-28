# app/crud/crud_user.py
# Este módulo maneja la lógica de negocio relacionada con los usuarios, incluyendo:
# - Registro de nuevos usuarios con validación de datos y hashing de contraseñas.
from Backend.app import schemas

def get_user_by_username(db, username: str):
    """Busca un usuario en Supabase por su nombre de usuario único"""
    query = "SELECT id, username, password_hash, role, is_active FROM USERS WHERE username = %s;"
    db.execute(query, (username,))
    return db.fetchone()

def create_user(db, user: schemas.UserCreate, hashed_password: str):
    """Inserta un nuevo cliente (rol: 'user') en PostgreSQL y devuelve el registro"""
    query = """
        INSERT INTO USERS (username, password_hash, role, is_active)
        VALUES (%s, %s, %s, %s)
        RETURNING id, username, role, is_active;
    """
    params = (user.username, hashed_password, "user", True)
    db.execute(query, params)
    return db.fetchone()