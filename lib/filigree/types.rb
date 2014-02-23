# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/04
# Description:	Extensions to help with type checking.

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
# @param [Object]       obj       Object to type check.
# @param [Class]        type      Class the object should be an instance of.
# @param [String, nil]  blame     Variable name to blame for failed type checks.
# @param [Boolean]      nillable  Object can be nil?
# @param [Boolean]      strict    Strict or non-strict checking.  Uses `instance_of?` and `is_a?` respectively.
#
# @raise [ArgumentError] An error is raise if the type checking fails.
#
# @return [Object] The object passed as parameter o.
def check_type(obj, type, blame = nil, nillable = false, strict = false)
	type_ok = if strict then obj.instance_of?(type) else obj.is_a?(type) end || (obj.nil? and nillable)	
	
	if type_ok
		obj
	else
		if blame
			raise TypeError,
				"Parameter #{blame} must be an instance of the #{type.name} class.  Received an instance of #{obj.class.name}."
		else
			raise TypeError,
				"Expected an object of type #{type.name}.  Received an instance of #{obj.class.name}."
		end
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
# @raise [ArgumentError] An error is raise if the type checking fails.
#
# @return [Object] The object passed in parameter o.
def check_array_type(array, type, blame = nil, nillable = false, strict = false)
	array.each do |obj|
		type_ok = if strict then obj.instance_of?(type) else obj.is_a?(type) end || (obj.nil? and nillable)
		
		if not type_ok
			if blame
				raise TypeError, "Parameter #{blame} must contain instances of the #{type.name} class."
			else
				raise TypeError, "Expected an object of type #{type.name}."
			end
		end
	end
end

#######################
# Classes and Modules #
#######################

module Filigree
	module TypedClass
		include ClassMethodsModule
	
		def set_typed_ivars(vals)
			self.class.typed_ivars.zip(vals).each do |name, val|
				self.send("#{name}=", val)
			end
		end
	
		module ClassMethods
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
		
			def define_typed_accessor(name, nillable, strict, type, checker)
				define_method "#{name}=" do |obj|
					self.instance_variable_set("@#{name}", checker.call(obj, type, name, nillable, strict))
				end
			end
			private :define_typed_accessor
		
			def typed_ivar(name, type, nillable = false, strict = false)
				typed_ivars << name
			
				define_typed_accessor(name, nillable, strict, *
					type.is_a?(Array) ? [type.first, method(:check_array_type)] : [type, method(:check_type)]
				)
		
				attr_reader name
			end
	
			def typed_ivars
				@typed_ivars ||= Array.new
			end
		end
	end
end
