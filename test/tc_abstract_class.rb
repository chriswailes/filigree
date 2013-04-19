# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/4/19
# Description:	

############
# Requires #
############

# Standard Library
require 'test/unit'

# Filigree
require 'filigree/abstract_class'

#######################
# Classes and Modules #
#######################

class AbstractClassTester < Test::Unit::TestCase
	class Foo
		extend AbstractClass
		
		abstract_method :foo
	end
	
	class Bar < Foo; end
	
	class Bam < Foo
		def foo
			true
		end
	end
	
	def setup
	
	end
	
	def test_abstract_method
		assert_raise(AbstractMethodError) { Bar.new.foo }
		
		assert_nothing_raised { Bam.new.foo }
	end
	
	def test_instantiate_abstract_class
		assert_raise(AbstractClassError) { Foo.new }
	end
	
	def test_instantiate_subclass
		assert_nothing_raised { Bar.new }
	end
	
	def test_multiple_hierarchies
		baf = Class.new { extend AbstractClass }
		baz = Class.new(baf)
		
		assert_raise(AbstractClassError) { Foo.new }
		assert_raise(AbstractClassError) { baf.new }
		
		assert_nothing_raised { Bar.new }
		assert_nothing_raised { baz.new }
	end
end
