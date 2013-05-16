# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/14
# Description:	Simple application framework.

############
# Requires #
############

# Standard Library

# Filigree
#require 'filigree/configuration'

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
	def initialize
#		@config = self.class::Configuration.new(ARGV)
	end
	
	#############
	# Callbacks #
	#############
	
	def included(klass)
#		klass.instance_exec do
#			Configuration = Class.new
#			Configuration.extend(Filigree::Configuration)
#		end
	end
end
