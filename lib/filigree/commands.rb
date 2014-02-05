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
require 'filigree/configuration'

##########
# Errors #
##########

class CommandNotFoundError  < RuntimeError
	def initialize(line)
		super "No command found for '#{line}'"
	end
end

###########
# Methods #
###########

#######################
# Classes and Modules #
#######################

module Filigree::Commands
	include ClassMethodsModule
	
	####################
	# Instance Methods #
	####################
	
	# Process a command.
	def call(line)
		namespace, rest = self.class.get_namespace(line.split)
		
		if namespace == self.class.commands
			raise CommandNotFoundError, line
		end
		
		namespace[:nil].(rest)
	end
	
	#################
	# Class Methods #
	#################
	
	module ClassMethods
		attr_accessor :commands
		
		def add_command(str, command_obj)
			reify_namespace(str.split.map {|str| str.to_sym})[:nil] = command_obj
		end
		
		def command(str, &block)
			add_command(str, Command.new(str, @help_string, @param_docs, @config, block))
			
			@help_string = ''
			@param_docs  = Array.new
			@config      = nil
		end
		
		def config(&block)
			@config = Class.new { include Filigree::Configuration }
			@config.instance_exec &block
		end
		
		def help(str)
			@help_string = str
		end
		
		def install_icvars
			@commands    = Hash.new
			@config      = nil
			@help_string = ''
			@param_docs  = Array.new
		end
		
		def get_namespace(tokens, root: @commands)
			if tokens.empty?
				[root, tokens]
			else
				curr_token = tokens.first.to_sym
				
				if ns = root[curr_token]
					tokens.shift
					get_namespace(tokens, root: ns)
				else
					[root, tokens]
				end
			end
		end
		
		def param(name, description)
			@param_docs << [name, description]
		end
		
		def reify_namespace(tokens, root: @commands)
			if tokens.empty?
				root
			else
				curr_token = tokens.shift
				
				ns = root[curr_token]
				ns = root[curr_token] = Hash.new if ns.nil?
				
				reify_namespace(tokens, root: ns)
			end
		end
		
		#############
		# Callbacks #
		#############
	
		def self.extended(klass)
			klass.install_icvars
		end
	end
	
	#################
	# Inner Classes #
	#################
	
	class Command < Struct.new(:name, :help, :param_help, :config, :action)
		def call(args)
			if self.config
				conf_obj = self.config.new(args)
				call_prime(conf_obj.rest, conf_obj)
			else
				call_prime(args)
			end
		end
		
		def call_prime(args, context = nil)
			if self.action.arity < 0 or self.action.arity == args.length
				if context
					context.instance_exec(*args, &self.action)
				else
					self.action.call(*args)
				end
			else
				raise ArgumentError, "Wrong number of arguments for command: #{self.name}."
			end
		end
		private :call_prime
	end
	
	########################
	# Pre-defined Commands #
	########################
	
	HELP_COMMAND = Command.new('help', 'Prints this help message.', [], nil, Proc.new do
		puts "HELP!"
	end)
end
