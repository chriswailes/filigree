# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/04
# Description:	Pattern matching for Ruby.

############
# Requires #
############

# Standard Library

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

class MatchEnvironment
	def initialize
		@patterns = Array.new
		@deferred = Array.new
	end
	
	def find_match(objects)
		found	= false
		result	= nil
		
		@patterns.each do |pattern|
			if found = pattern.match?(objects)
				result = pattern.(objects)
				break
			end
		end
		
		if found then result else raise MatchError end
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
end

class MatchPattern
	attr_writer :block
	
	def initialize(pattern, guard, block)
		@pattern	= pattern
		@guard	= guard
		@block	= block
	end
	
	def call(objects)
		@block.(*objects)
	end
	
	def match?(objects)
		if objects.length == @pattern.length
			objects.zip(@pattern).inject(nil) do |_, pair|
				o, p = pair
				
				if p == :_ || o == p then true else break false end
			end
			
		else
			@pattern.length == 1 and @pattern.first == :_
		end && (@guard.nil? or @guard.(*objects))
	end
end

