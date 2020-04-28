import pandas as pd
import pytest
from import_csv import *


@pytest.fixture
def db(): 
    import psycopg2
    import psycopg2.extras

    with open("people.sql") as f:
        SQL = f.read()
    conn = psycopg2.connect("dbname=selfware user=selfware")
    conn.autocommit = True
    DB = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    DB.execute(SQL)
    yield DB
    print("teardown")
    DB.execute(SQL) 

def test_df_import(db):
    input_df = pd.DataFrame({
        'name': ['Arf', 'John Smith'],
        'email': ['test@arf.com', 'smith@test.com'] 
    })
    
    df_import(input_df, db)

    db.execute("SELECT status, js FROM rowland.contacts_get();")
    res = db.fetchall()
    assert res[0]['status'] == 200 
    assert res[0]['js'][2]['name'] == 'Arf'
    assert res[0]['js'][3]['name'] == 'John Smith'
