# Backend/app/routers/wishlist.py
# Endpoints REST para el sistema de Wishlist (Lista de Deseos) de la tienda.
# Todos los endpoints son protegidos y requieren autenticación JWT.

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from Backend.app.database import get_db
from Backend.app import schemas
from Backend.app.crud import crud_wishlist, crud_article
from Backend.app.routers.auth import get_current_user

router = APIRouter(
    prefix="/wishlist",
    tags=["Lista de Deseos (Wishlist)"]
)


@router.get("/", response_model=List[schemas.WishlistItemResponse])
def get_my_wishlist(
    db=Depends(get_db),
    current_user=Depends(get_current_user)
):
    """
    Ruta Protegida.
    Devuelve todos los artículos guardados en la wishlist del usuario autenticado,
    con los datos actualizados de cada producto.
    """
    return crud_wishlist.get_wishlist_by_user(db, user_id=current_user["id"])


@router.get("/{article_id}/status")
def check_wishlist_status(
    article_id: int,
    db=Depends(get_db),
    current_user=Depends(get_current_user)
):
    """
    Ruta Protegida.
    Verifica si un artículo específico ya está en la wishlist del usuario.
    Retorna { "is_in_wishlist": true/false }.
    """
    item = crud_wishlist.get_wishlist_item(db, user_id=current_user["id"], article_id=article_id)
    return {"is_in_wishlist": item is not None}


@router.post("/{article_id}", status_code=status.HTTP_201_CREATED)
def add_to_wishlist(
    article_id: int,
    db=Depends(get_db),
    current_user=Depends(get_current_user)
):
    """
    Ruta Protegida.
    Agrega un artículo a la wishlist del usuario autenticado.
    Si el artículo ya estaba, retorna el elemento existente sin error (idempotente).
    """
    # Verificar que el artículo exista en el catálogo
    article = crud_article.get_article_by_id(db, article_id=article_id)
    if not article:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="El artículo solicitado no existe en el catálogo."
        )

    item = crud_wishlist.add_to_wishlist(db, user_id=current_user["id"], article_id=article_id)
    return {"message": "Artículo añadido a tu lista de deseos.", "wishlist_item": item}


@router.delete("/{article_id}", status_code=status.HTTP_200_OK)
def remove_from_wishlist(
    article_id: int,
    db=Depends(get_db),
    current_user=Depends(get_current_user)
):
    """
    Ruta Protegida.
    Elimina un artículo de la wishlist del usuario autenticado.
    Si el artículo no estaba, retorna un error 404.
    """
    removed = crud_wishlist.remove_from_wishlist(db, user_id=current_user["id"], article_id=article_id)
    if not removed:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Este artículo no se encuentra en tu lista de deseos."
        )
    return {"message": "Artículo eliminado de tu lista de deseos."}
