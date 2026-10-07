import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from Backend.app.database import get_db_connection

def run_migration():
    print("Iniciando migración de original_price en PostgreSQL/Supabase...")
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            add_column_sql = """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'articles' AND column_name = 'original_price'
                ) THEN
                    ALTER TABLE articles ADD COLUMN original_price NUMERIC DEFAULT NULL;
                END IF;
            END $$;
            """
            cur.execute(add_column_sql)
            print("[OK] Columna 'original_price' agregada o verificada en 'articles'.")
    print("Migración completada con éxito.")

if __name__ == "__main__":
    run_migration()
