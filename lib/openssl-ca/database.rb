class OpenSSLCA
	class Database
		def initialize(cert, key, database)
			@cert = cert
			@key = key
			@database = database
		end

		def init_ca!
			@database.create_table :index do
				String :status, :fixed => true, :size => 1, :null => false
				DateTime :not_after, :null => false
				DateTime :revoked_at, :null => true
				primary_key :serial, :auto_increment => false
				String :location, :null => true
				String :dn, :null => false
				#TODO append full certificate
			end
			true
		end

		def <<(cert)
			raise "DN #{cert.subject.to_s} already in database" if include_valid_cert? cert

			@database[:index].insert(	:status		=> 'V',		# [V]alid, [E]xpires, [R]evoked
										:not_after	=> cert.not_after,
										:revoked_at	=> nil,
										:serial		=> cert.serial.to_i,
										:location	=> nil,
										:dn			=> cert.subject.to_s
									)
		end

		def include_valid_cert?(s)
			if s.is_a? OpenSSL::X509::Certificate then
				subject = s.subject
			else
				subject = s
			end

			not @database[:index][:status => 'V', :dn => subject.to_s].nil?
		end

		def [](filter)
			@database[:index][filter]
		end

		def revoke!(dn)
			raise "Certificate not found revokeable in database" if @database[:index][:status => 'V', :dn => dn].nil?
			@database[:index].filter(:status => 'V', :dn => dn).update(:status => 'R', :revoked_at => Time.now)
		end

		def crl(next_secs = 86400)
			crl = OpenSSL::X509::CRL.new
			@database[:index].filter(:status => 'R').each do |c|
				r = OpenSSL::X509::Revoked.new
				r.serial = c[:serial]
				r.time = c[:revoked_at]
				crl.add_revoked r
			end
			crl.version = 1
			crl.issuer = @cert.issuer
			crl.last_update = Time.now
			crl.next_update = Time.now + next_secs
			crl.sign @key, OpenSSL::Digest::SHA1.new
			crl
#			p crl
		end
	end
end
