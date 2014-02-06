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
		
		command = namespace[:nil]
		
		action = 
		if command.config
			conf_obj = command.config.new(rest)
			rest     = conf_obj.rest
			
			-> (*args) { conf_obj.instance_exec(*args, &command.action) }
		else
			command.action
		end
		
		if command.action.arity < 0 or command.action.arity == rest.length
			self.instance_exec(*rest, &action)
		else
			raise ArgumentError, "Wrong number of arguments for command: #{command.name}."
		end
	end
	
	#################
	# Class Methods #
	#################
	
	module ClassMethods
		attr_accessor :commands
		attr_accessor :command_list
		
		def add_command(command_obj)
			@command_list << command_obj
			namespace = reify_namespace(command_obj.name_as_syms)
			namespace[:nil] = command_obj
		end
		
		def command(str, &block)
			add_command Command.new(str, @help_string, @param_docs, @config, block)
			
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
			@commands     = Hash.new
			@command_list = Array.new
			@config       = nil
			@help_string  = ''
			@param_docs   = Array.new
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
		def name_as_syms
			self.name.split.map {|str| str.to_sym}
		end
	end
	
	########################
	# Pre-defined Commands #
	########################
	
	HELP_COMMAND = Command.new('help', 'Prints this help message.', [], nil, Proc.new do
		puts 'Usage: <command> [options] <args>'
		puts
		puts 'Commands:'
		
		self.class.command_list.map {|com| com.name} .each { |com| puts com.name }
	end)
end
