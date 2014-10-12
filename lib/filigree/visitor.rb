# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2014/02/11
# Description:	An implementation of the Visitor pattern.

############
# Requires #
############

# Standard Library

# Filigree
require 'filigree/class_methods_module'
require 'filigree/match'

#######################
# Classes and Modules #
#######################

module Filigree
	# An implementation of the Visitor pattern.
	module Visitor

		include ClassMethodsModule

		####################
		# Instance Methods #
		####################

		# Find the correct pattern and execute its block on the provided
		# objects.
		#
		# @param [Object]  objects  Objects to pattern match.
		#
		# @return [Object]  Result of calling the matched pattern's block
		#
		# @raise [MatchError]  Raised when no matching pattern is found
		def visit(*objects)
			# FIXME: A dirty hack.  Find a better place to initialize this.
			@match_bindings ||= Array.new

			@match_bindings.push OpenStruct.new

			self.class.patterns.each do |pattern|

				# FIXME: Make these take their arguments in the same order
				if pattern.match?(objects, self)
					result = pattern.(self, objects)
					@match_bindings.pop
					return result
				end
			end

			@match_bindings.pop

			if self.class.strict_match?
				# If we didn't find anything we raise a MatchError.
				raise MatchError
			else
				nil
			end
		end

		#############
		# Callbacks #
		#############

		# This is used to get and set binding names
		def method_missing(name, *args)
			if args.empty? and @match_bindings.last.respond_to?(name)
				@match_bindings.last.send(name)
			elsif name.to_s[-1] == '=' and args.length == 1
				@match_bindings.last.send(name, *args)
			else
				super(name, *args)
			end
		end

		#################
		# Class Methods #
		#################

		module ClassMethods

			attr_reader :patterns

			# Force a name binding.
			#
			# @param [Symbol]  name  Name to bind to
			#
			# @return [BindingPattern]
			def Bind(name)
				BindingPattern.new(name)
			end

			# Force a literal comparison.
			#
			# @param [Object]  obj  Object to be comapred against
			#
			# @return [LiteralPattern]
			def Literal(obj)
				LiteralPattern.new(obj)
			end

			# Inserts a new pattern in the appropriate place in the patterns
			# list.
			#
			# @param [OuterPattern]  new_pat  New pattern to add
			#
			# @return [void]
			def add_pattern(new_pat)
				@patterns.each_with_index do |old_pat, index|
					if new_pat > old_pat
						@patterns.insert(index, new_pat)
						return
					end
				end

				@patterns << new_pat
			end

			# A callback used to pass patterns declared in a parent class to
			# a subclass.
			#
			# @param [Class]  klass  Subclass
			#
			# @return [void]
			def inherited(klass)
				klass.install_icvars(@patterns.clone)
			end

			# Install the instance class variables in the including class.
			#
			# @return [void]
			def install_icvars(inherited_patterns = Array.new)
				@patterns     = inherited_patterns
				@deferred     = Array.new
				@strict_match = false
			end

			# Define a pattern for this visitor.
			#
			# @see match  Pattern matching description
			#
			# @param [Object]  pattern  List of pattern elements
			# @param [Proc]    block    Block to be executed when the pattern is matched
			#
			# @return [void]
			def on(*pattern, &block)
				guard = if pattern.last.is_a?(Proc) then pattern.pop end

				pattern = Filigree::wrap_pattern_elements(pattern)
				add_pattern (mp = OuterPattern.new(pattern, guard, block))

				if block
					@deferred.each { |pattern| pattern.block = block }
					@deferred.clear

				else
					@deferred << mp
				end
			end

			# Tell the visitor that it must raise an exception if no match is
			# found.
			#
			# @param [Boolean]  bool  Raise an exception or not.
			#
			# @return [void]
			def strict_match(bool)
				@strict_match = bool
			end

			# Accessor for the strict match member.
			#
			# @return [Boolean] The value of the class's @strict_match
			#                   instance variable.
			def strict_match?
				@strict_match
			end

			#############
			# Callbacks #
			#############

			# Used to generate wildcard and binding patterns.
			def method_missing(name, *args)
				if args.empty?
					if name == :_ then WildcardPattern.instance else BindingPattern.new(name) end
				else
					super(name, *args)
				end
			end

			def self.extended(klass)
				klass.install_icvars
			end
		end
	end

	# This class can be used to call multiple visitors on an object at once.
	# This could potentialy reduce the number of times data structures are
	# traversed.
	class TourGuide
		attr_reader :visitors

		# Call each visitor on the specified objects.
		#
		# @param [Object]  objects  Objects to be visited
		#
		# @return [Array<Visitor>]  The wrapped visitors
		def visit(*objects)
			@visitors.each { |visitor| visitor.visit(*objects) }
		end

		# Construct a tour guide for a list of visitors.
		#
		# @param [Visitor]  visitors  List of visitors
		def initialize(*visitors)
			@visitors = visitors
		end
	end

	# This module provides a default implementation of three common traversal
	# patterns: pre-order, post-order, and in-order (level-order).  The
	# including class must implement the `children` function.
	module Visitable

		# Visit this object with the provided visitor in pre-, post-, or
		# in-order traversal.
		#
		# @param [Visitor]                          visitor  Visitor to call
		# @param [:preorder, :inorder, :postorder]  method   How to visit
		#
		# @return [void]
		def visit(visitor, method = :preorder)
			case method
			when :preorder
				visitor.visit(self)
				children.compact.each { |child| child.visit(visitor, :preorder) }

			when :inorder
				nodes = [self]

				while node = nodes.shift
					nodes += node.children.compact
					visitor.visit(node)
				end

			when :postorder
				children.compact.each { |child| child.visit(visitor, :postorder) }
				visitor.visit(self)
			end
		end
	end
end
