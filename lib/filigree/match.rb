# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/04
# Description:	Pattern matching for Ruby.

############
# Requires #
############

# Standard Library
require 'ostruct'
require 'singleton'

# Filigree
require 'filigree/abstract_class'
require 'filigree/class'

##########
# Errors #
##########

# An error that indicates that no pattern matched a given object.
class MatchError < RuntimeError; end

###########
# Methods #
###########

# This is an implementation of pattern matching.  The objects passed to match
# are tested against the patterns defined inside the match block.  The return
# value of `match` will be the result of evaluating the block given to `with`.

# The most basic pattern is the literal.  Here, the object or objects being
# matched will be tested for equality with value passed to `with`.  In the
# example below, the call to `match` will return `:one`.  Similar to the
# literal pattern is the wildcard pattern `_`.  This will match any object.

# You may also match against variables.  This can sometimes conflict with the
# next kind of pattern, which is a binding pattern.  Here, the pattern will
# match any object, and then make the object it matched available to the with
# block via an attribute reader.  This is accomplished using the method_missing
# callback, so if there is a variable or function with that name you might
# accidentally compare against a variable.  To bind to a name that is already
# in scope you can use the {Filigree::MatchEnvironment#Bind} method.  In
# addition, class and destructuring pattern results (see bellow) can be bound
# to a variable by using the {Filigree::BasicPattern#as} method.

# If you wish to match string patterns you may use regular expressions.  Any
# object that isn't a string will fail to match against a regular expression.
# If the object being matched is a string then the regular expressions `match?`
# method is used.  The result of the regular expression match is available
# inside the with block via the match_data accessor.

# When a class is used in a pattern it will match any object that is an
# instance of that class.  If you wish to compare one regular expression to
# another, or one class to another, you can force the comparison using the
# {Filigree::MatchEnvironment#Literal} method.
#
# Destructuring patterns allow you to match against an instance of a class,
# while simultaneously binding values stored inside the object to variables
# in the context of the with block.  A class that is destructurable must
# include the {Filigree::Destructurable} module.  You can then destructure an
# object as shown bellow.

# Both `match` and `with` can take multiple arguments.  When this happens, each
# object is paired up with the corresponding pattern.  If they all match, then
# the `with` clause matches.  In this way you can match against tuples.

# Any with clause can be given a guard clause by passing a lambda as the last
# argument to `with`.  These are evaluated after the pattern is matched, and
# any bindings made in the pattern are available to the guard clause.

# If you wish to evaluate the same body on matching any of several patterns you
# may list them in order and then specify the body for the last pattern in the
# group.

# Patterns are evaluated in the order in which they are defined and the first
# pattern to match is the one chosen.  You may define helper methods inside the
# match block.  They will be re-defined every time the match statement is
# evaluated, so you should move any definitions outside any match calls that
# are being evaluated often.

# @example The literal pattern
#   def foo(n)
#     match 1 do
#       with(1) { :one   }
#       with(2) { :two   }
#       with(_) { :other }
#     end
#   end
#
#   foo(1)

# @example Matching against variables
#   var = 42
#   match 42 do
#     with(var) { :hoopy }
#     with(0)   { :zero  }
#   end

# @example Binding patterns
#   # Returns 42
#   match 42 do
#     with(x) { x }
#   end

#   x = 3
#   # Returns 42
#   match 42 do
#     with(Bind(:x)) { x      }
#     with(42)       { :hoopy }
#   end

# @example Regular expression and class instance pattern
#    def matcher(object)
#      match object do
#        with(/hoopy/) { 42      }
#        with(Integer) { 'hoopy' }
#      end
#    end

#    # Returns 42
#    matcher('hoopy')
#    # Returns 'hoopy'
#    matcher(42)

# @example Destructuring an object
#    class Foo
#      include Filigree::Destructurable
#      def initialize(a, b)
#        @a = a
#        @b = b
#      end
#
#      def destructure(_)
#         [@a, @b]
#      end
#    end

#    # Returns true
#    match Foo.new(4, 2) do
#      with(Foo.(4, 2)) { true  }
#      with(_)          { false }
#    end

# @example Using guard clauses
#    match o do
#      with(n, -> { n < 0 }) { :NEG  }
#      with(0)               { :ZERO }
#      with(n, -> { n > 0 }) { :POS  }
#    end
#
# @param [Object]  objects  Objects to be matched
# @param [Proc]    block    Block containing with clauses.
#
# @return [Object]  Result of evaluating the matched pattern's block
def match(*objects, &block)
	me = Filigree::MatchEnvironment.new

	me.instance_exec &block

	me.find_match(objects)
