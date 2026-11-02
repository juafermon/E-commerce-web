# Backend/scripts/create_ratings_migration.py
# Script de migración para crear la tabla de calificaciones y agregar las columnas de resumen en artículos.

import sys
import os

# Asegurar que el directorio raíz del proyecto esté en el path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from Backend.app.database import get_db_connection

def run_migration():
    print("Iniciando migración de calificaciones en PostgreSQL/Supabase...")
    
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # 1. Crear tabla product_ratings
            create_ratings_table_sql = """
            CREATE TABLE IF NOT EXISTS product_ratings (
                id SERIAL PRIMARY KEY,
                article_id INT NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
                user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
                comment TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                CONSTRAINT unique_user_article_rating UNIQUE (article_id, user_id)
            );
            """
            cur.execute(create_ratings_table_sql)
            print("[OK] Tabla 'product_ratings' creada o verificada exitosamente.")

            # 2. Agregar columnas rating_avg y rating_count a articles si no existen
            add_columns_sql = """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'articles' AND column_name = 'rating_avg'
                ) THEN
                    ALTER TABLE articles ADD COLUMN rating_avg NUMERIC(3,1) DEFAULT 0.0;
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'articles' AND column_name = 'rating_count'
                ) THEN
                    ALTER TABLE articles ADD COLUMN rating_count INT DEFAULT 0;
                END IF;
            END $$;
            """
            cur.execute(add_columns_sql)
            print("[OK] Columnas 'rating_avg' y 'rating_count' agregadas a 'articles'.")

            # 3. Crear índice para optimizar consultas de calificaciones por artículo
            cur.execute("CREATE INDEX IF NOT EXISTS idx_product_ratings_article_id ON product_ratings(article_id);")
            print("[OK] Indice en 'article_id' creado o verificado.")

    print("Migración completada con éxito.")

if __name__ == "__main__":
    run_migration()
