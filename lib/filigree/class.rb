# Author:      Chris Wailes <chris.wailes+filigree@gmail.com>
# Project:     Filigree
# Date:        2013/05/04
# Description: Class extensions for the Class class.

############
# Requires #
############

# Standard Library

# Filigree
require 'filigree/types'

#######################
# Classes and Modules #
#######################

module Filigree

	refine Class do
		# Checks for module inclusion.
		#
		# @param [Module]  mod  Module to check the inclusion of.
		#
		# @return [Boolean]  If the module was included
		def includes_module?(mod)
			self.included_modules.include?(mod)
		end

		# @return [String]  Name of class without the namespace.
		def short_name
			self.name.split('::').last
		end

		# Checks to see if a Class object is a subclass of the given class.
		#
		# @param [Class]  klass  Class we are checking if this is a subclass of.
		#
		# @return [Boolean]  If self is a subclass of klass
		def subclass_of?(klass)
			check_type(klass, Class, blame: 'klass')

			if (superklass = self.superclass)
				superklass == klass or superklass.subclass_of?(klass)
			else
				false
			end
		end
	end
end
