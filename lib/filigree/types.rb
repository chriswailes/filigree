# Author:      Chris Wailes <chris.wailes+filigree@gmail.com>
# Project:     Filigree
# Date:        2013/05/04
# Description: Extensions to help with type checking.

############
# Requires #
############

# Standard Library

# Filigree
require 'filigree/class_methods_module'

###########
# Methods #
###########

# A method for type checking Ruby values.
#
# @param [Object]       obj       Object to type check
# @param [Class]        type      Class the object should be an instance of
# @param [String, nil]  blame     Variable name to blame for failed type checks
# @param [Boolean]      nillable  Object can be nil?
# @param [Boolean]      strict    Strict or non-strict checking.  Uses `instance_of?` and `is_a?` respectively
#
# @raise [ArgumentError]  An error is raise if the type checking fails.
#
# @return [Object]  The object passed as parameter obj
def check_type(obj, type, blame: nil, nillable: false, strict: false)
	type_ok = (obj.nil? && nillable) || (strict ? obj.instance_of?(type) : obj.is_a?(type))

	if type_ok
		obj
	elsif blame
		raise TypeError,
			"Parameter #{blame} must be an instance of the #{type.name} class.  Received an instance of #{obj.class.name}."
	else
		raise TypeError,
			"Expected an object of type #{type.name}.  Received an instance of #{obj.class.name}."
	end
end

# A method for type checking Ruby array values.
#
# @param [Array<Object>]  array     Array of objects to type check.
# @param [Class]          type      Class the objects should be an instance of.
# @param [String, nil]    blame     Variable name to blame for failed type checks.
# @param [Boolean]        nillable  Object can be nil?
# @param [Boolean]        strict    Strict or non-strict checking.  Uses `instance_of?` and `is_a?` respectively.
#
# @raise [ArgumentError]  An error is raise if the type checking fails
#
# @return [Object]  The object passed in parameter array
def check_array_type(array, type, blame: nil, nillable: false, strict: false)
	array.each do |obj|
		type_ok = (obj.nil? && nillable) || (strict ? obj.instance_of?(type) : obj.is_a?(type))

		if not type_ok
			if blame
				raise TypeError, "Parameter #{blame} must contain instances of the #{type.name} class."
			else
				raise TypeError, "Expected an object of type #{type.name}."
			end
		end
	end
end

# A method for checking enum membership for a Symbol.
#
# @param [Symbol]         sym       Symbol to check for enum membership
# @param [Array<Symbol>]  enum_set  The symbols that comprise the set of enumerable values
# @param [String, nil]    blame     Variable name to blame for failed enum checks
# @param [Boolean]        nillable  Symbol can be nil?
def check_enum_type(sym, enum_set, blame: nil, nillable: false)
	check_type(sym, Symbol, blame: 'sym', nillable: nillable)
	check_array_type(enum_set, Symbol, blame: 'enum_set', nillable: false)

	if enum_set.include?(sym)
		sym
	elsif blame
		raise TypeError,
			"Parameter #{blame} (#{sym}) is not a member of the provided enum set: #{enum_set}"
	else
		raise TypeError,
			"Symbol #{sym} is not a member of the provided enum set: #{enum_set}"
	end
end

#######################
# Classes and Modules #
#######################

module Filigree
	# Allows the including class to define typed type checked instance
	# variables.  This also provides a default constructor.
	module TypedClass
		include ClassMethodsModule

		# Set each of the typed instance variables to its corresponding
		# value.
		#
		# @param [Array<Object>]  vals  Values to set typed variables to
		#
		# @return [void]
		def set_typed_ivars(vals)
			self.class.typed_ivars.zip(vals).each do |name, val|
				self.send("#{name}=", val)
			end
		end

		module ClassMethods
			# Define the default constructor for the including class.
			#
			# @param [Boolean]  strict  To use strict checking or not
			#
			# @return [void]
			def default_constructor(strict = false)
				class_eval do
					if strict
						def initialize(*vals)
							if self.class.typed_ivars.length != vals.length
								raise ArgumentError, "#{self.class.typed_ivars.length} arguments expected, #{vals.length} given."
							end

							self.set_typed_ivars(vals)
						end
					else
						def initialize(*vals)
							self.set_typed_ivars(vals)
						end
					end
				end
			end

			# Define a new typed accessor.
			#
			# @param [Symbol]   name      Name of the accessor
			# @param [Boolean]  nillable  If the value can be nil or not
			# @param [Boolean]  strict    To use strict checking or not
			# @param [Class]    type      Type of the accessor
			# @param [Proc]     checker   Method used to check the type
			#
			# @return [void]
			def define_typed_accessor(name, nillable, strict, type, checker)
				define_method "#{name}=" do |obj|
					self.instance_variable_set("@#{name}", checker.call(obj, type, blame: name, nillable: nillable, strict: strict))
				end
			end
			private :define_typed_accessor

			# Define a typed instance variable.
			#
			# @param [Symbol]   name      Name of the accessor
			# @param [Class]    type      Type of the accessor
			# @param [Boolean]  nillable  If the value can be nil or not
			# @param [Boolean]  strict    To use strict checking or not
			#
			# @return [void]
			def typed_ivar(name, type, nillable: false, strict: false)
				typed_ivars << name

				define_typed_accessor(name, nillable, strict, *
					type.is_a?(Array) ? [type.first, method(:check_array_type)] : [type, method(:check_type)])

				attr_reader name
			end

			# Return the typed instance variables for an object.
			#
			# @return [Array<Symbol>]  Array of defined typed instance variables
			def typed_ivars
				@typed_ivars ||= Array.new
			end
		end
	end
end
