# app/crud/crud_article.py
# Este archivo define las funciones CRUD para manejar los artículos en la base de datos de Supabase.
# Estas funciones serán utilizadas por los endpoints de FastAPI para interactuar con la base de datos
from Backend.app import schemas

def get_articles(db, skip: int = 0, limit: int = 100):
    """Obtiene la lista de artículos disponibles en la tienda"""
    query = """
        SELECT id, name, description, price, stock, category, image_urls, is_available 
        FROM ARTICLES 
        WHERE is_available = TRUE 
        ORDER BY id DESC 
        LIMIT %s OFFSET %s;
    """
    db.execute(query, (limit, skip))
    results = db.fetchall()
    for row in results:
        if row.get("image_urls") and len(row["image_urls"]) > 0:
            row["image_url"] = row["image_urls"][0]
        else:
            row["image_url"] = None
    return results

def get_article_by_id(db, article_id: int):
    """Busca un artículo específico por su ID"""
    query = "SELECT id, name, description, price, stock, category, image_urls, is_available FROM ARTICLES WHERE id = %s;"
    db.execute(query, (article_id,))
    row = db.fetchone()
    if row:
        if row.get("image_urls") and len(row["image_urls"]) > 0:
            row["image_url"] = row["image_urls"][0]
        else:
            row["image_url"] = None
    return row

def create_article(db, article: schemas.ArticleCreate):
    """Inserta un nuevo artículo en el catálogo de Supabase (Solo Admin) y registra sus imágenes"""
    query = """
        INSERT INTO ARTICLES (name, description, price, stock, category, image_urls, is_available)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        RETURNING id, name, description, price, stock, category, image_urls, is_available;
    """
    params = (
        article.name,
        article.description,
        article.price,
        article.stock,
        article.category,
        article.image_urls,
        True # Disponible por defecto
    )
    db.execute(query, params)
    row = db.fetchone()
    
    if row and article.image_urls:
        article_id = row["id"]
        for idx, url in enumerate(article.image_urls):
            is_primary = (idx == 0)
            sort_order = idx
            insert_img_query = """
                INSERT INTO article_images (article_id, url_thumb, url_medium, url_full, is_primary, sort_order)
                VALUES (%s, %s, %s, %s, %s, %s);
            """
            db.execute(insert_img_query, (article_id, url, url, url, is_primary, sort_order))
            
    if row:
        if row.get("image_urls") and len(row["image_urls"]) > 0:
            row["image_url"] = row["image_urls"][0]
        else:
            row["image_url"] = None
    return row

def update_article(db, article_id: int, article_data: schemas.ArticleCreate):
    """Actualiza los datos de un artículo existente en Supabase y sincroniza sus imágenes"""
    query = """
        UPDATE ARTICLES 
        SET name = %s, description = %s, price = %s, stock = %s, category = %s, image_urls = %s
        WHERE id = %s
        RETURNING id, name, description, price, stock, category, image_urls, is_available;
    """
    params = (
        article_data.name,
        article_data.description,
        article_data.price,
        article_data.stock,
        article_data.category,
        article_data.image_urls,
        article_id
    )
    db.execute(query, params)
    row = db.fetchone()
    
    # Sincronizar imágenes: eliminar anteriores e insertar la lista actualizada
    db.execute("DELETE FROM article_images WHERE article_id = %s;", (article_id,))
    if article_data.image_urls:
        for idx, url in enumerate(article_data.image_urls):
            is_primary = (idx == 0)
            sort_order = idx
            insert_img_query = """
                INSERT INTO article_images (article_id, url_thumb, url_medium, url_full, is_primary, sort_order)
                VALUES (%s, %s, %s, %s, %s, %s);
            """
            db.execute(insert_img_query, (article_id, url, url, url, is_primary, sort_order))
            
    if row:
        if row.get("image_urls") and len(row["image_urls"]) > 0:
            row["image_url"] = row["image_urls"][0]
        else:
            row["image_url"] = None
    return row