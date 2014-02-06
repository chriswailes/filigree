# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/04
# Description:	Additional features for Arrays.

############
# Requires #
############

# Standard Library

# Filigree

#######################
# Classes and Modules #
#######################

class Array
	alias :aliased_map :map
	
	def map(method = nil, &block)
		if method
			self.aliased_map { |obj| obj.send(method) }
		else
			self.aliased_map(&block)
		end
	end
end
