# Backend/app/routers/categories.py
# Este archivo define el endpoint para obtener las categorías desde Supabase.

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from pydantic import BaseModel
from Backend.app.database import get_db 

# =======================================================
# ESQUEMA DE PYDANTIC (Mapeo del JSON de salida)
# =======================================================
class CategoryOut(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True


# =======================================================
# ENRUTADOR DE FASTAPI
# =======================================================
router = APIRouter(prefix="/categories", tags=["Categories"])


@router.get("/", response_model=List[CategoryOut], status_code=status.HTTP_200_OK)
def get_categories(cursor = Depends(get_db)):
    """
    Endpoint que consulta todas las categorías en Supabase 
    utilizando el cursor inyectado por psycopg2.
    """
    try:
        # 1. Ejecutamos la consulta SQL pura para obtener las categorías ordenadas alfabéticamente
        query = "SELECT id, name FROM categories ORDER BY name ASC;"
        cursor.execute(query)
        
        # 2. Obtenemos los resultados. Gracias a 'from_attributes=True' en el modelo, podemos mapear directamente los diccionarios de psycopg2 a nuestros esquemas Pydantic.
        categories = cursor.fetchall()
        
        return categories

    except Exception as e:
        # Si algo falla en la consulta SQL o en la red, disparamos un error 500
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error en la base de datos al leer categorías: {str(e)}"
        )