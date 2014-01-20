# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/14
# Description:	Simple application framework.

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

module Filigree; end

module Filigree::Application
	include ClassMethodsModule
	
	#############
	# Constants #
	#############
	
	REQUIRED_METHODS = [
		:kill,
		:pause,
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
		
		Signal.trap('KILL') { self.kill }
		
		Signal.trap('CONT') { self.resume }
		Signal.trap('STOP') { self.pause  }
	end
	
	#################
	# Class Methods #
	#################
	
	module ClassMethods
		def finalize
			REQUIRED_METHODS.each do |method|
				raise(NoMethodError, "Application #{self.name} missing method: #{method}") if not self.instance_methods.include?(method)
			end
		end
		
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
