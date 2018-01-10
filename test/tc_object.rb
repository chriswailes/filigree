# Author:      Chris Wailes <chris.wailes+filigree@gmail.com>
# Project:     Filigree
# Date:        2013/05/04
# Description: Test cases for the Object extensions.

############
# Requires #
############

# Gems
require 'minitest/autorun'

# Filigree
require 'filigree/object'

#######################
# Classes and Modules #
#######################

class ObjectTester < Minitest::Test

	using Filigree

	Foo = Struct.new :a, :b

	def test_returning
		assert( returning(true) { false } )
	end

	def test_with
		v0 = Foo.new(1, 2)
		v1 = v0.clone_with { self.a = 3 }

		assert_equal 1, v0.a
		assert_equal 2, v0.b

		assert_equal 3, v1.a
		assert_equal 2, v1.b

		refute_equal v0.object_id, v1.object_id
	end
end
