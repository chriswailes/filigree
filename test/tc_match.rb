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
	
	def match_tester_simple(o)
		match o do
			with(1) { :one   }
			with(2) { :two   }
			with(3) { :three }
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
	
	def match_tester_wildcard(o)
		match o do
			with(1)	{ 1 }
			with(2)	{ 2 }
			with(:_)	{ |n| n   }
		end
	end
	
	def match_tester_guard(o)
		match o do
			with(:_, ->(n) { n < 0 })	{ :NEG  }
			with(0)					{ :ZERO }
			with(:_, ->(n) { n > 0 })	{ :POS  }
		end
	end
	
	def test_constants
		assert_equal :one,   match_tester_simple(1)
		assert_equal :two,   match_tester_simple(2)
		assert_equal :three, match_tester_simple(3)
		
		assert_raise(MatchError) { match_tester_simple(4) }
		
		assert_equal :hello0, match_tester_mixed('hello')
		assert_equal :world,  match_tester_mixed(:world)
		assert_equal :one,    match_tester_mixed(1)
	end
	
	def test_guards
		assert_equal :NEG,  match_tester_guard(-5)
		assert_equal :ZERO, match_tester_guard(0)
		assert_equal :POS,  match_tester_guard(6)
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
