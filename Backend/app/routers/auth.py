# app/routers/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from datetime import timedelta
from jose import JWTError, jwt
from Backend.app.core.config import settings

# Importaciones de nuestro propio proyecto
from Backend.app.database import get_db
from Backend.app.core import security
from Backend.app import schemas
from Backend.app.crud import crud_user

router = APIRouter(
    prefix="/auth",
    tags=["Autenticación"]
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

@router.post("/register", response_model=schemas.User, status_code=status.HTTP_201_CREATED)
def register_client(user: schemas.UserCreate, db = Depends(get_db)):
    """
    Registro público de clientes.
    Cualquier usuario puede registrarse libremente sin necesidad de tokens.
    """
    # 1. Verificar si el usuario ya existe
    db_user = crud_user.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El nombre de usuario ya está registrado en la tienda."
        )
    
    # 2. Generar hash de la contraseña de forma segura
    hashed_pwd = security.get_password_hash(user.password)
    
    # 3. Guardar en Supabase utilizando la capa CRUD
    return crud_user.create_user(db, user=user, hashed_password=hashed_pwd)


@router.post("/login", response_model=schemas.Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db = Depends(get_db)):
    """
    Inicio de sesión estándar compatible con OAuth2.
    Devuelve el Token JWT que Flutter debe almacenar.
    """
    # 1. Buscar el usuario en la base de datos
    user = crud_user.get_user_by_username(db, username=form_data.username)
    
    # 2. Validar existencia y contraseña
    if not user or not security.verify_password(form_data.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nombre de usuario o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 3. Verificar si la cuenta no está suspendida
    if not user["is_active"]:
        raise HTTPException(status_code=400, detail="Usuario inactivo o suspendido.")

    # 4. Generar el token inyectando el rol del usuario como metadata (claim)
    token_data = {"sub": user["username"], "role": user["role"]}
    access_token = security.create_access_token(data=token_data)
    
    return {"access_token": access_token, "token_type": "bearer"}

def get_current_user(token: str = Depends(oauth2_scheme), db = Depends(get_db)):
    """Valida el token JWT y retorna los datos del usuario actual desde Supabase"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudieron validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
        username: str = payload.get("sub")
        role: str = payload.get("role")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
        
    # Buscamos el usuario en la base de datos para asegurar que sigue activo
    
    user = crud_user.get_user_by_username(db, username=username)
    if user is None:
        raise credentials_exception
    return user