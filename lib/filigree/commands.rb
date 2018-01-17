# Author:      Chris Wailes <chris.wailes+filigree@gmail.com>
# Project:     Filigree
# Date:        2013/05/14
# Description: Easy application configuration.

############
# Requires #
############

# Standard Library

# Filigree
require 'filigree/class_methods_module'
require 'filigree/configuration'
require 'filigree/string'

##########
# Errors #
##########

class CommandNotFoundError < RuntimeError
	def initialize(line)
		super "No command found for '#{line}'"
	end
end

#######################
# Classes and Modules #
#######################

module Filigree
	module Commands
		using Filigree

		include ClassMethodsModule

		####################
		# Instance Methods #
		####################

		# This will find the appropriate command and execute it.
		#
		# @param [String]  line  String containing the command to be processed and its arguments
		#
		# @return [Object]  Result of invoking the command's block
		def call(line)
			# FIXME: Let this take either a split array, or a string that needs to be split
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
				# TODO: Specify the number of arguments expected and given.
				# TODO: Display the help string for the command if present.
				raise ArgumentError, "Wrong number of arguments for command: #{command.name}."
			end
		end

		#################
		# Class Methods #
		#################

		module ClassMethods
			# @return [Hash<String, Hash>]
			attr_accessor :commands

			# @return [Array<Command>]
			attr_accessor :command_list

			# Add a command to the necessary internal data structures.
			#
			# @param [Command]  command_obj  Command to add
			#
			# @return [void]
			def add_command(command_obj)
				@command_list << command_obj
				namespace = reify_namespace(command_obj.name.split.map(&:to_sym))
				namespace[:nil] = command_obj
			end

			# Add a new command to the class.  All command code is executed
			# in the context of the Commands object.
			#
			# @param [String]  str    Name of the command
			# @param [Proc]    block  Code to be executed when the command is run
			#
			# @return [void]
			def command(str, &block)
				add_command Command.new(str, @help_string, @param_docs, @config, block)

				@help_string = ''
				@param_docs  = Array.new
				@config      = nil
			end

			# This will generate an anonymous {Configuration} class for this
			# command.  After a string resolves to the next command defined
			# the remainder of the command line will be passed to an
			# instance of this Configuration class.  Any remaining text is
			# then provided to the command as usual.
			#
			# The variables defined in the configuration class are available
			# in the command's block.
			#
			# @param [Proc]  block  Body of the {Configuration} class
			#
			# @return [void]
			def config(&block)
				@config = Class.new { include Filigree::Configuration }
				@config.instance_exec(&block)
			end

			# Attaches the provided help string to the command that is
			# defined next.
			#
			# @param [String]  str  Help string for the next command
			#
			# @return [void]
			def help(str)
				@help_string = str
			end

			# Install the instance class variables in the including class.
			#
			# @return [void]
			def install_icvars
				@commands     = Hash.new
				@command_list = Array.new
				@config       = nil
				@help_string  = ''
				@param_docs   = Array.new
			end

			# Given a root namespace, find the namespace indicated by the
			# provided tokens.
			#
			# @param  [Array<String>]       tokens  String tokens specifying the namespace
			# @param  [Hash<Symbol, Hash>]  root    Root namespace
			#
			# @return  [Array<(Hash<Symbol, Hash>, Array<String>)>]
			#   The requested namespace and the remainder of the tokens.
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

			# Add a description for a command's parameter.
			#
			# @param  [String]  name         Name of the parameter
			# @param  [String]  description  Description of the parameter.
			#
			# @return [void]
			def param(name, description)
				@param_docs << [name, description]
			end

			# Find or create the namespace specified by tokens.
			#
			# @param  [Array<String>]       tokens  Tokens specifying the namespace.
			# @param  [Hash<Symbol, Hash>]  root    Root namespace
			#
			# @return  [Array<(Hash<Symbol, Hash>, Array<String>)>]
			#   The requested namespace and the remainder of the tokens.
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

		# The POD representing a command.
		class Command < Struct.new(:name, :help, :param_help, :config, :action)
		end

		########################
		# Pre-defined Commands #
		########################

		# The default help command.  This can be added to your class via
		# add_command.
		HELP_COMMAND = Command.new('help', 'Prints this help message.', [], nil, Proc.new do

			puts 'Usage: <command> [options] <args>'
			puts
			puts 'Commands:'

			comm_list = self.class.command_list

			sorted_comm_list = comm_list.sort { |a, b| a.name <=> b.name }
			max_length       = comm_list.lazy.map { |opt| opt.name.length }.max


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
				puts "\t#{comm.help}"
				puts

				if !comm.param_help.empty?
					max_param_len = comm.param_help.inject(0) do |max, pair|
						param_len = pair.first.to_s.length
						max <=  param_len ? param_len : max
					end

					segment_indent	= max_param_len + 8
					comm.param_help.each do |name, help|
						printf "\t%-#{max_param_len}s - %s\n", name, help.segment(segment_indent)
					end
				end
			end
		end)
	end
end
