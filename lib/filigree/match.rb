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

##########
# Errors #
##########

class MatchError < RuntimeError; end

###########
# Methods #
###########

def match(*objects, &block)
	me = Filigree::MatchEnvironment.new
	
	me.instance_exec &block
	
	me.find_match(objects)
end

#######################
# Classes and Modules #
#######################

module Filigree
	module Destructurable
		def call(*pattern)
			DestructuringPattern.new(self, *pattern)
		end
	end

	class MatchEnvironment
		def Bind(name)
			BindingPattern.new(name)
		end
	
		def Literal(obj)
			LiteralPattern.new(obj)
		end

		def initialize
			@patterns = Array.new
			@deferred = Array.new
		end
	
		def find_match(objects)
			@patterns.each do |pattern|
				env = OpenStruct.new 
			
				return pattern.(env, objects) if pattern.match?(objects, env)
			end
		
			# If we didn't find anything we raise a MatchError.
			raise MatchError
		end
	
		def with(*pattern, &block)
			guard = if pattern.last.is_a?(Proc) then pattern.pop end 
		
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
	
		def method_missing(name, *args)
			if args.empty?
				if name == :_ then WildcardPattern.instance else BindingPattern.new(name) end
			else
				super(name, *args)
			end
		end
	end

	class BasicPattern
		extend AbstractClass
	
		def as(binding_pattern)
			binding_pattern.tap { |bp| bp.pattern_elem = self }
		end
	
		def match_pattern_element(pattern_elem, object, env)
			case pattern_elem
			when Class
				object.is_a?(pattern_elem)
			
			when Regexp
				object.is_a?(String) and pattern_elem.match(object)
			
			when BasicPattern
				pattern_elem.match?(object, env)
				 
			else
				object == pattern_elem
			end
		end
	end

	class WildcardPattern < BasicPattern
		include Singleton
	
		def match?(_, _)
			true
		end
	end

	class SingleObjectPattern < BasicPattern
		extend AbstractClass
	
		def initialize(pattern_elem)
			@pattern_elem = pattern_elem
		end
	
		def match?(object, env)
			match_pattern_element(@pattern_elem, object, env)
		end
	end

	class LiteralPattern < SingleObjectPattern
		def match?(object, _)
			object == @pattern_elem
		end
	end

	class BindingPattern < SingleObjectPattern
		attr_accessor :pattern_elem
	
		def initialize(name, pattern_elem = nil)
			@name = name
			super(pattern_elem)
		end
	
		def match?(object, env)
			(@pattern_elem.nil? or super).tap do |match|
				env.send("#{@name}=", object) if match
			end
		end
	end

	class MultipleObjectPattern < BasicPattern
		extend AbstractClass
	
		def initialize(pattern)
			@pattern = pattern
		end
	
		def match?(objects, env)
			if objects.length == @pattern.length
				@pattern.zip(objects).each do |pattern_elem, object|
					return false unless match_pattern_element(pattern_elem, object, env)
				end
			
				true
			
			else
				(@pattern.length == 1 and @pattern.first == WildcardPattern.instance)
			end
		end
	end

	class OuterPattern < MultipleObjectPattern
		attr_writer :block
	
		def initialize(pattern, guard, block)
			super(pattern)
			@guard = guard
			@block = block
		end
	
		def call(env, objects = [])
			if @block then env.instance_exec(*objects, &@block) else nil end
		end
	
		def match?(objects, env)
			super && (@guard.nil? or env.instance_exec(&@guard))
		end
	end

	class DestructuringPattern < MultipleObjectPattern
		def initialize(klass, *pattern)
			@klass = klass
			super(pattern)
		end
	
		def match?(object, env)
			object.is_a?(@klass) and super(object.destructure(@pattern.length), env)
		end
	end
end

###################################
# Standard Library Deconstructors #
###################################

class Array
	extend Filigree::Destructurable

	def destructure(num_names)
		[*self.first(num_names - 1), self[(num_names - 1)..-1]]
	end
end

class Class
	def as(binding_pattern)
		binding_pattern.tap { |bp| bp.pattern_elem = self }
	end
end

class Fixnum
	extend Filigree::Destructurable

	def destructure(_)
		[self]
	end
end

class Float
	extend Filigree::Destructurable

	def destructure(_)
		[self]
	end
end

class String
	extend Filigree::Destructurable

	def destructure(_)
		[self]
	end
end
