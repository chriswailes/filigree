# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/04
# Description:	Test cases for the Object extensions.

############
# Requires #
############

# Standard Library
require 'test/unit'

# Filigree
require 'filigree/match'

#######################
# Classes and Modules #
#######################

class MatchTester < Test::Unit::TestCase
	
	def setup
		
	end
	
	###########
	# Helpers #
	###########
	
	def match_tester_deferred(o)
		match o do
			with(1)
			with(2) { :NUM }
			with(:a)
			with(:b) { :SYM }
		end
	end
	
	def match_tester_guard(o)
		match o do
			with(:_, ->(n) { n < 0 })	{ :NEG  }
			with(0)					{ :ZERO }
			with(:_, ->(n) { n > 0 })	{ :POS  }
		end
	end
	
	def match_tester_mixed(o)
		match o do
			with('hello')	{ :hello0 }
			with('hello')	{ :hello1 }
			with(:world)	{ :world  }
			with(1)		{ :one    }
		end
	end
	
	def match_tester_simple(o)
		match o do
			with(1) { :one   }
			with(2) { :two   }
			with(3) { :three }
		end
	end
	
	def match_tester_tuple(*touple)
		match *touple do
			with(1, 2)	{ :FOO }
			with(3, 4)	{ :BAR }
			with(5)		{ :BAF }
		end
	end
	
	def match_tester_tuple_wildcard(*touple)
		match *touple do
			with(1)
			with(2,3)		{ :DEF }
			with(4, :_)	{ :PART_WILD }
			with(:_)		{ :WILD }
		end
	end
	
	def match_tester_wildcard(o)
		match o do
			with(1)	{ 1 }
			with(2)	{ 2 }
			with(:_)	{ |n| n   }
		end
	end
	
	#########
	# Tests #
	#########
	
	def test_constants
		assert_equal :one,   match_tester_simple(1)
		assert_equal :two,   match_tester_simple(2)
		assert_equal :three, match_tester_simple(3)
		
		assert_raise(MatchError) { match_tester_simple(4) }
		
		assert_equal :hello0, match_tester_mixed('hello')
		assert_equal :world,  match_tester_mixed(:world)
		assert_equal :one,    match_tester_mixed(1)
	end
	
	def test_deferred_block
		assert_equal :NUM, match_tester_deferred(1)
		assert_equal :NUM, match_tester_deferred(2)
		
		assert_equal :SYM, match_tester_deferred(:a)
		assert_equal :SYM, match_tester_deferred(:b)
	end
	
	def test_guards
		assert_equal :NEG,  match_tester_guard(-5)
		assert_equal :ZERO, match_tester_guard(0)
		assert_equal :POS,  match_tester_guard(6)
	end
	
	def test_tuple_wildcard
		assert_equal :DEF, match_tester_tuple_wildcard(1)
		assert_equal :DEF, match_tester_tuple_wildcard(2, 3)
		
		assert_equal :PART_WILD, match_tester_tuple_wildcard(4, 1)
		assert_equal :PART_WILD, match_tester_tuple_wildcard(4, :cat)
		
		assert_equal :WILD, match_tester_tuple_wildcard(5)
		assert_equal :WILD, match_tester_tuple_wildcard(5, 6)
		assert_equal :WILD, match_tester_tuple_wildcard(5, 6, 7)
	end
	
	def test_tuples
		assert_equal :FOO, match_tester_tuple(1, 2)
		assert_equal :BAR, match_tester_tuple(3, 4)
		assert_equal :BAF, match_tester_tuple(5)
		
		assert_raise(MatchError) { match_tester_tuple(1, 2, 3) }
		assert_raise(MatchError) { match_tester_tuple(6)		}
	end
	
	def test_wildcard_pattern
		result =
		match 42 do
			with(:_) { |n| n }
		end
		
		assert_equal 42, result
		
		assert_equal  1, match_tester_wildcard(1)
		assert_equal 42, match_tester_wildcard(42)
	end
end
