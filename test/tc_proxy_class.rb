# Author:      Chris Wailes <chris.wailes+filigree@gmail.com>
# Project:     Filigree
# Date:        2013/04/19
# Description: Test cases for the ProxyClass module.

############
# Requires #
############

# Gems
require 'minitest/autorun'

# Filigree
require 'filigree/proxy_class'

#######################
# Classes and Modules #
#######################

class ProxyClassTester < Minitest::Test
	class Foo
		def foo(n)
			n + 100
		end

		def common
			true
		end
	end

	class Bar
		def bar(s)
			"Hello #{s}!"
		end

		def common
			false
		end
	end

	class Baz
		include Filigree::ProxyClass

		proxy_for :other_obj

		def initialize
			@other_obj = Foo.new
		end
	end

	class Baf
		include Filigree::ProxyClass

		proxy_for :fobj, :bobj

		def initialize
			@fobj = Foo.new
			@bobj = Bar.new
		end
	end

	class Caz
		def caz
			3.14
		end
	end

	class Fub < Baf
		proxy_for :cobj

		def initialize
			super

			@cobj = Caz.new
		end
	end

	def test_single_proxy
		var = Baz.new

		assert_equal(142, var.foo(42))
	end

	def test_proxy_chain
		var = Baf.new

		assert_equal(142,            var.foo(42))
		assert_equal("Hello world!", var.bar('world'))
		assert(var.common)
	end

	def test_proxy_inheritance
		var0 = Baf.new
		var1 = Fub.new

		assert_raises(NoMethodError) { var0.caz }

		assert_equal(142,            var1.foo(42))
		assert_equal("Hello world!", var1.bar('world'))
		assert_equal(3.14,           var1.caz)
		assert(var1.common)
	end

	def test_wrong_args
		var = Baz.new

		assert_raises(ArgumentError) { var.foo(1, 2) }
	end
end
