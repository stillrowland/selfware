import psycopg2
import psycopg2.extras
import pandas as pd
from optparse import OptionParser


with open("people.sql") as f:
    SQL = f.read()
conn = psycopg2.connect("dbname=selfware user=selfware")
conn.autocommit = True
DB = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
DB.execute(SQL)

def df_import(df, db):
    for index, row in df.iterrows():
        db.execute("SELECT status, js FROM rowland.contact_add(%s,%s);", [row['name'], row['email']]) 

def csv_to_db(csv_file, db):
    df = pd.read_csv(csv_file)
    df_import(df, db)

if __name__ == "__main__":
    parser = OptionParser()
    (options, args) = parser.parse_args()
    print(args[0])
