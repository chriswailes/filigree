# Author:      Chris Wailes <chris.wailes+filigree@gmail.com>
# Project:     Filigree
# Date:        2013/05/14
# Description: Simple application framework.

############
# Requires #
############

# Standard Library

# Filigree
require 'filigree/class_methods_module'
require 'filigree/configuration'

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
	# The beginnings of a general purpose application module.  The aim is to provide
	# the basic framework for larger desktop and command line applications.
	module Application
		include ClassMethodsModule

		#############
		# Constants #
		#############

		REQUIRED_METHODS = [
			:resume,
			:run,
			:stop
		]

		####################
		# Instance Methods #
		####################

		attr_accessor :configuration
		alias :config :configuration

		def initialize
			@configuration = self.class::Configuration.new

			# Set up signal handlers.
			Signal.trap('ABRT') { self.stop }
			Signal.trap('INT')  { self.stop }
			Signal.trap('QUIT') { self.stop }
			Signal.trap('TERM') { self.stop }

			Signal.trap('CONT') { self.resume }
		end

		#################
		# Class Methods #
		#################

		module ClassMethods
			# Check to make sure all of the required methods are defined.
			#
			# @raise [NoMethodError]
			#
			# @return [void]
			def finalize
				REQUIRED_METHODS.each do |method|
					if not self.instance_methods.include?(method)
						raise(NoMethodError, "Application #{self.name} missing method: #{method}")
					end
				end
			end

			# Create a new instance of this application and run it.
			#
			# @return [Object]
			def run
				self.new.run
			end
		end

		#############
		# Callbacks #
		#############

		class << self
			alias :old_included :included

			def included(klass)
				old_included(klass)
				klass.const_set(:Configuration, Class.new { include Filigree::Configuration })
			end
		end
	end
end
