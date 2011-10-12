require "test/unit"
require "ca"

class TestCaSerial < Test::Unit::TestCase
	def test_ca_serial
		serial = CA::Serial.new Sequel.sqlite
		assert_equal serial.class, CA::Serial
		assert serial.init_ca!

		assert_equal serial.to_i, 1
		assert_equal serial.locked?, false
		assert true
	end

	def test_ca_serial_lock
		serial = CA::Serial.new Sequel.sqlite
		serial.init_ca!

		assert_equal serial.locked?, false
		assert serial.lock!
		assert_equal serial.locked?, true
		assert_raise(RuntimeError){ serial.lock! }
		assert serial.unlock!
		assert_equal serial.locked?, false
		assert serial.unlock!

		assert serial.lock!
		sleep 15
		assert_equal serial.locked?, false

		assert serial.wait
		assert serial.lock!
		assert serial.wait
		assert_equal serial.locked?, false
	end

	def test_ca_serial_modify
		serial = CA::Serial.new Sequel.sqlite
		serial.init_ca!

		assert serial.next!
		assert_equal serial.to_i, 2
		assert serial.next!
		assert_equal serial.to_i, 3
		assert serial.lock!
		assert_raise(RuntimeError){serial.next!}
		assert serial.next! true
		assert_equal serial.locked?, false
		assert_equal serial.to_i, 4
	end
end
