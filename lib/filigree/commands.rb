# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/14
# Description:	Easy application configuration.

############
# Requires #
############

# Standard Library

# Filigree
require 'filigree/array'
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
			namespace = reify_namespace(command_obj.name.split.map(:to_sym))
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
	
	Command = Struct.new(:name, :help, :param_help, :config, :action)
	
	########################
	# Pre-defined Commands #
	########################
	
	HELP_COMMAND = Command.new('help', 'Prints this help message.', [], nil, Proc.new do
		puts 'Usage: <command> [options] <args>'
		puts
		puts 'Commands:'
		
		comm_list = self.class.command_list
		
		sorted_comm_list = comm_list.sort { |a, b| a.name <=> b.name }
		max_length       = comm_list.map(:name).inject(0) { |max, str| max <= str.length ? str.length : max }
		
		
		sorted_comm_list.each do |comm|
			printf "  % #{max_length}s", comm.name
			
			if comm.config
				print ' [options]'
			end
			
			puts comm.param_help.inject('') { |str, pair| str << " <#{pair.first}>" }
			
			if comm.config
				options = comm.config.options_long.values.sort { |a, b| a.long <=> b.long }
				puts Filigree::Configuration::Option.to_s(options, max_length + 4)
			end
			
			puts
			
			if !comm.param_help.empty?
				max_param_len = comm.param_help.inject(0) do |max, pair|
					param_len = pair.first.to_s.length
					max <=  param_len ? param_len : max
				end
				
				segment_indent	= max_param_len + 8
				comm.param_help.each do |name, help|
					printf "     %-#{max_param_len}s - %s\n", name, help.segment(segment_indent)
				end
			end
		end
	end)
end
