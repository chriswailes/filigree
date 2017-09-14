# Author:		Chris Wailes <chris.wailes+filigree@gmail.com>
# Project: 	Filigree
# Date:		2013/05/15
# Description:	Test cases the InnerClassModule module.

############
# Requires #
############

# Gems
require 'minitest/autorun'

# Filigree
require 'filigree/class_methods_module'

#######################
# Classes and Modules #
#######################

class ClassMethodsModuleTester < Minitest::Test
	module Foo
		include Filigree::ClassMethodsModule

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
		include Filigree::ClassMethodsModule

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

#	module ModuleVarTester0
#		include Filigree::ClassMethodsModule

#		module ClassMethods
#			module Variables
#				@
#			end

#			def answer
#				@answer
#			end

#			def answer=(val)
#				@answer = val
#			end
#		end
#	end

#	module ModuleVarTester1
#		include Filigree::ClassMethodsModule

#		def ClassVariables
#			@hoopy = :frood
#		end

#		module ClassMethods
#			def hoopy
#				@hoopy
#			end
#		end
#	end

#	class VarTester0
#		include ModuleVarTester0
#	end

#	class VarTester1
#		include ModuleVarTester0
#	end

#	class VarTester2
#		include ModuleVarTester0
#		include ModuleVarTester1
#	end

	def test_class_methods_module
		assert_equal :foo, Bar.foo
		assert_equal :foo, Bar.new.foo
	end

#	def test_class_variables
#		assert_equal 42, VarTester0.answer
#		assert_equal 42, VarTester1.answer

#		VarTester1.answer = 0

#		assert_equal 42, VarTester0.answer
#		assert_equal  0, VarTester1.answer

#		assert_equal     42, VarTester2.answer
#		assert_equal :frood, VarTester2.hoopy
#	end

	def test_double_include

		assert_equal :foo, Baf.foo
		assert_equal :foo, Baf.new.foo

		assert_equal :baz, Baf.baz
		assert_equal :baz, Baf.new.baz
	end
end
