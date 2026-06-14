# Backend/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from Backend.app.core.config import settings
from Backend.app.routers import auth, articles, orders, categories

# Inicialización de la aplicación FastAPI usando la configuración centralizada
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.PROJECT_VERSION,
    description="Backend escalable para E-commerce conectado a Supabase con PostgreSQL"
)

# ==============================================================================
# CONFIGURACIÓN DE CORS (Cross-Origin Resource Sharing)
# ==============================================================================
# IMPORTANTE: Permitir "*" es ideal para desarrollo local con Flutter (Web y Emuladores).
# Si en el futuro pasas a producción, puedes restringirlo a las IPs de tus clientes.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==============================================================================
# INCLUSIÓN DE ROUTERS MODULARES
# ==============================================================================
# Cada router maneja su propio prefijo (Ej: /auth, /articles, /orders, /categories)
app.include_router(auth.router)
app.include_router(articles.router)
app.include_router(orders.router)
app.include_router(categories.router)


# ==============================================================================
# ENDPOINT DE CONTROL DE SALUD (Health Check)
# ==============================================================================
@app.get("/", tags=["General"])
def health_check():
    """
    Endpoint público para verificar que la API está en línea y 
    revisar la versión actual del despliegue.
    """
    return {
        "status": "API Operativa", 
        "version": settings.PROJECT_VERSION,
        "database": "Conectado a Supabase (PostgreSQL)"
    }