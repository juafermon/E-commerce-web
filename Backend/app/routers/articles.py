# app/routers/articles.py
# Este módulo define los endpoints relacionados con el catálogo de artículos de la tienda virtual.

# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from typing import List
import uuid
import re
from Backend.app.core.config import settings
from supabase import create_client, Client

from Backend.app.database import get_db
from Backend.app import schemas
from Backend.app.crud import crud_article
from Backend.app.routers.auth import get_current_user # Importamos el validador de tokens

router = APIRouter(
    prefix="/articles",
    tags=["Catálogo de Artículos"]
)

@router.get("/", response_model=List[schemas.Article])
def list_articles(skip: int = 0, limit: int = 100, db = Depends(get_db)):
    """
    Endpoint Público.
    Cualquier cliente (registrado o no) puede ver la lista de artículos de la tienda.
    """
    return crud_article.get_articles(db, skip=skip, limit=limit)


@router.get("/{article_id}", response_model=schemas.Article)
def get_article(article_id: int, db = Depends(get_db)):
    """
    Endpoint Público.
    Obtiene los detalles (incluyendo stock actual) de un artículo específico por su ID.
    """
    db_article = crud_article.get_article_by_id(db, article_id=article_id)
    if not db_article:
        raise HTTPException(status_code=404, detail="El artículo solicitado no existe.")
    return db_article



@router.post("/", response_model=schemas.Article, status_code=status.HTTP_201_CREATED)
def add_article(
    article: schemas.ArticleCreate, 
    db = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    """
    Endpoint Protegido.
    Solo los usuarios con rol 'admin' pueden agregar nuevos productos al catálogo.
    """
    # Verificación estricta de rol
    if current_user["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permisos de administrador para modificar el catálogo."
        )
    
    return crud_article.create_article(db, article=article)

# app/routers/articles.py (Añadir al final)

@router.put("/{article_id}", response_model=schemas.Article)
def edit_article(
    article_id: int, 
    article_update: schemas.ArticleCreate, 
    db = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    """
    Endpoint Protegido.
    Permite a un administrador modificar los detalles o stock de un artículo específico.
    """
    if current_user["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Permisos insuficientes para editar productos."
        )
    
    # Verificar si el artículo existe antes de actualizar
    db_article = crud_article.get_article_by_id(db, article_id=article_id)
    if not db_article:
        raise HTTPException(status_code=404, detail="El artículo solicitado no existe.")
        
    return crud_article.update_article(db, article_id=article_id, article_data=article_update)


@router.post("/upload-images", response_model=List[str])
def upload_images(
    files: List[UploadFile] = File(...),
    current_user = Depends(get_current_user)
):
    """
    Endpoint Protegido.
    Permite subir entre 2 y 8 imágenes a Supabase Storage bucket 'images'.
    """
    if current_user["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permisos de administrador para subir imágenes."
        )

    if len(files) < 2 or len(files) > 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Se deben subir entre 2 y 8 imágenes por artículo."
        )

    if not settings.SUPABASE_KEY or not settings.SUPABASE_URL:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="La configuración de Supabase Storage no está definida en el servidor."
        )

    # Crear cliente Supabase una sola vez (maneja las claves sb_ correctamente)
    try:
        supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    except Exception as ex:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"No se pudo conectar con Supabase: {str(ex)}"
        )

    urls = []
    
    for file in files:
        if not file.content_type.startswith("image/"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"El archivo {file.filename} no es una imagen válida."
            )

        # Sanitize user filename to keep it safe for URL paths
        clean_name = re.sub(r'[^a-zA-Z0-9_.-]', '_', file.filename)
        # Generate a unique filename using a UUID prefix to prevent duplicate name collisions
        unique_filename = f"{uuid.uuid4()}_{clean_name}"
        
        # Read the file content
        file_content = file.file.read()
        
        try:
            supabase.storage.from_(settings.SUPABASE_BUCKET).upload(
                path=unique_filename,
                file=file_content,
                file_options={"content-type": file.content_type, "upsert": "false"}
            )
        except Exception as ex:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error de conexión con Supabase Storage: {str(ex)}"
            )
            
        public_url = f"{settings.SUPABASE_URL}/storage/v1/object/public/{settings.SUPABASE_BUCKET}/{unique_filename}"
        urls.append(public_url)
        
    return urls