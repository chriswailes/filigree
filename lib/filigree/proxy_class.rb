# Author:      Chris Wailes <chris.wailes+filigree@gmail.com>
# Project:     Filigree
# Date:        2013/4/19
# Description: A simple way to proxy messages from one object to another

############
# Requires #
############

# Standard Library

# Filigree

require 'filigree/class_methods_module'

#######################
# Classes and Modules #
#######################

module Filigree
	# A module the implements the abstract class and abstract method patterns.
	module ProxyClass
		include ClassMethodsModule

		####################
		# Instance Methods #
		####################

		#################
		# Class Methods #
		#################

		module ClassMethods
			attr_reader :proxy_names

			# Install instance class variables in the extended class.
			#
			# @return [void]
			def install_icvars
				@proxy_names = Array.new
			end

			def proxy_for(*names)
				@proxy_names.push(*names)
			end

			#############
			# Callbacks #
			#############

			def inherited(klass)
				klass.instance_variable_set(:@proxy_names, @proxy_names.clone)
			end

			# Tell the extended class to install its instance class variables.
			#
			# @return [void]
			def self.extended(klass)
				klass.install_icvars
			end
		end

		#############
		# Callbacks #
		#############

		def method_missing(method_name, *args, &block)
			self.class.proxy_names.each do |ivar_name|
				obj = self.instance_variable_get(:"@#{ivar_name}")

				if obj && obj.respond_to?(method_name)
					return obj.send(method_name, *args, &block)
				end
			end

			super
		end
	end
end