end

#######################
# Classes and Modules #
#######################

module Filigree

	###########
	# Methods #
	###########

	# Wrap non-pattern objects in pattern objects so they can all be treated
	# in the same way during pattern sorting and matching.
	#
	# @param [Array<Object>]  pattern  Naked pattern object
	#
	# @return [Array<BasicPattern>]  Wrapped pattern object
	def Filigree::wrap_pattern_elements(pattern)
		pattern.map do |el|
			case el
			when BasicPattern then el
			when Class        then InstancePattern.new(el)
			when Regexp       then RegexpPattern.new(el)
			else                   LiteralPattern.new(el)
			end
		end
	end

	#######################
	# Modules and Classes #
	#######################

	# A module indicating that an object may be destructured.  The including
	# class must define the `destructure` instance method, which takes one
	# argument specifying the number of pattern elements it is being matched
	# against.
	module Destructurable
		# The instance method that generates a destructuring pattern.
		#
		# @param [Object]  pattern  Sub-patterns used to match the destructured elements of the object.
		#
		# @return [DestructuringPattern]
		def call(*pattern)
			DestructuringPattern.new(self, Filigree::wrap_pattern_elements(pattern))
		end
	end

	# Match blocks are evaluated inside an instance of MatchEnvironment.
	class MatchEnvironment
		# Force binding to the given name
		#
		# @param [Symbol]  name  Name to bind the value to
		#
		# @return [BindingPattern]
		def Bind(name)
			BindingPattern.new(name)
		end

		# Force a literal comparison
		#
		# @param [Object]  obj  Object to test equality with
		#
		# @return [LiteralPattern]
		def Literal(obj)
			LiteralPattern.new(obj)
		end

		def initialize
			@patterns = Array.new
			@deferred = Array.new
		end

		# Find a match for the given objects among the defined patterns.
		#
		# @param [Array<Object>]  objects  Objects to be matched
		#
		# @return [Object]  Result of evaluating the matching pattern's block
		#
		# @raise [MatchError]  Raised if no pattern matches the objects
		def find_match(objects)
			@patterns.each do |pattern|
				env = OpenStruct.new

				return pattern.(env, objects) if pattern.match?(objects, env)
			end

			# If we didn't find anything we raise a MatchError.
			raise MatchError
		end

		# Define a pattern in this match call.
		#
		# @see match  Documentation on pattern matching
		#
		# @param [Object]  pattern  Objects defining the pattern
		# @param [Proc]    block    Block to be executed if the pattern matches
		#
		# @return [void]
		def with(*pattern, &block)
			guard = if pattern.last.is_a?(Proc) then pattern.pop end

			pattern = Filigree::wrap_pattern_elements(pattern)

			@patterns << (mp = OuterPattern.new(pattern, guard, block))

			if block
				@deferred.each { |pattern| pattern.block = block }
				@deferred.clear

			else
				@deferred << mp
			end
		end
		alias :w :with

		#############
		# Callbacks #
		#############

		# Callback used to generate wildcard and binding patterns
		def method_missing(name, *args)
			if args.empty?
				if name == :_ then WildcardPattern.instance else BindingPattern.new(name) end
			else
				super(name, *args)
			end
		end
	end

	# This class provides the basis for all match patterns.
	class BasicPattern
		extend  AbstractClass
		include Comparable

		# Base implementation of bi-directional comparison for patterns.
		#
		# @param [BasicPattern]  other  Right-hand side of the comparison
		#
		# @return [Integer]  Value corresponding to less than, equal to, or
		#   greater than the right-hand side pattern.
		def <=>(other)
			# This is performed in the non-intuitive order due to
			# higher-priority patterns having lower weights.
			other.weight - self.weight
		end

		# Wraps this pattern in a {BindingPattern}, causing the object that
		# this pattern matches to be bound to this name in the with block.
		#
		# @param [BindingPattern]  binding_pattern  Binding pattern containing the name
		def as(binding_pattern)
			binding_pattern.tap { |bp| bp.pattern_elem = self }
		end
	end

	# A pattern that matches any object
	class WildcardPattern < BasicPattern
		include Singleton

		# Return true for any object and don't create any bindings.
		#
		# @return [true]
		def match?(_, _)
			true
		end

		def weight
			4
		end
	end

	# An abstract class that matches only a single object to a single pattern.
	class SingleObjectPattern < BasicPattern
		extend AbstractClass

		# @return [BasicPattern]
		attr_reader :pattern_elem

		# Create a new pattern with a single element.
		#
		# @param [Object]  pattern_elem  Object representing the pattern
		def initialize(pattern_elem)
			@pattern_elem = pattern_elem
		end
	end

	# A pattern for checking to see if an object is an instance of a given
	# class.
	class InstancePattern < SingleObjectPattern
		# Specialized version of the bi-directional comparison operator.
		#
		# @param [BasicPattern]  other  Right-hand side of the comparison
		#
		# @return [-1, 0, 1]  Value corresponding to less than, equal to, or
		#   greater than the right-hand side pattern.
		def <=>(other)
			if other.is_a?(InstancePattern)
				if    self.pattern_elem == other.pattern_elem            then 0
				elsif self.pattern_elem.subclass_of?(other.pattern_elem) then 1
				else                                                         -1
				end
			else
				super(other)
			end
		end

		# Test the object to see if the object is an instance of the given
		# class.
		#
		# @param [Object]  object  Object to test pattern against
		#
		# @return [Boolean]
		def match?(object, _)
			object.is_a?(@pattern_elem)
		end

		def weight
			3
		end
	end

	# A pattern that forces an equality comparison
	class LiteralPattern < SingleObjectPattern
		# Test the object for equality to the pattern element.
		#
		# @param [Object]  object  Object to test pattern against
		#
		# @return [Boolean]
		def match?(object, _)
			object == @pattern_elem
		end

		def weight
			0
		end
	end

	# A pattern that tests a string against a regular expression.
	class RegexpPattern < SingleObjectPattern
		# Test the object to see if it matches the wrapped regular
		# expression.
		#
		# @param [Object]  object  Object to test pattern against
		# @param [Object]  env     Binding environment
		#
		# @return [Boolean]
		def match?(object, env)
			(object.is_a?(String) and (md = @pattern_elem.match(object))).tap do |match|
				env.send("match_data=", md) if match
			end
		end

		def weight
			2
		end
	end

	# A pattern that binds a sub-pattern's matching object to a name in the
	# binding environment.
	class BindingPattern < SingleObjectPattern

		attr_writer :pattern_elem

		# Create a new binding pattern.
		#
		# @param  [Symbol]  name          Name to bind to
		# @param  [Object]  pattern_elem  Sub-pattern
		def initialize(name, pattern_elem = WildcardPattern.instance)
			@name = name
			super(pattern_elem)
		end

		# Overridden method to prevent binding BindingPattern objects.
		def as(_, _)
			raise 'Binding a BindingPattern is not allowed.'
		end

		# Test the object for equality to the pattern element.  Binds the
		# object to the binding pattern's name if it does match.
		#
		# @param [Object]  object  Object to test pattern against
		# @param [Object]  env     Binding environment
		#
		# @return [Boolean]
		def match?(object, env)
			@pattern_elem.match?(object, env).tap { |match| env.send("#{@name}=", object) if match }
		end

		def weight
			@pattern_elem.weight
		end
	end

	# An abstract class that matches multiple objects to multiple patterns.
	class MultipleObjectPattern < BasicPattern
		extend AbstractClass

		# @return [Array<BasicPattern>]
		attr_reader :pattern

		# Create a new pattern with multiple elements.
		#
		# @param [Array<Object>]  pattern  Array of pattern elements
		def initialize(pattern)
			@pattern = pattern
		end

		# A wrapper method to sort MultipleObjectPattern objects by their
		# arity.
		#
		# @param [BasicPattern]  other  Right-hand side of the comparison
		#
		# @return [Integer]  Value corresponding to less than, equal to, or
		#   greater than the right-hand side pattern.
		def base_compare(other)
			if self.pattern.length == other.pattern.length
				yield
			else
				self.pattern.length - other.pattern.length
			end
		end

		# Test multiple objects against multiple pattern elements.
		#
		# @param [Object]  objects  Object to test pattern against
		#
		# @return [Boolean]
		def match?(objects, env)
			if objects.length == @pattern.length
				@pattern.zip(objects).each do |pattern_elem, object|
					return false unless pattern_elem.match?(object, env)
				end

				true

			else
				(@pattern.length == 1 and @pattern.first == WildcardPattern.instance)
			end
		end
	end

	# The class that contains all of the pattern elements passed to a with clause.
	class OuterPattern < MultipleObjectPattern
		attr_writer :block
		attr_reader :guard

		# Specialized version of the bi-directional comparison operator.
		#
		# @param [BasicPattern]  other  Right-hand side of the comparison
		#
		# @return [-1, 0, 1]  Value corresponding to less than, equal to, or
		#   greater than the right-hand side pattern.
		def <=>(other)
			base_compare(other) do
				comp_res =
				self.pattern.zip(other.pattern).inject(0) do |total, pair|
					total + (pair.first <=> pair.last)
				end <=> 0

				if comp_res == 0
					self.guard ? (other.guard ? 0 : 1) : (other.guard ? -1 : comp_res)
				else
					comp_res
				end
			end
		end

		# Create a new outer pattern with the given pattern elements, guard,
		# and block.
		#
		# @param [Array<Object>]  pattern  Pattern elements
		# @param [Proc]           guard    Guard clause that is tested if the pattern matches
		# @param [Proc]           block    Block to be evaluated if the pattern matches
		def initialize(pattern, guard, block)
			super(pattern)
			@guard = guard
			@block = block
		end

		# Call the pattern's block, passing the given objects to the block.
		#
		# @param [Object]         env      Environment in which to evaluate the block
		# @param [Array<Object>]  objects  Arguments to the block
		def call(env, objects = [])
			if @block then env.instance_exec(*objects, &@block) else nil end
		end

		# Test the objects for equality to the pattern elements.
		#
		# @param [Object]  objects  Objects to test pattern elements against
		# @param [Object]  env      Binding environment
		#
		# @return [Boolean]
		def match?(objects, env)
			super && (@guard.nil? or env.instance_exec(&@guard))
		end
	end

	# A pattern that matches an instance of a class and destructures it so
	# that the values contained by the object may be matched upon.
	class DestructuringPattern < MultipleObjectPattern

		# @return [Class]
		attr_reader :klass

		# Specialized version of the bi-directional comparison operator.
		#
		# @param [BasicPattern]  other  Right-hand side of the comparison
		#
		# @return [Integer]  Value corresponding to less than, equal to, or
		#   greater than the right-hand side pattern.
		def <=>(other)
			if other.is_a?(DestructuringPattern)
				if self.klass == other.klass
					base_compare(other) do
						self.pattern.zip(other.pattern).inject(0) do |total, pair|
							total + (pair.first <=> pair.last)
						end / self.pattern.length
					end

				elsif self.klass.subclass_of?(other.klass) then  1
				else                                            -1
				end

			else
				super
			end
		end

		# Create a new destructuring pattern.
		#
		# @param [Class]   klass    Class to match instances of.  It must be destructurable.
		# @param [Object]  pattern  Pattern elements to use in matching the object's values
		def initialize(klass, pattern)
			@klass = klass
			super(pattern)
		end

		# Test to see if the object is an instance of the appropriate class,
		# and if so destructure it and test it's values against the
		# sub-pattern elements.
		#
		# @param [Object]  object  Object to test pattern against
		# @param [Object]  env     Binding environment
		#
		# @return [Boolean]
		def match?(object, env)
			object.is_a?(@klass) and super(object.destructure(@pattern.length), env)
		end

		def weight
			1
		end
	end
