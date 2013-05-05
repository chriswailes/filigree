# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/04
# Description:	Class extensions for the Class class.

############
# Requires #
############

# Standard Library

# Filigree

#######################
# Classes and Modules #
#######################

class Class
	# Checks for module inclusion.
	#
	# @param [Module] mod Module to check the inclusion of.
	def includes_module?(mod)
		self.included_modules.include?(mod)
	end
	
	# @return [String] Name of class without the namespace.
	def short_name
		self.name.split('::').last
	end
	
	# Checks to see if a Class object is a subclass of the given class.
	#
	# @param [Class] klass Class we are checking if this is a subclass of.
	def subclass_of?(klass)
		raise 'The klass parameter must be an instance of Class.' if not klass.is_a?(Class)
		
		if (superklass = self.superclass)
			superklass == klass or superklass.subclass_of?(klass)
		else
			false
		end
	end
end
