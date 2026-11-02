# Backend/scripts/create_wishlist_migration.py
# Script de migración para crear la tabla de wishlist (lista de deseos) en PostgreSQL/Supabase.
# Ejecutar una sola vez: python -m Backend.scripts.create_wishlist_migration

import sys
import os

# Asegurar que el directorio raíz del proyecto esté en el path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from Backend.app.database import get_db_connection

def run_migration():
    print("Iniciando migración de Wishlist en PostgreSQL/Supabase...")

    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # 1. Crear tabla wishlists
            create_wishlist_table_sql = """
            CREATE TABLE IF NOT EXISTS wishlists (
                id SERIAL PRIMARY KEY,
                user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                article_id INT NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
                added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                CONSTRAINT unique_user_article_wishlist UNIQUE (user_id, article_id)
            );
            """
            cur.execute(create_wishlist_table_sql)
            print("[OK] Tabla 'wishlists' creada o verificada exitosamente.")

            # 2. Índice en user_id para búsquedas rápidas por usuario
            cur.execute(
                "CREATE INDEX IF NOT EXISTS idx_wishlists_user_id ON wishlists(user_id);"
            )
            print("[OK] Índice en 'user_id' creado o verificado.")

            # 3. Índice en article_id para consultas inversas (¿quién guardó este artículo?)
            cur.execute(
                "CREATE INDEX IF NOT EXISTS idx_wishlists_article_id ON wishlists(article_id);"
            )
            print("[OK] Índice en 'article_id' creado o verificado.")

    print("\nMigración de Wishlist completada con éxito.")
    print("Recuerda reiniciar el servidor FastAPI para activar los nuevos endpoints.")

if __name__ == "__main__":
    run_migration()
