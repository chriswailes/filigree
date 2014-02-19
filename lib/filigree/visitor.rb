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
			@match_bindings = OpenStruct.new
		
			return pattern.(self, objects) if pattern.match?(objects, self)
		end
	
		# If we didn't find anything we raise a MatchError.
		raise MatchError
	end
	
	#############
	# Callbacks #
	#############
	
	def method_missing(name, *args)
		if args.empty? and @match_bindings.respond_to?(name)
			@match_bindings.send(name)
		elsif name.to_s[-1] == '=' and args.length == 1
			@match_bindings.send(name, *args)
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
			BindingPattern.new(name)
		end
	
		def Literal(obj)
			LiteralPattern.new(obj)
		end
		
		def install_icvars
			@patterns = Array.new
			@deferred = Array.new
		end
		
		def on(*pattern, &block)
			guard = if pattern.last.is_a?(Proc) then pattern.pop end 
		
			@patterns << (mp = OuterPattern.new(pattern, guard, block))
		
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
				if name == :_ then WildcardPattern.instance else BindingPattern.new(name) end
			else
				super(name, *args)
			end
		end
	
		def self.extended(klass)
			klass.install_icvars
		end
	end
end

class TourGuide
	attr_reader :visitors
	
	def call(*objects)
		@visitors.each { |visitor| visitor.(*objects) }
	end
	
	def initialize(*visitors)
		@visitors = visitors
	end
end

module Visitable
	def visit(visitor, method = :preorder)
		case method
		when :preorder
			visitor.(self)
			children.compact.each { |child| child.visit(visitor, :preorder) }
			
		when :levelorder
			nodes = [self]
			
			while node = nodes.shift
				nodes += node.children.compact
				visitor.(node)
			end
			
		when :postorder
			children.compact.each { |child| child.visit(visitor, :postorder) }
			visitor.(self)
		end
	end
end
