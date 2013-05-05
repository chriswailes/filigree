# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/04
# Description:	Class extensions for dealing with integers and booleans.

############
# Requires #
############

# Standard Library

# Filigree

#######################
# Classes and Modules #
#######################

# Extra boolean support for the Integer class.
class Integer
	# @return [Boolean] This Integer as a Boolean value.
	def to_bool
		self != 0
	end
end

# Extra boolean support for the TrueClass class.
class TrueClass
	# @return [1]
	def to_i
		1
	end
end

# Extra boolean support for the FalseClass class.
class FalseClass
	# @return [0]
	def to_i
		0
	end
end
