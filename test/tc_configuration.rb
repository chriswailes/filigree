# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/15
# Description:	Test cases the Configuration module.

############
# Requires #
############

# Standard Library
require 'test/unit'

# Filigree
require 'filigree/configuration'

#######################
# Classes and Modules #
#######################

class ConfigurationTester < Test::Unit::TestCase
	class TestConfig
		include Filigree::Configuration
		
		auto :foo do
			:foo
		end
		
		help 'foo'
	end
	
	def test_auto
		assert_equal :foo, TestConfig.new.foo
		assert_equal 'foo', TestConfig.new.help_string
	end
end
