# Author:		Chris Wailes <chris.wailes+filigree@gmail.com>
# Project: 	Filigree
# Date:		2013/04/19
# Description:	Test cases for the AbstractClass module.

############
# Requires #
############

# Gems
require 'minitest/autorun'

# Filigree
require 'filigree/abstract_class'

#######################
# Classes and Modules #
#######################

class AbstractClassTester < Minitest::Test
	class Foo
		extend Filigree::AbstractClass

		abstract_method :foo
	end

	class Bar < Foo; end

	class Bam < Foo
		def foo
			true
		end
	end

	class Baf < Foo
		extend Filigree::AbstractClass
	end

	class Zap < Baf; end

	def setup
	end

	def test_abstract_method
		assert_raises(AbstractMethodError) { Bar.new.foo }

		Bam.new.foo
	end

	def test_instantiate_abstract_class
		assert_raises(AbstractClassError) { Foo.new }
	end

	def test_instantiate_subclass
		Bar.new
	end

	def test_multi_level_abstract_hierarchy
		assert_raises(AbstractClassError) { Baf.new }

		Zap.new
	end

	def test_multiple_hierarchies
		baf = Class.new { extend Filigree::AbstractClass }
		baz = Class.new(baf)

		assert_raises(AbstractClassError) { Foo.new }
		assert_raises(AbstractClassError) { baf.new }

		Bar.new
		baz.new
	end
end
