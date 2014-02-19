# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/04
# Description:	Test cases for Class extensions.

############
# Requires #
############

# Gems
require 'minitest/autorun'

# Filigree
require 'filigree/class'

#######################
# Classes and Modules #
#######################

class ClassTester < Minitest::Test
	module Foo; end
	
	class Bar
		include Foo
	
		class Baf; end
	end
	
	class Baz < Bar; end
	
	def setup
		
	end
	
	def test_class
		assert Bar.includes_module?(Foo)
		
		assert_equal 'ClassTester::Bar::Baf', Bar::Baf.name 
		assert_equal 'Baf', Bar::Baf.short_name
		
		assert  Baz.subclass_of?(Bar)
		assert !Baz.subclass_of?(Fixnum)
		assert_raises(TypeError) { Baz.subclass_of?(1) }
	end
end
