# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/4/19
# Description:	Test cases for the AbstractClass module.

############
# Requires #
############

# Standard Library
require 'test/unit'

# Filigree
require 'filigree/object'

#######################
# Classes and Modules #
#######################

class ObjectTester < Test::Unit::TestCase
	def setup
		
	end
	
	def test_returning
		assert( returning(true) { false } )
	end
end
