# app/routers/articles.py
# Este módulo define los endpoints relacionados con el catálogo de artículos de la tienda virtual.

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

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