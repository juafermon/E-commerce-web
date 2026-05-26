# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from Backend.app.core.config import settings
from Backend.app.routers import auth, articles, orders

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.PROJECT_VERSION,
    description="Backend escalable para E-commerce conectado a Supabase"
)

# Configuración de CORS para permitir conexiones desde Flutter (móvil o web)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclusión de Routers Modulares
app.include_router(auth.router)
app.include_router(articles.router)
app.include_router(orders.router)

@app.get("/", tags=["General"])
def health_check():
    return {"status": "API Operativa", "version": settings.PROJECT_VERSION}
