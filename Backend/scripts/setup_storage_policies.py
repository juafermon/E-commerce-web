from Backend.app.database import get_db_connection

def setup_storage_policies():
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # Enable RLS if not already enabled
            cur.execute("ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;")
            
            # Create policies for images bucket
            policies = [
                (
                    "images_bucket_select",
                    """
                    CREATE POLICY "images_bucket_select" ON storage.objects
                    FOR SELECT TO public
                    USING (bucket_id = 'images');
                    """
                ),
                (
                    "images_bucket_insert",
                    """
                    CREATE POLICY "images_bucket_insert" ON storage.objects
                    FOR INSERT TO public
                    WITH CHECK (bucket_id = 'images');
                    """
                ),
                (
                    "images_bucket_update",
                    """
                    CREATE POLICY "images_bucket_update" ON storage.objects
                    FOR UPDATE TO public
                    USING (bucket_id = 'images')
                    WITH CHECK (bucket_id = 'images');
                    """
                ),
                (
                    "images_bucket_delete",
                    """
                    CREATE POLICY "images_bucket_delete" ON storage.objects
                    FOR DELETE TO public
                    USING (bucket_id = 'images');
                    """
                ),
            ]
            
            for name, sql in policies:
                cur.execute(f"DROP POLICY IF EXISTS {name} ON storage.objects;")
                cur.execute(sql)
                print(f"[OK] Policy '{name}' created.")
                
    print("Storage policies successfully configured.")

if __name__ == "__main__":
    setup_storage_policies()
