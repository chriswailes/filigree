# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/04
# Description:	Test cases for the Object extensions.

############
# Requires #
############

# Gems
require 'minitest/autorun'

# Filigree
require 'filigree/match'

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
	
	def setup
		
	end
	
	###########
	# Helpers #
	###########
	
	def match_tester_array_destructure(o)
		match o do
			with(Array.(x, [])) {       x }
			with(Array.(x, xs)) { [x, xs] }
		end
	end
	
	def match_tester_destructure(o)
		match o do
			with(Foo.( 1))           { :one }
			with(Foo.(:a))           { :a   }
			with(Foo.(Foo.(:b)))     { :b   }
			
			with(Foo.(Foo.(a).as b)) { [a, b] }
			
			with(Foo.(a))
			with(Bar.(a, _))         { a }
		end
	end
	
	def match_tester_deferred(o)
		match o do
			with(1)
			with(2)  { :NUM }
			with(:a)
			with(:b) { :SYM }
		end
	end
	
	def match_tester_guard(o)
		match o do
			with(n, -> { n < 0 }) { :NEG  }
			with(0)               { :ZERO }
			with(n, -> { n > 0 }) { :POS  }
		end
	end
	
	def match_tester_instance_pattern(o)
		match o do
			with(Instance(Fixnum, a)) { [:Fixnum, a] }
			with(Instance(Float, a))  { [:Float,  a] }
			with(Instance(String, a)) { [:String, a] }
		end
	end
	
	def match_tester_manual_bind(o)
		match o do
			with(Fixnum.(Bind(:a))) { [:Fixnum, a] }
			with(Float.(Bind(:a)))  { [:Float,  a] }
			with(String.(Bind(:a))) { [:String, a] }
		end
	end
	
	def match_tester_mixed(o)
		match o do
			with('hello') { :hello0 }
			with('hello') { :hello1 }
			with(:world)  { :world  }
			with(1)       { :one    }
		end
	end
	
	def match_tester_regexp(s)
		match s do
			with(/(ab)+/)  { :a }
			with(/[abc]+/) { :b }
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
			with(1, 2) { :FOO }
			with(3, 4) { :BAR }
			with(5)    { :BAF }
		end
	end
	
	def match_tester_tuple_wildcard(*touple)
		match *touple do
			with(1)
			with(2, 3) { :DEF }
			with(4, _) { :PART_WILD }
			with(_)    { :WILD }
		end
	end
	
	def match_tester_wildcard(o)
		match o do
			with(1) { 1 }
			with(2) { 2 }
			with(n) { n }
		end
	end
	
	#########
	# Tests #
	#########
	
	def test_array_destructure
		assert_equal             42, match_tester_array_destructure([42])
		assert_equal [1, [2, 3, 4]], match_tester_array_destructure([1, 2, 3, 4])
	end
	
	def test_as
		v0 = Foo.new(:dog)
		v1 = Foo.new(v0)
		
		assert_equal([:dog, v0], match_tester_destructure(v1))
	end
	
	def test_constants
		assert_equal :one,   match_tester_simple(1)
		assert_equal :two,   match_tester_simple(2)
		assert_equal :three, match_tester_simple(3)
		
		assert_raises(MatchError) { match_tester_simple(4) }
		
		assert_equal :hello0, match_tester_mixed('hello')
		assert_equal :world,  match_tester_mixed(:world)
		assert_equal :one,    match_tester_mixed(1)
	end
	
	def test_deconstructor
		assert_equal :one, match_tester_destructure(Foo.new(   1))
		assert_equal :a,   match_tester_destructure(Foo.new(  :a))
		assert_equal 42.0, match_tester_destructure(Foo.new(42.0))
		
		assert_equal :b,   match_tester_destructure(Foo.new(Foo.new(:b)))
		assert_equal 42,   match_tester_destructure(Bar.new(42, nil))
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
	
	def test_instance_pattern
		assert_equal [:Fixnum, 42],    match_tester_instance_pattern(42)
		assert_equal [:Float, 42.0],   match_tester_instance_pattern(42.0)
		assert_equal [:String, 'foo'], match_tester_instance_pattern('foo')
	end
	
	def test_manual_bind
		assert_equal [:Fixnum, 42],    match_tester_manual_bind(42)
		assert_equal [:Float, 42.0],   match_tester_manual_bind(42.0)
		assert_equal [:String, 'foo'], match_tester_manual_bind('foo')
	end
	
	def test_match_array
		result =
		match [1,2,3,4] do
		with(Array.(a, b, c))	{ [a, b, c] }
		end
		
		assert_equal [1, 2, [3, 4]], result
	end
	
	def test_regexp
		assert_equal :a, match_tester_regexp('abab')
		assert_equal :b, match_tester_regexp('acba')
		
		assert_raises(MatchError) { match_tester_regexp('def') }
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
		
		assert_raises(MatchError) { match_tester_tuple(1, 2, 3) }
		assert_raises(MatchError) { match_tester_tuple(6)		}
	end
	
	def test_wildcard_pattern
		result =
		match 42 do
			with(n) { n }
		end
		
		assert_equal 42, result
		
		assert_equal  1, match_tester_wildcard(1)
		assert_equal 42, match_tester_wildcard(42)
	end
end
