# app/schemas.py
# Este módulo define los esquemas de datos (Pydantic models) que se utilizan para validar y estructurar la información que entra y sale de la API.
# Incluye esquemas para usuarios, autenticación, artículos, pedidos y categorías.
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# --- SCHEMAS DE AUTENTICACIÓN ---
class UserBase(BaseModel):
    username: str = Field(..., max_length=15, description="Nombre de usuario único para la tienda")
    email: str = Field(..., max_length=30, description="Correo electrónico del usuario")
    address: str = Field(..., max_length=100, description="Dirección de envío/residencia")
    id_type: str = Field(..., description="Tipo de documento: CC, CE, NIT, Pasaporte")
    doc_number: str = Field(..., max_length=15, description="Número de identificación (Solo dígitos)")

class UserCreate(UserBase):
    password: str = Field(..., min_length=6, max_length=20, description="Contraseña de acceso")

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
    original_price: Optional[float] = Field(None, gt=0, description="Precio anterior/original antes del descuento")
    stock: int = Field(..., ge=0, description="El inventario no puede ser negativo")
    category: Optional[str] = None
    image_urls: List[str] = []
    image_url: Optional[str] = None
    is_available: bool = True

class ArticleCreate(ArticleBase):
    pass  # Se usa para recibir datos cuando subes un artículo nuevo o lo editas

class Article(ArticleBase):
    id: int
    rating_avg: float = 0.0
    rating_count: int = 0

    class Config:
        from_attributes = True

# --- SCHEMAS DE CALIFICACIONES Y RESEÑAS ---

class RatingCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5, description="Puntuación de 1 a 5 estrellas")
    comment: Optional[str] = Field(None, max_length=500, description="Comentario u opinión sobre el producto")

class RatingResponse(BaseModel):
    id: int
    article_id: int
    user_id: int
    username: str
    rating: int
    comment: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# --- SCHEMAS DE WISHLIST (LISTA DE DESEOS) ---

class WishlistItemResponse(BaseModel):
    """Representa un artículo guardado en la wishlist con los datos completos del producto."""
    wishlist_id: int
    user_id: int
    article_id: int
    added_at: datetime
    # Datos del artículo
    name: str
    description: Optional[str] = None
    price: float
    stock: int
    category: Optional[str] = None
    image_url: Optional[str] = None
    image_urls: List[str] = []
    is_available: bool
    rating_avg: float = 0.0
    rating_count: int = 0

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