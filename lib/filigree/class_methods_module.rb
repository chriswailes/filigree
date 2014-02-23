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

module Filigree
	# Including this in a module will cause any class that includes the client
	# module to also extend itself with the <client module>::ClassMethods module.
	# If this module is not defined a NameError will be thrown when the client
	# module is included.
	module Filigree::ClassMethodsModule
		def self.included(mod)
			mod.instance_exec do
				def included(mod)
					mod.extend self::ClassMethods
				end
			end
		end
	end
end
