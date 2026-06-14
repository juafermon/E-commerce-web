# app/crud/crud_user.py
# Este módulo maneja la lógica de negocio relacionada con los usuarios, incluyendo:
# - Registro de nuevos usuarios con validación de datos y hashing de contraseñas.
# Backend/app/crud/crud_user.py
from Backend.app import schemas

def get_user_by_username(db, username: str):
    """Busca un usuario en Supabase por su nombre de usuario único"""
    query = "SELECT id, username, password_hash, role, is_active FROM USERS WHERE username = %s;"
    db.execute(query, (username,))
    return db.fetchone()

def get_user_by_document(db, doc_number: str):
    """Busca si ya existe un usuario registrado con el mismo número de documento"""
    query = "SELECT id FROM USERS WHERE doc_number = %s;"
    db.execute(query, (doc_number,))
    return db.fetchone()

def create_user(db, user: schemas.UserCreate, hashed_password: str):
    """Inserta un nuevo cliente con todos sus datos extendidos en PostgreSQL/Supabase"""
    query = """
        INSERT INTO USERS (username, password_hash, role, is_active, email, address, id_type, doc_number)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id, username, role, is_active, email, address, id_type, doc_number::text;
    """
    params = (
        user.username, 
        hashed_password, 
        "user", 
        True, 
        user.email, 
        user.address, 
        user.id_type, 
        user.doc_number
    )
    db.execute(query, params)
    return db.fetchone()