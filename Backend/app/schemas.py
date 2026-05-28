# app/schemas.py
# Este módulo define los esquemas de datos (Pydantic models) que se utilizan para validar y estructurar la información que entra y sale de la API.
# Incluye esquemas para usuarios, autenticación, artículos, pedidos y categorías.
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# --- SCHEMAS DE AUTENTICACIÓN ---

class UserBase(BaseModel):
    username: str = Field(..., description="Nombre de usuario único para la tienda")

class UserCreate(UserBase):
    password: str = Field(..., min_length=6, description="Contraseña de acceso")

class User(UserBase):
    id: int
    role: str
    is_active: bool

    class Config:
        from_attributes = True  # Permite mapear los diccionarios de psycopg2 de forma nativa

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None
    role: Optional[str] = None


# --- SCHEMAS DEL CATÁLOGO DE ARTÍCULOS ---

class ArticleBase(BaseModel):
    name: str
    description: Optional[str] = None
    price: float = Field(..., gt=0, description="El precio debe ser mayor a cero")
    stock: int = Field(..., ge=0, description="El inventario no puede ser negativo")
    category: Optional[str] = None
    image_url: Optional[str] = None

class ArticleCreate(ArticleBase):
    pass  # Se usa para recibir datos cuando subes un artículo nuevo

class Article(ArticleBase):
    id: int
    is_available: bool

    class Config:
        from_attributes = True
        
# --- SCHEMAS DE PEDIDOS y carrito ---
# Representa un artículo dentro del carrito de compras
class OrderItemCreate(BaseModel):
    article_id: int
    quantity: int = Field(..., gt=0, description="La cantidad debe ser mayor a 0")
    
# Lo que envía Flutter para crear un pedido
class OrderCreate(BaseModel):
    shipping_address: str
    items: List[OrderItemCreate]

# Representa el detalle que se le devuelve al usuario
class OrderItemResponse(BaseModel):
    article_id: int
    quantity: int
    price_at_purchase: float

    class Config:
        from_attributes = True

# Representa la orden completa que se devuelve al usuario
class OrderResponse(BaseModel):
    id: int
    user_id: int
    total_price: float
    status: str
    shipping_address: str
    created_at: datetime
    items: List[OrderItemResponse] = []

    class Config:
        from_attributes = True
        
class OrderStatusUpdate(BaseModel):
    status: str = Field(..., description="Estados válidos: pending, paid, shipped, delivered, cancelled")
    
class CategoryOut(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True  # Permite mapear los datos directamente desde la base de datos