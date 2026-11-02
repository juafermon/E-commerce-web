# Backend/app/routers/ratings.py
# Endpoints para el sistema de calificaciones y reseñas de productos.

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from Backend.app.database import get_db
from Backend.app import schemas
from Backend.app.crud import crud_rating, crud_article
from Backend.app.routers.auth import get_current_user

router = APIRouter(
    prefix="/articles/{article_id}/ratings",
    tags=["Calificaciones y Reseñas"]
)

@router.get("/", response_model=List[schemas.RatingResponse])
def get_article_ratings(article_id: int, db = Depends(get_db)):
    """
    Ruta Pública.
    Obtiene la lista de todas las calificaciones y opiniones de un producto específico.
    """
    article = crud_article.get_article_by_id(db, article_id=article_id)
    if not article:
        raise HTTPException(status_code=404, detail="El artículo solicitado no existe.")
    return crud_rating.get_ratings_by_article(db, article_id=article_id)

@router.get("/my-rating", response_model=Optional[schemas.RatingResponse])
def get_my_rating(
    article_id: int, 
    db = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    """
    Ruta Protegida.
    Devuelve la calificación previa que el usuario autenticado otorgó a este artículo (o null si no ha calificado).
    """
    return crud_rating.get_user_rating(db, article_id=article_id, user_id=current_user["id"])

@router.post("/", response_model=schemas.RatingResponse, status_code=status.HTTP_201_CREATED)
def submit_rating(
    article_id: int,
    rating_data: schemas.RatingCreate,
    db = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Ruta Protegida.
    Crea o actualiza la calificación (1 a 5 estrellas) con comentario opcional del usuario autenticado.
    Recalcula de inmediato el rating promedio y total de calificaciones del artículo.
    """
    article = crud_article.get_article_by_id(db, article_id=article_id)
    if not article:
        raise HTTPException(status_code=404, detail="El artículo solicitado no existe.")
    
    return crud_rating.upsert_rating(
        db, 
        article_id=article_id, 
        user_id=current_user["id"], 
        rating_data=rating_data
    )
