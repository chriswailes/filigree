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

def match(object, &block)
	me = MatchEnvironment.new
	
	me.instance_exec &block
	
	me.find_match object
end

#######################
# Classes and Modules #
#######################

class MatchEnvironment
	def initialize
		@patterns = Array.new
	end
	
	def find_match(object)
		found	= false
		result	= nil
		
		@patterns.each do |pattern|
			if found = pattern.match?(object)
				result = pattern.(object)
				break
			end
		end
		
		if found then result else raise MatchError end
	end
	
	def with(pattern, guard = nil, &block)
		@patterns << MatchPattern.new(pattern, guard, block)
	end
end

class MatchPattern
	def initialize(pattern, guard, block)
		@pattern	= pattern
		@guard	= guard
		@block	= block
	end
	
	def call(object)
		@block.(object)
	end
	
	def match?(object)
		(@pattern == :_ || object == @pattern) and (@guard.nil? or @guard.(object))
	end
end

