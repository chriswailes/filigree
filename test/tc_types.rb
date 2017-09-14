# Author:		Chris Wailes <chris.wailes+filigree@gmail.com>
# Project: 	Filigree
# Date:		2013/05/04
# Description:	Test cases for type checking.

############
# Requires #
############

# Gems
require 'minitest/autorun'

# Filigree
require 'filigree/types'

#######################
# Classes and Modules #
#######################

class TypeTester < Minitest::Test

	class Foo
		include Filigree::TypedClass

		typed_ivar :foo, Integer
		typed_ivar :bar, String
		typed_ivar :baf, [Integer]
	end

	class Bar
		include Filigree::TypedClass

		typed_ivar :foo, Integer
		typed_ivar :bar, String

		default_constructor
	end

	class Baf
		include Filigree::TypedClass

		typed_ivar :foo, Integer
		typed_ivar :bar, String, nillable: true

		default_constructor
	end

	class Baz
		include Filigree::TypedClass

		typed_ivar :foo, Integer
		typed_ivar :bar, String

		default_constructor true
	end

	def setup

	end

	def test_check_type
		assert check_type([], Array)

		assert check_type(1,   Integer)
		assert check_type(nil, Integer, nillable: true).nil?
		assert check_type(1,   Integer, strict: true)
		assert check_type(nil, Integer, nillable: true, strict: true).nil?

		assert_raises(TypeError) { check_type(1, Numeric, strict: true) }
		assert_raises(TypeError) { check_type(1, Array) }
	end

	def test_check_array_type
		assert check_array_type([1, 2, 3],      Integer)
		assert check_array_type([1, 2, 3, nil], Integer, nillable: true)
		assert check_array_type([1, 2, 3],      Integer, strict: true)
		assert check_array_type([1, 2, 3, nil], Integer, nillable: true, strict: true)

		assert_raises(TypeError) { check_array_type([1, 2, 3],            Numeric, strict: true) }
		assert_raises(TypeError) { check_array_type([1, :hello, 'world'], Integer) }
		assert_raises(TypeError) { check_array_type([1, 2, 3],            Float, blame: 'foo') }
	end

	def test_default_constructor
		v0 = Bar.new(1, 'hello')

		assert_equal 1,       v0.foo
		assert_equal 'hello', v0.bar

		v1 = Baf.new(2)

		assert_equal 2, v1.foo
		assert_nil   v1.bar

		assert_raises(ArgumentError) { Baz.new(3) }

		v2 = Baz.new(2, 'world')

		assert_equal 2,       v2.foo
		assert_equal 'world', v2.bar
	end

	def test_typed_instance_vars
		v0 = Foo.new

		v0.foo = 1
		v0.bar = 'hello'
		v0.baf = [1,2,3]

		assert_equal 1,       v0.foo
		assert_equal 'hello', v0.bar
		assert_equal [1,2,3], v0.baf

		assert_raises(TypeError) { v0.foo = 'world' }
	end
end
