# Author:      Chris Wailes <chris.wailes+filigree@gmail.com>
# Project:     Filigree
# Date:        2013/05/04
# Description: Additional features for all objects.

############
# Requires #
############

# Standard Library

# Filigree

###########
# Methods #
###########

# Simple implementation of the Y combinator.
#
# @param [Object] value Value to be returned after executing the provided block.
#
# @return [Object] The object passed in parameter value.
def returning(value)
	yield(value)
	value
end

#######################
# Classes and Modules #
#######################

module Filigree

	# Object class extras.
	refine Object do
		# A copy and modification helper.
		#
		# @return [Object] A copy of the object with the block evaluated in the context of the copy.
		def clone_with(&block)
			self.clone.tap { |clone| clone.instance_exec(&block) }
		end
	end
end
