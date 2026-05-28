# app/routers/orders.py
# Este archivo define los endpoints relacionados con las órdenes y pedidos, incluyendo la creación de pedidos a partir del carrito, la consulta del historial de compras y la actualización del estado de las órdenes.
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

from Backend.app.database import get_db, get_db_connection
from Backend.app import schemas
from Backend.app.crud import crud_order
from Backend.app.routers.auth import get_current_user

router = APIRouter(
    prefix="/orders",
    tags=["Órdenes y Pedidos"]
)

@router.post("/", response_model=schemas.OrderResponse, status_code=status.HTTP_201_CREATED)
def checkout_cart(order_data: schemas.OrderCreate, current_user = Depends(get_current_user)):
    """
    Crea un nuevo pedido a partir de los artículos del carrito.
    Protegido: Requiere Token del cliente.
    """
    # Al requerir lógica transaccional estricta, abrimos la conexión directa aquí
    with get_db_connection() as conn:
        from psycopg2.extras import RealDictCursor
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            order = crud_order.create_order_transaction(cursor, conn, order_data, current_user["id"])
            conn.commit() # Si todo sale bien, guarda todos los cambios a la vez
            return order
        except HTTPException as he:
            conn.rollback()
            raise he
        except Exception as e:
            conn.rollback()
            raise HTTPException(status_code=500, detail=f"Error al procesar la orden: {str(e)}")
        finally:
            cursor.close()

@router.get("/", response_model=List[schemas.OrderResponse])
def my_orders(current_user = Depends(get_current_user), db = Depends(get_db)):
    """
    Devuelve el historial de compras del cliente autenticado.
    """
    return crud_order.get_user_orders(db, user_id=current_user["id"])


@router.patch("/{order_id}/status", response_model=schemas.OrderResponse)
def change_order_status(
    order_id: int, 
    status_data: schemas.OrderStatusUpdate, 
    db = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    """
    Endpoint Protegido.
    Permite al administrador cambiar el estado del pedido (Ej: de 'pending' a 'shipped').
    """
    if current_user["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo los administradores pueden cambiar el estado de las órdenes."
        )
    
    # Validar el string del estado antes de enviarlo a la base de datos
    valid_statuses = ["pending", "paid", "shipped", "delivered", "cancelled"]
    if status_data.status not in valid_statuses:
        raise HTTPException(
            status_code=400, 
            detail=f"Estado inválido. Los estados permitidos son: {', '.join(valid_statuses)}"
        )
        
    updated_order = crud_order.update_order_status(db, order_id=order_id, new_status=status_data.status)
    if not updated_order:
        raise HTTPException(status_code=404, detail="La orden solicitada no existe.")
        
    return updated_order