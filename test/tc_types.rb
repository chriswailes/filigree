# Author:		Chris Wailes <chris.wailes@gmail.com>
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
		include TypedClass
		
		typed_ivar :foo, Integer
		typed_ivar :bar, String
		typed_ivar :baf, [Integer]
	end
	
	class Bar
		include TypedClass
		
		typed_ivar :foo, Integer
		typed_ivar :bar, String
		
		default_constructor
	end
	
	class Baf
		include TypedClass
		
		typed_ivar :foo, Integer
		typed_ivar :bar, String, true
		
		default_constructor
	end
	
	class Baz
		include TypedClass
		
		typed_ivar :foo, Integer
		typed_ivar :bar, String
		
		default_constructor true
	end
	
	def setup
		
	end
	
	def test_check_type
		assert check_type([], Array)
		
		assert check_type(1, Fixnum)
		assert check_type(nil, Fixnum, nil, true).nil?
		assert check_type(1, Fixnum, nil, false, true)
		assert check_type(nil, Fixnum, nil, true, true).nil?
		assert check_type(1, Integer)
		
		assert_raises(TypeError) { check_type(1, Integer, nil, false, true) }
		assert_raises(TypeError) { check_type(1, Array) }
	end
	
	def test_check_array_type
		assert check_array_type([1, 2, 3], Fixnum)
		assert check_array_type([1, 2, 3], Fixnum, nil, true)
		assert check_array_type([1, 2, 3], Integer)
		
		assert_raises(TypeError) { check_array_type([1, 2, 3], Integer, nil, false, true) }
		assert_raises(TypeError) { check_array_type([1, :hello, 'world'], Fixnum) }
		assert_raises(TypeError) { check_array_type([1, 2, 3], Float, 'foo') }
	end
	
	def test_default_constructor
		v0 = Bar.new(1, 'hello')
		
		assert_equal 1, v0.foo
		assert_equal 'hello', v0.bar
		
		v1 = Baf.new(2)
		
		assert_equal 2, v1.foo
		assert_nil v1.bar
		
		assert_raises(ArgumentError) { Baz.new(3) }
		
		v2 = Baz.new(2, 'world')
		
		assert_equal 2, v2.foo
		assert_equal 'world', v2.bar
	end
	
	def test_typed_instance_vars
		v0 = Foo.new
		
		v0.foo = 1
		v0.bar = 'hello'
		v0.baf = [1,2,3]
		
		assert_equal 1, v0.foo
		assert_equal 'hello', v0.bar
		assert_equal [1,2,3], v0.baf
		
		assert_raises(TypeError) { v0.foo = 'world' }
	end
end
