# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/4/19
# Description:	

############
# Requires #
############

# Standard Library

# Filigree

#######################
# Classes and Modules #
#######################

# Object class extras.
class Object
	# Simple implementation of the Y combinator.
	#
	# @param [Object] value Value to be returned after executing the provided block.
	#
	# @return [Object] The object passed in parameter value.
	def returning(value)
		yield(value)
		value
	end
end
