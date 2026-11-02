# Backend/app/crud/crud_rating.py
# Operaciones CRUD para el sistema de calificaciones y reseñas de productos.

from typing import List, Optional
from Backend.app import schemas

def get_ratings_by_article(db, article_id: int) -> List[dict]:
    """Obtiene todas las calificaciones de un producto con los nombres de usuario"""
    query = """
        SELECT r.id, r.article_id, r.user_id, u.username, r.rating, r.comment, r.created_at, r.updated_at
        FROM product_ratings r
        JOIN users u ON r.user_id = u.id
        WHERE r.article_id = %s
        ORDER BY r.created_at DESC;
    """
    db.execute(query, (article_id,))
    return db.fetchall()

def get_user_rating(db, article_id: int, user_id: int) -> Optional[dict]:
    """Obtiene la calificación específica que un usuario dio a un artículo (si existe)"""
    query = """
        SELECT r.id, r.article_id, r.user_id, u.username, r.rating, r.comment, r.created_at, r.updated_at
        FROM product_ratings r
        JOIN users u ON r.user_id = u.id
        WHERE r.article_id = %s AND r.user_id = %s;
    """
    db.execute(query, (article_id, user_id))
    return db.fetchone()

def upsert_rating(db, article_id: int, user_id: int, rating_data: schemas.RatingCreate) -> dict:
    """
    Inserta o actualiza la calificación de un usuario para un artículo (UPSERT),
    y luego recalcula y actualiza automáticamente el promedio y conteo en la tabla 'articles'.
    """
    # 1. Insertar o actualizar la reseña
    upsert_query = """
        INSERT INTO product_ratings (article_id, user_id, rating, comment, updated_at)
        VALUES (%s, %s, %s, %s, NOW())
        ON CONFLICT (article_id, user_id) 
        DO UPDATE SET 
            rating = EXCLUDED.rating,
            comment = EXCLUDED.comment,
            updated_at = NOW()
        RETURNING id, article_id, user_id, rating, comment, created_at, updated_at;
    """
    db.execute(upsert_query, (article_id, user_id, rating_data.rating, rating_data.comment))
    rating_row = db.fetchone()

    # 2. Recalcular y actualizar rating_avg y rating_count en la tabla 'articles'
    update_article_stats_query = """
        UPDATE articles
        SET 
            rating_avg = COALESCE((
                SELECT ROUND(AVG(rating)::numeric, 1) 
                FROM product_ratings 
                WHERE article_id = %s
            ), 0.0),
            rating_count = (
                SELECT COUNT(*) 
                FROM product_ratings 
                WHERE article_id = %s
            )
        WHERE id = %s;
    """
    db.execute(update_article_stats_query, (article_id, article_id, article_id))

    # 3. Obtener el nombre del usuario para la respuesta
    db.execute("SELECT username FROM users WHERE id = %s;", (user_id,))
    user_row = db.fetchone()
    username = user_row["username"] if user_row else "Usuario"

    rating_row["username"] = username
    return rating_row
