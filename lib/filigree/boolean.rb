# Author:      Chris Wailes <chris.wailes@gmail.com>
# Project:     Filigree
# Date:        2013/05/04
# Description: Class extensions for dealing with integers and booleans.

############
# Requires #
############

# Standard Library

# Filigree

#######################
# Classes and Modules #
#######################

module Filigree

	# Extra boolean support for the Integer class.
	refine Integer do
		# @return [Boolean] This Integer as a Boolean value.
		def to_bool
			self != 0
		end
	end

	# Extra boolean support for the TrueClass class.
	refine TrueClass do
		# @return [1]
		def to_i
			1
		end
	end

	# Extra boolean support for the FalseClass class.
	refine FalseClass do
		# @return [0]
		def to_i
			0
		end
	end
end
