# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2014/02/11
# Description:	Test cases for the Visitor module.

############
# Requires #
############

# Gems
require 'minitest/autorun'

# Filigree
require 'filigree/visitor'

#######################
# Classes and Modules #
#######################

class MatchTester < Minitest::Test
	
	####################
	# Internal Classes #
	####################
	
	class Foo
		extend Destructurable
		
		def initialize(a)
			@a = a
		end
		
		def destructure(_)
			[@a]
		end
	end
	
	class Bar
		extend Destructurable
		
		def initialize(a, b)
			@a = a
			@b = b
		end
		
		def destructure(_)
			[@a, @b]
		end
	end
	
	class SimpleVisitor
		include Visitor
		
		on 1 do
			:one
		end
		
		on :two do |two|
			two
		end
		
		on /three/ do
			:three
		end
		
		on Foo.(4) do
			:four
		end
		
		on Foo.(n), -> { n == 5 } do
			:five
		end
		
		on Foo.(n), -> { n == 'six' } do
			n.to_sym
		end
	end
	
	class HelperMethodVisitor
		include Visitor
		
		def helper(_)
			true
		end
		
		on Foo.(n), -> { helper(n) } do
			:foo
		end
	end
	
	class AdditiveVisitor
		include Visitor
		
		def initialize
			@total = 0
		end
		
		on(Foo.(Fixnum.as n)) do
			@total += n
		end
	end
	
	def setup
	end
	
#	def test_simple_visitor
#		sv = SimpleVisitor.new
#		
#		assert_equal :one,   sv.(1)
#		assert_equal :two,   sv.(:two)
#		assert_equal :three, sv.('three')
#		assert_equal :four,  sv.(Foo.new(4))
#		assert_equal :five,  sv.(Foo.new(5))
#		assert_equal :six,   sv.(Foo.new('six'))
#	end
	
	def test_stateful_visitor
		av = AdditiveVisitor.new
		
		assert_equal  1, av.(Foo.new(1))
		assert_equal  3, av.(Foo.new(2))
		assert_equal 42, av.(Foo.new(39))
	end
	
#	def test_visibility
#		hmv = HelperMethodVisitor.new
#		
#		assert_equal :foo, hmv.(Foo.new(42))
#	end
end
