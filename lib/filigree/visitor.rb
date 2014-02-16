# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2014/02/11
# Description:	An implementation of the Visitor pattern.

############
# Requires #
############

# Standard Library

# Filigree
require 'filigree/class_methods_module'
require 'filigree/match'

#######################
# Classes and Modules #
#######################

module Visitor
	
	include ClassMethodsModule
	
	####################
	# Instance Methods #
	####################
	
	def call(*objects)
		self.class.patterns.each do |pattern|
			@matchBindings = OpenStruct.new
		
			return pattern.(self, objects) if pattern.match?(objects, self)
		end
	
		# If we didn't find anything we raise a MatchError.
		raise MatchError
	end
	
	#############
	# Callbacks #
	#############
	
	def method_missing(name, *args)
		if args.empty? and @matchBindings.respond_to?(name)
			@matchBindings.send(name)
		elsif name.to_s[-1] == '=' and args.length == 1
			@matchBindings.send(name, *args)
		else
			super(name, *args)
		end
	end
	
	#################
	# Class Methods #
	#################
	
	module ClassMethods
		
		attr_reader :patterns
		
		def Bind(name)
			MatchBinding.new(name)
		end
	
		def Instance(klass, pattern = Wildcard.instance)
			InstancePattern.new(klass, [pattern])
		end
		
		def install_icvars
			@patterns = Array.new
			@deferred = Array.new
		end
		
		def on(*pattern, &block)
			guard = if pattern.last.is_a?(Proc) then pattern.pop end 
		
			@patterns << (mp = MatchPattern.new(pattern, guard, block))
		
			if block
				@deferred.each { |pattern| pattern.block = block }
				@deferred.clear
			
			else
				@deferred << mp
			end
		end
		
		#############
		# Callbacks #
		#############
		
		def method_missing(name, *args)
			if args.empty?
				if name == :_ then Wildcard.instance else MatchBinding.new(name) end
			else
				super(name, *args)
			end
		end
	
		def self.extended(klass)
			klass.install_icvars
		end
	end
end
