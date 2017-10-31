# Author:		Chris Wailes <chris.wailes+filigree@gmail.com>
# Project: 	Filigree
# Date:		2013/05/14
# Description:	Easy application configuration.

############
# Requires #
############

# Standard Library

# Filigree
require 'filigree/class_methods_module'
require 'filigree/string'

#########
# Notes #
#########

# TODO: Add support for configuration destructors

#######################
# Classes and Modules #
#######################

module Filigree
	module Configuration
		include ClassMethodsModule

		#############
		# Constants #
		#############

		####################
		# Instance Methods #
		####################

		# @return [Array<String>]  Remaining strings that weren't used in configuration
		attr_accessor :rest

		# Dump the state of the Configuration object.  This will dump the
		# state, encoded in YAML, to different destinations depending on the
		# io parameter.
		#
		# @overload dump(io, *fields)
		#   Dump the state to stdout.
		#   @param [nil]     io      Tells the method to serialize to stdout
		#   @param [Symbol]  fields  Fields to serialize
		#
		# @overload dump(str, *fields)
		#   Dump the state to a file.
		#   @param [String]  io      Name of file to serialize to
		#   @param [Symbol]  fields  Fields to serialize
		#
		# @overload dump(io, *fields)
		#   Dump the state to the provided IO instance.
		#   @param [IO]      io      IO object to serialize to
		#   @param [Symbol]  fields  Fields to serialize
		#
		# @return [void]
		def dump(io = nil, *fields)
			require 'yaml'

			vals =
			if fields.empty? then self.class.options_long.keys else fields end.inject(Hash.new) do |hash, field|
				hash.tap { hash[field.to_s] = self.send(field) }
			end

			case io
			when nil
				YAML.dump vals

			when String
				File.open(io, 'w') { |file| YAML.dump vals, file }

			when IO
				YAML.dump vals, io
			end
		end
		alias :serialize :dump

		# Configures the object based on the overloaded parameter.
		#
		# @overload initialize(args)
		#   Configure the object from an array of strings.
		#   @param [Array<String>]  args  String arguments
		#
		# @overload initialize(source)
		#    Configure the object from a serialized source.  If source is a
		#    string then it will be treated as a file name and the
		#    configuration will be loaded from the specified string.  If it
		#    an IO object then that will be used as the source.
		#    @param [String, IO]  source  Serialized configuration source
		#
		# @return [void]
		def initialize(overloaded = ARGV.clone)
			set_opts = Array.new

			case overloaded
			when Array
				handle_array_options(overloaded, set_opts)

			when String, IO
				handle_serialized_options(overloaded, set_opts)
			end

			(self.class.options_long.keys - set_opts).each do |opt_name|
				default = self.class.options_long[opt_name].default
				default = self.instance_exec(&default) if default.is_a? Proc

				self.send("#{opt_name}=", default)
			end

			# Check to make sure all the required options are set.
			self.class.required_options.each do |option|
				raise ArgumentError, "Option #{option} not set." if self.send(option).nil?
			end
		end

		# Find the appropriate option object given a string.
		#
		# @param [String]  str  Search string
		#
		# @return [Option, nil]  Desired option or nil if it wasn't found
		def find_option(str)
			if str[0,2] == '--'
				self.class.options_long[str[2..-1]]

			elsif str[0,1] == '-'
				self.class.options_short[str[1..-1]]
			end
		end

		# Configure the object from an array of strings.
		#
		# @param [Array<String>]  argv      String options
		# @param [Array<String>]  set_opts  List of names of options already added
		#
		# @return [void]
		def handle_array_options(argv, set_opts)
			while str = argv.shift

				break if str == '--'

				if option = find_option(str)
					args = argv.shift(option.arity == -1 ? argv.index { |sub_str| sub_str[0,1] == '-' } : option.arity)

					case option.handler
					when Array
						tmp = args.zip(option.handler).map { |arg, sym| arg.send sym }
						self.send("#{option.long}=", (option.arity == 1 and tmp.length == 1) ? tmp.first : tmp)

					when Proc
						self.send("#{option.long}=", self.instance_exec(*args, &option.handler))
					end

					set_opts << option.long
				end
			end

			# Save the rest of the command line for later.
			self.rest = argv
		end

		# Configure the object from a serialization source.
		#
		# @param [String, IO]     overloaded  Serialization source
		# @param [Array<String>]  set_opts    List of names of options already added
		#
		# @return [void]
		def handle_serialized_options(overloaded, set_opts)
			options =
			if overloaded.is_a? String
				if File.exist? overloaded
					YAML.load_file overloaded
				else
					YAML.load overloaded
				end
			else
				YAML.load overloaded
			end

			options.each do |option, val|
				set_opts << option
				self.send "#{option}=", val
			end
		end

		#################
		# Class Methods #
		#################

		module ClassMethods
			# @return [Hash<String, Option>]  Hash of options with long names used as keys
			attr_reader :options_long
			# @return [Hash<String, Option>]  hash of options with short name used as keys
			attr_reader :options_short

			# Add an option to the necessary data structures.
			#
			# @param [Option]  opt  Option to add
			#
			# @return [void]
			def add_option(opt)
				attr_accessor opt.long

				@options_long[opt.long]   = opt
				@options_short[opt.short] = opt unless opt.short.nil?
			end

			# Define an automatic configuration variable.
			#
			# FIXME: These blocks should only be executed once and then memoized.
			#
			# @param [Symbol]  name   Name of the configuration variable
			# @param [Proc]    block  Block to be executed to generate the value
			#
			# @return [void]
			def auto(name, &block)
				define_method(name, &block)
			end

			# Define a boolean option.  The variable will be set to true if
			# the flag is seen and be false otherwise.
			#
			# @param [String]  long   Long name of the option
			# @param [String]  short  Short name of the option
			#
			# @return [void]
			def bool_option(long, short = nil)
				@next_default = false
				option(long, short) { true }
			end

			# Sets the default value for the next command.  If a block is
			# provided it will be used.  If not, the val parameter will be.
			#
			# @param [Object]  val    Default value
			# @param [Proc]    block  Default value generator block
			#
			# @return [void]
			def default(val = nil, &block)
				@next_default = block ? block : val
			end

			# Sets the help string for the next command.
			#
			# @param [String]  str  Command help string
			#
			# @return [void]
			def help(str)
				@help_string = str
			end

			# Install the instance class variables in the including class.
			#
			# @return [void]
			def install_icvars
				@help_string   = ''
				@next_default  = nil
				@next_required = false
				@options_long  = Hash.new
				@options_short = Hash.new
				@required      = Array.new
				@usage         = ''
			end

			# Define a new option.
			#
			# @param [String]         long         Long option name
			# @param [String]         short        Short option name
			# @param [Array<Symbol>]  conversions  List of methods used to convert string arguments
			# @param [Proc]           block        Block used when the option is encountered
			#
			# @return [void]
			def option(long, short = nil, conversions: nil, &block)
				long  = long.to_s.gsub('-', '_')
				short = short.to_s if short

				attr_accessor long.to_sym

				add_option Option.new(long, short, @help_string, @next_default,
					                  conversions.nil? ? block : conversions)

				@required << long.to_sym if @next_required

				# Reset state between option declarations.
				@help_string   = ''
				@next_default  = nil
				@next_required = false
			end

			# Mark some options as required.  If no names are provided then
			# the next option to be defined is required; if names are
			# provided they are all marked as required.
			#
			# @param [Symbol]  names  Options to be marked as required.
			#
			# @return [void]
			def required(*names)
				if names.empty?
					@next_required = true
				else
					@required += names
				end
			end

			# @return [Array<Symbol>]  Options that need to be marked as required
			def required_options
				@required
			end

			# Define an option that takes a single string argument.
			#
			# @param [String]  long   Long option name
			# @param [String]  short  Short option name
			#
			# @return [void]
			def string_option(long, short = nil)
				option(long, short) { |str| str }
			end

			# Add's a usage string to the entire configuration object.  If
			# no string is provided the current usage string is returned.
			#
			# @param [String, nil]  str  Usage string
			#
			# @return [String]  Current or new usage string
			def usage(str = nil)
				if str then @usage = str else @usage end
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

		# This class represents an option that can appear in the
		# configuration.
		class Option < Struct.new(:long, :short, :help, :default, :handler)
			using Filigree

			# Returns the number of arguments that this option takes.
			#
			# @return [Fixnum]  Number of arguments the option takes
			def arity
				case self.handler
				when Array then self.handler.length
				when Proc  then self.handler.arity
				end
			end

			# Print the option information out as a string.
			#
			# Layout:
			# |       ||--`long`,|| ||-`short`|| ~ |
			# |_______||_________||_||________||___|
			#   indent    max_l+3  1   max_s+1   3
			#
			# @param [Fixnum]  max_long   Maximim length of all long argumetns being printed in a block
			# @param [Fixnum]  max_short  Maximum length of all short arguments being printed in a block
			# @param [Fixnum]  indent     Indentation to be placed before each line
			#
			# @return [String]
			def to_s(max_long, max_short, indent = 0)
				segment_indent	= indent + max_long + max_short + 8
				segmented_help = self.help.segment(segment_indent)

				if self.short
					sprintf "#{' ' * indent}%-#{max_long + 3}s %-#{max_short + 1}s   %s", "--#{self.long},", '-' + self.short, segmented_help
				else
					sprintf "#{' ' * indent}%-#{max_long + max_short + 5}s   %s", '--' + self.long, segmented_help
				end
			end

			# Helper method used to print out information on a set of options.
			#
			# @param [Array<Option>]  options  Options to be printed
			# @param [Fixnum]         indent   Indentation to be placed before each line
			#
			# @return [String]
			def self.to_s(options, indent = 0)
				lines = []

				max_long  = options.lazy.map { |opt| opt.long.length }.max
				max_short = options.lazy.map(&:short).reject { |opt| opt.nil? }.map(&:length).max

				options.each do |opt|
					lines << opt.to_s(max_long, max_short, indent)
				end

				lines.join("\n")
			end
		end

		#######################
		# Pre-defined Options #
		#######################

		# The default help option.  This can be added to your class via
		# add_option.
		HELP_OPTION = Option.new('help', 'h', 'Prints this help message.', nil, Proc.new do
			puts "Usage: #{self.class.usage}"
			puts
			puts 'Options:'

			options = self.class.options_long.values.sort { |a, b| a.long <=> b.long }
			puts Option.to_s(options, 2)

			# Quit the application after printing the help message.
			exit
		end)
	end
end
