from Backend.app.database import get_db_connection

with get_db_connection() as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'articles';")
        rows = cur.fetchall()
        print("Columns in articles:")
        for r in rows:
            print(f" - {r[0]}: {r[1]}")
