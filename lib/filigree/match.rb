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
	
	me.find_match objects
end

#######################
# Classes and Modules #
#######################

module Deconstructable
	def call(*pattern)
		DeconstructionPattern.new(self, pattern)
	end
end

class MatchEnvironment
	def initialize
		@patterns = Array.new
		@deferred = Array.new
	end
	
	def find_match(objects)
#		puts
#		puts 'Finding match for:'
#		pp objects
		
		@patterns.each do |pattern|
#			puts
#			puts 'Considering pattern:'
#			pp pattern
			
			env = OpenStruct.new 
			
			if pattern.match?(objects, env)
#				puts 'Pattern matched.'
				
				return pattern.(env, objects)
			else
#				puts "Pattern didn't match."
			end
		end
		
		# If we didn't find anything we raise a MatchError.
		raise MatchError
	end
	
	def with(*pattern, &block)
		guard = if pattern.last.is_a?(Proc) then pattern.pop end 
		
		@patterns << (mp = MatchPattern.new(pattern, guard, block))
		
		if block
			@deferred.each { |p| p.block = block }
			@deferred.clear
			
		else
			@deferred << mp
		end
	end
	
	#############
	# Callbacks #
	#############
	
	def method_missing(name, *args)
		if args.empty?
			if name == :_ then Wildcard.instance else MatchBinding.new(name) end
		else
			super(name, *args)
		end
	end
end

class BasicPattern
	def initialize(pattern)
		@pattern = pattern
	end
	
	def match?(objects, env = OpenStruct.new)
		result = true
		
		if objects.length == @pattern.length
			@pattern.zip(objects).each do |pattern, object|
				ok = match_prime(pattern, object, env)
				
				if not ok
					result = false
					break
				end
			end
			
			result
			
		else
			(@pattern.length == 1 and @pattern.first == Wildcard.instance)
		end
	end
	
	def match_prime(pattern, object, env)
		case pattern
		when Wildcard
			true
			
		when Regexp
			object.is_a?(String) and pattern.match(object)
			
		when MatchBinding
			pattern.match?(object, env).tap { |match| env.send("#{pattern.name}=", object) if match }
			 
		when DeconstructionPattern
			pattern.match?(object, env)
			 
		else
			object == pattern
		end
	end
end

class DeconstructionPattern < BasicPattern
	attr_reader :klass
	
	def initialize(klass, pattern)
		super(pattern)
		
		@klass = klass
	end
	
	def match?(object, env = OpenStruct.new)
#		puts 'Testing DeconstructionPattern:'
#		pp self
#		
#		puts 'On object:'
#		pp object
#		
#		puts "Object is of correct class: #{object.is_a?(@klass)}"
#		puts "Object is deconstructable : #{object.respond_to?(:deconstruct)}"
		
		object.is_a?(@klass) && object.respond_to?(:deconstruct) && super(object.deconstruct, env)
	end
end

class MatchPattern < BasicPattern
	attr_writer :block
	
	def initialize(pattern, guard, block)
		super(pattern)
		
		@guard = guard
		@block = block
	end
	
	def call(env, objects)
		env.instance_exec(&@block)
	end
	
	def match?(objects, env = OpenStruct.new)
#		puts 'Checking MatchPattern:'
#		pp self
#		
#		puts 'On objects:'
#		pp objects
		
		super(objects, env) && (@guard.nil? or env.instance_exec(&@guard))
	end
end

class Wildcard
	include Singleton
end

class MatchBinding
	attr_accessor :name
	attr_accessor :pattern
	
	def initialize(name, pattern = nil)
		@name	= name
		@pattern	= pattern
	end
	
	def match?(object, env = OpenStruct.new)
		@pattern.nil? or @pattern.match?(object, env)
	end
end

