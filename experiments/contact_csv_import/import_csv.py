import psycopg2
import psycopg2.extras
import pandas as pd


with open("people.sql") as f:
    SQL = f.read()
conn = psycopg2.connect("dbname=selfware user=selfware")
conn.autocommit = True
DB = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
DB.execute(SQL)

def df_import(df, db):
    for index, row in df.iterrows():
        db.execute("SELECT status, js FROM rowland.contact_add(%s,%s);", [row['name'], row['email']]) 
