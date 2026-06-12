# 🛒 Mi Tienda Virtual — E-commerce Web

Aplicación de tienda virtual con **backend en FastAPI** y **frontend en Flutter Web**. Permite gestionar usuarios, productos (artículos), categorías y órdenes, con autenticación JWT almacenada de forma segura en el cliente.

---

## 📐 Arquitectura

```
E-commerce-web/
├── Backend/               # API REST con FastAPI + Supabase (PostgreSQL)
│   └── app/
│       ├── core/          # Configuración y seguridad (JWT, settings)
│       ├── crud/          # Operaciones de base de datos
│       ├── routers/       # Endpoints: auth, articles, categories, orders
│       ├── schemas.py     # Modelos Pydantic (request/response)
│       ├── database.py    # Conexión a Supabase/PostgreSQL
│       └── main.py        # Punto de entrada de la API
│
└── frontend/              # Aplicación Flutter Web
    └── lib/
        ├── data/
        │   └── services/  # Servicios HTTP (AuthService, etc.)
        ├── ui/
        │   ├── screens/   # Pantallas (login, catálogo, etc.)
        │   └── widgets/   # Componentes reutilizables
        └── main.dart      # Punto de entrada Flutter
```

---

## 🧰 Stack Tecnológico

| Capa       | Tecnología                                      |
|------------|-------------------------------------------------|
| Backend    | Python · FastAPI · Uvicorn                      |
| Base de datos | Supabase (PostgreSQL)                        |
| Autenticación | JWT (`python-jose`) · `bcrypt` / `passlib`  |
| Frontend   | Flutter Web (Dart 3)                            |
| HTTP Client | `dio` ^5.9.2                                  |
| Almacenamiento seguro | `flutter_secure_storage` ^10.3.0  |

---

## ⚙️ Requisitos Previos

- **Python** 3.10+
- **Flutter** SDK 3.x (`dart sdk ^3.12.0`)
- **pip** para instalar dependencias de Python
- Cuenta en **[Supabase](https://supabase.com)** con una base de datos configurada
- Variables de entorno configuradas en `.env` (ver sección siguiente)

---

## 🔐 Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:

```env
DATABASE_URL=postgresql://usuario:password@host:5432/nombre_db
SECRET_KEY=tu_clave_secreta_jwt
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
PROJECT_NAME=Mi Tienda Virtual
PROJECT_VERSION=1.0.0
```

---

## 🚀 Instalación y Ejecución

### 1. Backend (FastAPI)

```bash
# Instalar dependencias
pip install fastapi "uvicorn[standard]" psycopg2-binary "python-jose[cryptography]" bcrypt passlib python-dotenv python-multipart

# Iniciar el servidor de desarrollo
uvicorn Backend.app.main:app --reload
```

La API estará disponible en: `http://127.0.0.1:8000`  
Documentación interactiva (Swagger): `http://127.0.0.1:8000/docs`

---

### 2. Frontend (Flutter Web)

Abrir una **nueva terminal** y ejecutar:

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## 📡 Endpoints de la API

| Método | Ruta               | Descripción                          | Auth requerida |
|--------|--------------------|--------------------------------------|----------------|
| `GET`  | `/`                | Health check de la API               | No             |
| `POST` | `/auth/login`      | Iniciar sesión, devuelve JWT         | No             |
| `POST` | `/auth/register`   | Registrar nuevo usuario              | No             |
| `GET`  | `/articles/`       | Listar artículos del catálogo        | Sí             |
| `POST` | `/articles/`       | Crear nuevo artículo                 | Sí             |
| `GET`  | `/categories/`     | Listar categorías                    | Sí             |
| `GET`  | `/orders/`         | Listar órdenes del usuario           | Sí             |
| `POST` | `/orders/`         | Crear una nueva orden                | Sí             |

---

## 📦 Dependencias Flutter (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  dio: ^5.9.2                        # Cliente HTTP
  flutter_secure_storage: ^10.3.0   # Almacenamiento seguro del JWT
```

---

## 🤝 Contribuciones

1. Haz un fork del repositorio
2. Crea una rama: `git checkout -b feature/nueva-funcionalidad`
3. Haz commit de tus cambios: `git commit -m "feat: descripción"`
4. Abre un Pull Request

---

## 📄 Licencia

Este proyecto es de uso privado / educativo.