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
		
		end
		
		def help(str)
			@help_string = str
		end
		
		def install_icvars
			@commands		= Array.new
			@help_string	= ''
		end
		
		def param
			
		end
		
		def subcommand
		
		end
		
		#############
		# Callbacks #
		#############
		
		class << self
			def extended(klass)
				klass.install_icvars
			end
		end
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
		
		def initialize(name, help, action)
			@name	= name
			@help	= help
			@action	= action
		end
		
		def match?(line)
			
		end
	end
	
	class Subcommand < Command
		def call(*args)
			@parent.call(*args, &@action)
		end
		
		def initialize(name, help, action, parent)
			super
			
			@parent = parent
		end
	end
end
