# app/crud/crud_order.py
# Este módulo maneja la lógica de negocio relacionada con las órdenes de compra, incluyendo:
# - Creación de órdenes con validación de stock y cálculo de precios.
from fastapi import HTTPException, status
from Backend.app import schemas

def create_order_transaction(db, conn, order_data: schemas.OrderCreate, user_id: int):
    """
    Registra una orden completa, calcula precios, valida stock y descuenta inventario.
    Recibe el cursor (db) y la conexión (conn) para asegurar consistencia.
    """
    total_price = 0.0
    items_to_save = []

    # 1. Validar stock y calcular precios de cada artículo
    for item in order_data.items:
        db.execute("SELECT id, name, price, stock, is_available FROM ARTICLES WHERE id = %s FOR UPDATE;", (item.article_id,))
        article = db.fetchone()

        if not article or not article["is_available"]:
            raise HTTPException(status_code=404, detail=f"El artículo con ID {item.article_id} no está disponible.")
        
        if article["stock"] < item.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Stock insuficiente para '{article['name']}'. Disponibles: {article['stock']}, Solicitados: {item.quantity}"
            )

        item_total = float(article["price"]) * item.quantity
        total_price += item_total

        # Guardamos la info procesada temporalmente
        items_to_save.append({
            "article_id": item.article_id,
            "quantity": item.quantity,
            "price_at_purchase": float(article["price"]),
            "new_stock": article["stock"] - item.quantity
        })

    # 2. Insertar la cabecera de la Orden (ORDERS)
    query_order = """
        INSERT INTO ORDERS (user_id, total_price, status, shipping_address)
        VALUES (%s, %s, %s, %s)
        RETURNING id, user_id, total_price, status, shipping_address, created_at;
    """
    db.execute(query_order, (user_id, total_price, "pending", order_data.shipping_address))
    new_order = db.fetchone()

    # 3. Insertar los detalles (ORDER_ITEMS) y actualizar stock (ARTICLES)
    query_item = """
        INSERT INTO ORDER_ITEMS (order_id, article_id, quantity, price_at_purchase)
        VALUES (%s, %s, %s, %s);
    """
    query_update_stock = "UPDATE ARTICLES SET stock = %s WHERE id = %s;"

    for item in items_to_save:
        # Insertar detalle
        db.execute(query_item, (new_order["id"], item["article_id"], item["quantity"], item["price_at_purchase"]))
        # Descontar inventario
        db.execute(query_update_stock, (item["new_stock"], item["article_id"]))

    # Adjuntar los ítems al diccionario de respuesta
    new_order["items"] = items_to_save
    return new_order

def get_user_orders(db, user_id: int):
    """Obtiene el historial de compras de un cliente específico"""
    query = "SELECT * FROM ORDERS WHERE user_id = %s ORDER BY created_at DESC;"
    db.execute(query, (user_id,))
    orders = db.fetchall()

    for order in orders:
        db.execute("SELECT article_id, quantity, price_at_purchase FROM ORDER_ITEMS WHERE order_id = %s;", (order["id"],))
        order["items"] = db.fetchall()
    
    return orders

def update_order_status(db, order_id: int, new_status: str):
    """Modifica el estado logístico de un pedido en Supabase"""
    query = """
        UPDATE ORDERS 
        SET status = %s 
        WHERE id = %s
        RETURNING id, user_id, total_price, status, shipping_address, created_at;
    """
    db.execute(query, (new_status, order_id))
    order = db.fetchone()
    
    if order:
        # Volvemos a adjuntar los ítems para cumplir con el esquema de respuesta
        db.execute("SELECT article_id, quantity, price_at_purchase FROM ORDER_ITEMS WHERE order_id = %s;", (order["id"],))
        order["items"] = db.fetchall()
        
    return order