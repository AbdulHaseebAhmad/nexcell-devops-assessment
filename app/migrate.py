import os

import psycopg

with psycopg.connect(os.environ["DATABASE_URL"]) as c:
    c.execute("CREATE TABLE IF NOT EXISTS tenants (id serial PRIMARY KEY, name text)")
print("migrations applied", flush=True)