end

###################################
# Standard Library Deconstructors #
###################################

class Array
	extend Filigree::Destructurable

	# Destructuring for the array class.  If the array is being matched
	# against two patterns the destructuring of the array will be the first
	# element and then an array containing the rest of the values.  If there
	# are three patterns the destructuring of the array will be the first and
	# second elements, and then an array containing the remainder of the
	# values.
	#
	# @param [Fixnum]  num_elems  Number of sub-pattern elements
	#
	# @return [Array<Object>]
	def destructure(num_elems)
		[*self.first(num_elems - 1), self[(num_elems - 1)..-1]]
	end
end

class Class
	# Causes an instance of a class to be bound the the given name.
	#
	# @param [BindingPattern]  binding_pattern  Name to bind the instance to
	def as(binding_pattern)
		binding_pattern.tap { |bp| bp.pattern_elem = Filigree::InstancePattern.new(self) }
	end
end

class Regexp
	# Causes a string matching the regular expression to be bound the the
	# given name.
	#
	# @param [BindingPattern]  binding_pattern  Name to bind the instance to
	def as(binding_pattern)
		binding_pattern.tap { |bp| bp.pattern_elem = Filigree::RegexpPattern.new(self) }
	end
end

class Symbol
	# Turns a symbol into a binding pattern.
	#
	# @return [Filigree::BindingPattern]
	def !
		Filigree::BindingPattern.new(self)
	end
end
