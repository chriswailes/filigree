# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/15
# Description:	A module to automatically extend classes with an inner module.

############
# Requires #
############

# Standard Library

# Filigree

##########
# Errors #
##########

###########
# Methods #
###########

#######################
# Classes and Modules #
#######################

module ClassMethodsModule
	def self.included(mod)
		mod.instance_exec do
			def included(mod)
				mod.extend self::ClassMethods
			end
		end
	end
end
