# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/04
# Description:	Test cases for Boolean extensions

############
# Requires #
############

# Standard Library
require 'test/unit'

# Filigree
require 'filigree/boolean'

#######################
# Classes and Modules #
#######################

class BooleanTester < Test::Unit::TestCase
	def setup
		
	end
	
	def test_integer
		assert  1.to_bool
		assert 10.to_bool
		assert !0.to_bool
	end
	
	def test_true
		assert_equal 1, true.to_i
	end
	
	def test_false
		assert_equal 0, false.to_i
	end
end
