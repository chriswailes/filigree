# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2014/02/05
# Description:	Test cases for the Array extensions.

############
# Requires #
############

# Gems
require 'minitest/autorun'

# Filigree
require 'filigree/array'

#######################
# Classes and Modules #
#######################

class ArrayTester < Minitest::Test
	
	def setup
	end
	
	def test_map_with_method
		assert_equal [:cat, :dog, :cow], ['cat', 'dog', 'cow'].map(:to_sym)
	end
end
