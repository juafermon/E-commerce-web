from Backend.app.database import get_db_connection

with get_db_connection() as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT id, name, public FROM storage.buckets;")
        print("Buckets:")
        for b in cur.fetchall():
            print(" ", b)
        
        cur.execute("""
            SELECT policyname, permissive, roles, cmd, qual, with_check 
            FROM pg_policies 
            WHERE schemaname = 'storage' AND tablename = 'objects';
        """)
        print("\nPolicies on storage.objects:")
        for pol in cur.fetchall():
            print(" ", pol)
