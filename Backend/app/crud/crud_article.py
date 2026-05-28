# app/crud/crud_article.py
# Este archivo define las funciones CRUD para manejar los artículos en la base de datos de Supabase.
# Estas funciones serán utilizadas por los endpoints de FastAPI para interactuar con la base de datos
from Backend.app import schemas

def get_articles(db, skip: int = 0, limit: int = 100):
    """Obtiene la lista de artículos disponibles en la tienda"""
    query = """
        SELECT id, name, description, price, stock, category, image_url, is_available 
        FROM ARTICLES 
        WHERE is_available = TRUE 
        ORDER BY id DESC 
        LIMIT %s OFFSET %s;
    """
    db.execute(query, (limit, skip))
    return db.fetchall()

def get_article_by_id(db, article_id: int):
    """Busca un artículo específico por su ID"""
    query = "SELECT * FROM ARTICLES WHERE id = %s;"
    db.execute(query, (article_id,))
    return db.fetchone()

def create_article(db, article: schemas.ArticleCreate):
    """Inserta un nuevo artículo en el catálogo de Supabase (Solo Admin)"""
    query = """
        INSERT INTO ARTICLES (name, description, price, stock, category, image_url, is_available)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        RETURNING id, name, description, price, stock, category, image_url, is_available;
    """
    params = (
        article.name,
        article.description,
        article.price,
        article.stock,
        article.category,
        article.image_url,
        True # Disponible por defecto
    )
    db.execute(query, params)
    return db.fetchone()

def update_article(db, article_id: int, article_data: schemas.ArticleCreate):
    """Actualiza los datos de un artículo existente en Supabase"""
    query = """
        UPDATE ARTICLES 
        SET name = %s, description = %s, price = %s, stock = %s, category = %s, image_url = %s
        WHERE id = %s
        RETURNING id, name, description, price, stock, category, image_url, is_available;
    """
    params = (
        article_data.name,
        article_data.description,
        article_data.price,
        article_data.stock,
        article_data.category,
        article_data.image_url,
        article_id
    )
    db.execute(query, params)
    return db.fetchone()