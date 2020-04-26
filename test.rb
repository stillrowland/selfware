require 'pg'
require 'minitest/autorun'

DB = PG::Connection.new(dbname: 'selfware', user:'selfware')
SQL = File.read('people.sql')

class Minitest::Test
	def setup
		DB.exec(SQL)
	end
end
Minitest.after_run do
	DB.exec(SQL)
end

class SqlTest < Minitest::Test
	def test_non_unique_primary_insert
		assert_raises(PG::UniqueViolation) {DB.exec("INSERT INTO contacts.email_address(person_id, email, primary_email) values (1, 'test@email.com', True);")}
	end

	def test_unique_primary_insert
		DB.exec("INSERT INTO rowland.email_address(person_id, email, primary_email) values (2, 'test@email.com', True);")
		res = DB.exec("SELECT * FROM rowland.email_address WHERE email = 'test@email.com';")
		assert_equal(res[0]['email'], "test@email.com")
	end

	def test_non_unique_non_primary_insert
		DB.exec("INSERT INTO rowland.email_address(person_id, email) values (1, 'test@email.com');")
		res = DB.exec("SELECT * FROM rowland.email_address WHERE email = 'test@email.com';")
	        assert_equal(res[0]['email'], "test@email.com")	
	end

	def test_new_primary
		DB.exec("UPDATE rowland.email_address SET primary_email = False WHERE email = 'rowland@stillclever.com';")
		DB.exec("UPDATE rowland.email_address SET primary_email = True WHERE email = 'test@gmail.com';")
		res = DB.exec("SELECT * FROM rowland.email_address WHERE email = 'test@gmail.com';")
		assert_equal(res[0]['primary_email'], 't')
		res = DB.exec("SELECT * FROM rowland.email_address WHERE email = 'rowland@stillclever.com';")
		assert_equal(res[0]['primary_email'], 'f')
	end

	def test_new_primary_single_query
		DB.exec("UPDATE rowland.email_address AS e SET primary_email = c.primary_email FROM (values ('rowland@stillclever.com', False), ('test@gmail.com', True)) as c(email, primary_email) WHERE c.email = e.email;")
		res = DB.exec("SELECT * FROM rowland.email_address WHERE email = 'test@gmail.com';")
		assert_equal(res[0]['primary_email'], 't')
		res = DB.exec("SELECT * FROM rowland.email_address WHERE email = 'rowland@stillclever.com';")
		assert_equal(res[0]['primary_email'], 'f')
	end

end
