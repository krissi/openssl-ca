require 'sequel'

class OpenSSLCA
	class Serial
		MAX_LOCK=10

		def initialize(database)
			@database = database
		end

		def init_ca!
			@database.create_table :serial do
				primary_key :serial
				DateTime :lock, :null => true
			end

			@database[:serial] << {:serial => 1}
		end

		def next!(havelock = false)
			raise "Serial is locked!" if locked? and not havelock
			cur = to_i
			@database[:serial].update(:serial => cur +1)
			unlock!
			cur
		end

		def lock!
			raise "Serial is locked!" if locked?
			@database[:serial].update(:lock => Time.now)
			true
		end

		def unlock!
			@database[:serial].update(:lock => nil)
		end

		def locked?
			l = @database[:serial].first[:lock]
			if l.nil? then
				return false
			end

			if (l + MAX_LOCK) <= Time.now then
				@database[:serial].update(:lock => nil)
				return false
			end

			true
		end

		def wait
			return true unless locked?
			l = @database[:serial].first[:lock]
			t = (l + MAX_LOCK) - Time.now
			sleep t if t > 0
		end

		def to_i
			@database[:serial].first[:serial]
		end

		def to_s
			@to_i.to_s
		end
	end
end

