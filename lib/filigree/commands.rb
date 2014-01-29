# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/14
# Description:	Easy application configuration.

############
# Requires #
############

# Standard Library

# Filigree
require 'filigree/class_methods_module'

##########
# Errors #
##########

###########
# Methods #
###########

#######################
# Classes and Modules #
#######################

module Filigree::Commands
	include ClassMethodsModule
	
	#############
	# Constants #
	#############

	####################
	# Instance Methods #
	####################
	
	# Process a command.
	def call(line)
	
	end
	
	#################
	# Class Methods #
	#################
	
	module CalssMethods
		def command(str, &block)
			tokens = str.split.map(:to_sym)
			@commands << Command.new(@help_string, @param_docs block)
			@help_string = ''
			@param_docs  = Array.new
		end
		
		def help(str)
			@help_string = str
		end
		
		def install_icvars
			@commands    = Hash.new
			@help_string = ''
			@param_docs  = Array.new
		end
		
		def param(name, description)
			@param_docs << [name, description]
		end
	end
	
	#############
	# Callbacks #
	#############
	
	def self.extended(klass)
		klass.install_icvars
	end
	
	#################
	# Inner Classes #
	#################
	
	class Command
		def call(*args)
			if @action.arity < 0 or @action.arity == args.length
				@action.call(*args)
			else
				raise ArgumentError, "Wrong number of arguments for command: #{self.name.join(' ')}."
			end
		end
		
		def initialize(tokens, help, action)
			@tokens = tokens
			@help   = help
			@action = action
		end
		
		def match?(line)
			
		end
	end
end
