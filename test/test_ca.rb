require "test/unit"
require "ca"
require File.absolute_path(File.join(File.dirname(__FILE__), 'keys.rb'))

class TestCa < Test::Unit::TestCase
	def test_ca
		assert ca = CA.new(CA_CERT, CA_KEY, "sqlite:/")
		assert ca.init_ca!

		assert_raise(RuntimeError){ca.sign(CA_CERT, 1)}
		assert_raise(RuntimeError){ca.sign(CA_KEY, 1)}
		assert cert = ca.sign(REQ, 3600)
		assert_instance_of OpenSSL::X509::Certificate, cert
		assert cert.verify(CA_CERT.public_key)

		assert_in_delta cert.not_before, Time.now, 5
		assert_in_delta cert.not_after, Time.now + 3600, 5
		assert_equal cert.issuer.hash, CA_CERT.subject.hash

		assert_instance_of OpenSSL::X509::CRL, crl = ca.crl
		assert ca.revoke(cert.subject.to_s)
		assert_not_same crl.hash, ca.crl.hash
	end
end
