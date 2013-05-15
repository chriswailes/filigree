# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/15
# Description:	Test cases the InnerClassModule module.

############
# Requires #
############

# Standard Library
require 'test/unit'

# Filigree
require 'filigree/class_methods_module'

#######################
# Classes and Modules #
#######################

class ClassMethodsModuleTester < Test::Unit::TestCase
	module Foo
		include ClassMethodsModule
		
		def foo
			:foo
		end
		
		module ClassMethods
			def foo
				:foo
			end
		end
	end
	
	module Baz
		include ClassMethodsModule
		
		def baz
			:baz
		end
		
		module ClassMethods
			def baz
				:baz
			end
		end
	end
	
	class Bar
		include Foo
	end
	
	class Baf
		include Foo
		include Baz
	end
	
	def test_class_methods_module
		assert_equal :foo, Bar.foo
		assert_equal :foo, Bar.new.foo
	end
	
	def test_double_include
		
		assert_equal :foo, Baf.foo
		assert_equal :foo, Baf.new.foo
		
		assert_equal :baz, Baf.baz
		assert_equal :baz, Baf.new.baz
	end
end
