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
	me = MatchEnvironment.new
	
	me.instance_exec &block
	
	me.find_match(objects)
end

#######################
# Classes and Modules #
#######################

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
		
		@patterns << (mp = MatchPattern.new(pattern, guard, block))
		
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
			if name == :_ then Wildcard.instance else BindingPattern.new(name) end
		else
			super(name, *args)
		end
	end
end

class Wildcard
	include Singleton
end

class BasicPattern
	extend AbstractClass
	
	def as(binding_pattern)
		binding_pattern.tap { |bp| bp.pattern = self }
	end
	
	def initialize(*pattern)
		@pattern = pattern
	end
	
	def match?(objects, env)
		if objects.length == @pattern.length
			@pattern.zip(objects).each do |pattern, object|
				return false unless match_prime(pattern, object, env)
			end
			
			true
			
		else
			(@pattern.length == 1 and @pattern.first == Wildcard.instance)
		end
	end
	
	def match_prime(pattern, object, env)
		case pattern
		when Wildcard
			true
			
		when Class
			object.is_a?(pattern)
			
		when Regexp
			object.is_a?(String) and pattern.match(object)
			
		when BasicPattern
			pattern.match?(object, env)
			 
		else
			object == pattern
		end
	end
	private :match_prime
end

class BindingPattern < BasicPattern
	attr_accessor :pattern
	
	def initialize(name, pattern = nil)
		@name    = name
		@pattern = pattern
	end
	
	def match?(object, env)
		(@pattern.nil? or match_prime(@pattern, object, env)).tap do |match|
			env.send("#{@name}=", object) if match
		end
	end
end

class DestructuringPattern < BasicPattern
	def initialize(klass, *pattern)
		super(*pattern)
		
		@klass = klass
	end
	
	def match?(object, env)
		object.is_a?(@klass) and super(object.destructure(@pattern.length), env)
	end
end

class LiteralPattern < BasicPattern
	def initialize(pattern)
		@pattern = pattern
	end
	
	def match?(object, _)
		object == @pattern
	end
end

class MatchPattern < BasicPattern
	attr_writer :block
	
	def initialize(pattern, guard, block)
		super(*pattern)
		
		@guard = guard
		@block = block
	end
	
	def call(env, objects = [])
		if @block then env.instance_exec(*objects, &@block) else nil end
	end
	
	def match?(objects, env)
		super(objects, env) and (@guard.nil? or env.instance_exec(&@guard))
	end
end

###################################
# Standard Library Deconstructors #
###################################

class Array
	extend Destructurable
	
	def destructure(num_names)
		[*self.first(num_names - 1), self[(num_names - 1)..-1]]
	end
end

class Class
	def as(binding_pattern)
		binding_pattern.tap { |bp| bp.pattern = self }
	end
end

class Fixnum
	extend Destructurable
	
	def destructure(_)
		[self]
	end
end

class Float
	extend Destructurable
	
	def destructure(_)
		[self]
	end
end

class String
	extend Destructurable
	
	def destructure(_)
		[self]
	end
end
