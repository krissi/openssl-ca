require "test/unit"
require "ca/database"
require File.absolute_path(File.join(File.dirname(__FILE__), 'keys.rb'))

class TestCaSerial < Test::Unit::TestCase
	def test_ca_database
		database = CA::Database.new CA_CERT, CA_KEY, Sequel.sqlite
		assert_equal database.class, CA::Database
		assert database.init_ca!

		assert_equal database.include_valid_cert?(CERT), false
		assert database.<<(CERT)
		assert_equal database.include_valid_cert?(CERT), true
		assert_equal database[:dn => CERT.subject.to_s][:status], "V"
		assert_equal database[:dn => CERT.subject.to_s][:serial], CERT.serial
		assert_equal database[:dn => CERT.subject.to_s][:not_after], CERT.not_after
		assert_equal database[:dn => CERT.subject.to_s][:revoked_at], nil
		assert_equal database[:dn => CERT.subject.to_s][:location], nil
		assert_equal database[:dn => CERT.subject.to_s][:dn], CERT.subject.to_s
	end

	def test_ca_database_revoke
		database = CA::Database.new CA_CERT, CA_KEY, Sequel.sqlite
		database.init_ca!

		cert = CERT
		cert = cert.sign(CA_KEY, OpenSSL::Digest::SHA1.new)

		assert database.<<(cert)
		assert database.revoke! CERT.subject.to_s
	end

	def test_ca_database_crl
		database = CA::Database.new CA_CERT, CA_KEY, Sequel.sqlite
		database.init_ca!

		assert database.crl.to_s
		assert_equal database.crl.verify(CA_CERT.public_key), true
	end
end
