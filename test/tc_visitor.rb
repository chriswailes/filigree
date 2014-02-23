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

class VisitorTester < Minitest::Test
	
	####################
	# Internal Classes #
	####################
	
	class Foo
		extend Filigree::Destructurable
		
		def initialize(a)
			@a = a
		end
		
		def destructure(_)
			[@a]
		end
		
		def visit(visitor)
			visitor.(self)
		end
	end
	
	class Bar
		extend Filigree::Destructurable
		
		def initialize(a, b)
			@a = a
			@b = b
		end
		
		def destructure(_)
			[@a, @b]
		end
		
		def visit(visitor)
			visitor(self)
		end
	end
	
	class Node
		extend Filigree::Destructurable
		include Filigree::Visitable
		
		def initialize(val, left = nil, right = nil)
			@val   = val
			@left  = left
			@right = right
		end
		
		def children
			[ @left, @right ]
		end
		
		def destructure(_)
			[ @val, @left, @right ]
		end
	end
	
	class SimpleVisitor
		include Filigree::Visitor
		
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
		include Filigree::Visitor
		
		def helper(_)
			true
		end
		
		on Foo.(n), -> { helper(n) } do
			:foo
		end
	end
	
	class AdditiveVisitor
		include Filigree::Visitor
		
		attr_reader :total
		
		def initialize
			@total = 0
		end
		
		on(Foo.(Fixnum.as n)) do
			@total += n
		end
	end
	
	class MultiplicativeVisitor
		include Filigree::Visitor
		
		attr_reader :total
		
		def initialize
			@total = 1
		end
		
		on(Foo.(Fixnum.as n)) do
			@total *= n
		end
	end
	
	class NodeVisitor
		include Filigree::Visitor
		
		attr_reader :vals
		
		def initialize
			@vals = []
		end
		
		on(Node.(val, _, _)) do
			@vals << val
		end
	end
	
	def setup
	end
	
	def test_simple_visitor
		sv = SimpleVisitor.new
		
		assert_equal :one,   sv.(1)
		assert_equal :two,   sv.(:two)
		assert_equal :three, sv.('three')
		assert_equal :four,  sv.(Foo.new(4))
		assert_equal :five,  sv.(Foo.new(5))
		assert_equal :six,   sv.(Foo.new('six'))
	end
	
	def test_stateful_visitor
		av = AdditiveVisitor.new
		
		assert_equal  1, Foo.new(1).visit(av)
		assert_equal  3, Foo.new(2).visit(av)
		assert_equal 42, Foo.new(39).visit(av)
	end
	
	def test_tour_guide
		tg = Filigree::TourGuide.new(AdditiveVisitor.new, MultiplicativeVisitor.new)
		
		Foo.new(1).visit(tg)
		Foo.new(2).visit(tg)
		Foo.new(39).visit(tg)
		
		assert_equal 42, tg.visitors[0].total
		assert_equal 78, tg.visitors[1].total
	end
	
	def test_visibility
		hmv = HelperMethodVisitor.new
		
		assert_equal :foo, hmv.(Foo.new(42))
	end
	
	def test_visitable
		tree = Node.new('F',
		                Node.new('B',
		                         Node.new('A'),
		                         Node.new('D',
		                                  Node.new('C'),
		                                  Node.new('E')
		                                 ),
		                        ),
		                Node.new('G',
		                         Node.new('I',
		                                  Node.new('H')
		                                 )
		                        )
		               )
		
		# Test pre-order
		nv       = NodeVisitor.new
		expected = ['F', 'B', 'A', 'D', 'C', 'E', 'G', 'I', 'H']
		tree.visit(nv, :preorder)
		
		assert_equal expected, nv.vals
		
		# Test level-order
		nv       = NodeVisitor.new
		expected = ['F', 'B', 'G', 'A', 'D', 'I', 'C', 'E', 'H']
		tree.visit(nv, :levelorder)
		
		assert_equal expected, nv.vals
		
		# Test post-order
		nv       = NodeVisitor.new
		expected = ['A', 'C', 'E', 'D', 'B', 'H', 'I', 'G', 'F']
		tree.visit(nv, :postorder)
		
		assert_equal expected, nv.vals
	end
end
