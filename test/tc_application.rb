# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/15
# Description:	Test cases for the Application module.

############
# Requires #
############

# Standard Library
require 'test/unit'

# Filigree
require 'filigree/application'

#######################
# Classes and Modules #
#######################

class ApplicationTester < Test::Unit::TestCase
	class Foo
		include Filigree::Application
	end
	
	class Bar
		include Filigree::Application
		
		class Configuration
			auto :foo do
				:foo
			end
		end
		
		def kill;		end
		def pause;	end
		def resume;	end
		def run;		end
		def stop;		end
	end
	
	def setup
	
	end
	
	def test_application
		assert_raise(NoMethodError)	{ Foo.finalize }
		assert_nothing_raised		{ Bar.finalize }
	end
	
	def test_embedded_config
		assert_equal :foo, Bar.new.config.foo
	end
end
