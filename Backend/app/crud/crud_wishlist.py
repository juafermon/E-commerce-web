# Backend/app/crud/crud_wishlist.py
# Operaciones CRUD para el sistema de lista de deseos (Wishlist) de usuarios.

from typing import List, Optional


def get_wishlist_by_user(db, user_id: int) -> List[dict]:
    """Obtiene todos los artículos en la wishlist de un usuario con la info del producto."""
    query = """
        SELECT 
            w.id AS wishlist_id,
            w.user_id,
            w.article_id,
            w.added_at,
            a.name,
            a.description,
            a.price,
            a.stock,
            a.category,
            a.image_url,
            a.image_urls,
            a.is_available,
            a.rating_avg,
            a.rating_count
        FROM wishlists w
        JOIN articles a ON w.article_id = a.id
        WHERE w.user_id = %s
        ORDER BY w.added_at DESC;
    """
    db.execute(query, (user_id,))
    return db.fetchall()


def get_wishlist_item(db, user_id: int, article_id: int) -> Optional[dict]:
    """Verifica si un artículo específico ya está en la wishlist del usuario."""
    query = """
        SELECT id, user_id, article_id, added_at
        FROM wishlists
        WHERE user_id = %s AND article_id = %s;
    """
    db.execute(query, (user_id, article_id))
    return db.fetchone()


def add_to_wishlist(db, user_id: int, article_id: int) -> dict:
    """Agrega un artículo a la wishlist del usuario (evita duplicados con ON CONFLICT)."""
    query = """
        INSERT INTO wishlists (user_id, article_id)
        VALUES (%s, %s)
        ON CONFLICT (user_id, article_id) DO NOTHING
        RETURNING id, user_id, article_id, added_at;
    """
    db.execute(query, (user_id, article_id))
    result = db.fetchone()
    if result is None:
        # Ya existía → retornamos el registro existente
        return get_wishlist_item(db, user_id, article_id)
    return result


def remove_from_wishlist(db, user_id: int, article_id: int) -> bool:
    """Elimina un artículo de la wishlist del usuario. Retorna True si se eliminó algo."""
    query = """
        DELETE FROM wishlists
        WHERE user_id = %s AND article_id = %s
        RETURNING id;
    """
    db.execute(query, (user_id, article_id))
    return db.fetchone() is not None
