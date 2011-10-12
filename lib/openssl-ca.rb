require 'openssl'
require 'sequel'
require 'openssl-ca/serial'
require 'openssl-ca/database'

class OpenSSLCA
	def initialize(cert, key, database_url)
		raise "OpenSSLCA.new takes OpenSSL::X509::Certificate as first argument. Given: #{cert.inspect}" unless cert.is_a? OpenSSL::X509::Certificate
		raise "OpenSSLCA.new takes OpenSSL::PKey as second argument. Given: #{key.inspect}" unless key.class.ancestors.include? OpenSSL::PKey::PKey
		raise "OpenSSLCA.new takes String as third argument. Given: #{database_url.inspect}" unless database_url.is_a? String
		raise "Key does not match Certificate" unless cert.check_private_key key

		@db_conn = Sequel.connect(database_url)
		@ca_cert = cert
		@ca_key = key

		@serial = Serial.new @db_conn
		@database = Database.new cert, key, @db_conn
	end

	def init_ca!
		@serial.init_ca!
		@database.init_ca!
	end

	def sign(req, valid_secs, subject = nil)
		raise "OpenSSLCA.sign takes OpenSSL::X509::Request as first argument. Given: #{req.inspect}" unless req.is_a? OpenSSL::X509::Request
		raise "OpenSSLCA.sign takes OpenSSL::X509::Name or nothing as third argument. Given: #{subject.inspect}" unless subject.is_a? OpenSSL::X509::Name or subject.nil?

		@serial.wait
		@serial.lock!
		begin
			cert = OpenSSL::X509::Certificate.new
			from = Time.now
			if subject.nil? then
				cert.subject = req.subject
			else
				cert.subject = subject
			end
			cert.public_key = req.public_key
			cert.serial = @serial.to_i
			cert.issuer = @ca_cert.subject
			cert.not_before = from
			cert.not_after = from + valid_secs
			cert.version = 2

			raise "There is already a signed Certificate with DN #{cert.subject.to_s} in database. Revoke it first" if @database.include_valid_cert? cert
			cert.sign @ca_key, OpenSSL::Digest::SHA1.new
			@database << cert

			@serial.next! true
		rescue
			@serial.unlock!
			raise
		end

		cert
	end

	def revoke(dn)
		s = dn.to_s
		if dn.is_a? OpenSSL::X509::Certificate then
			s = dn.subject.to_s
		end

		raise "DN #{s} not found in database" unless @database.include_valid_cert?(s)
		@database.revoke!(s)
		@database.crl
	end

	def crl
		@database.crl
	end

	def has_valid_cert?(subject)
		raise "OpenSSLCA.has_valid_cert? takes OpenSSL::X509::Name as first argument. Given: #{subject.inspect}" unless subject.is_a? OpenSSL::X509::Name

		@database.include_valid_cert? subject
	end

	def db
		@db_conn
	end
end
