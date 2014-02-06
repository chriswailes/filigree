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
require 'filigree/string'

#######################
# Classes and Modules #
#######################

module Filigree; end

module Filigree::Configuration
	include ClassMethodsModule
	
	#############
	# Constants #
	#############

	####################
	# Instance Methods #
	####################
	
	attr_accessor :rest
	
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
	
	def find_option(str)
		if str[0,2] == '--'
			self.class.options_long[str[2..-1]]
			
		elsif str[0,1] == '-'
			self.class.options_short[str[1..-1]]
		end
	end
	
	def handle_array_options(argv, set_opts)
		while str = argv.shift
		
			break if str == '--'
			
			if option = find_option(str)
				args = argv.shift(option.arity == -1 ? argv.index { |str| str[0,1] == '-' } : option.arity)
			
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
	
	def handle_serialized_options(overloaded, set_opts)
		options =
		if overloaded.is_a? String
			if File.exists? overloaded
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
		attr_reader :options_long
		attr_reader :options_short
		
		def add_option(opt)
			@options_long[opt.long]   = opt
			@options_short[opt.short] = opt unless opt.short.nil?
		end
		
		def auto(name, &block)
			define_method(name, &block)
		end
		
		def bool_option(long, short = nil)
			@next_default = false
			option(long, short) { true }
		end
		
		def default(val = nil, &block)
			@next_default = block ? block : val
		end
		
		def help(str)
			@help_string = str
		end
		
		def install_icvars
			@help_string	= ''
			@next_default	= nil
			@next_required	= false
			@options_long	= Hash.new
			@options_short	= Hash.new
			@required		= Array.new
			@usage		= ''
		end
		
		def option(long, short = nil, conversions: nil, &block)
			
			attr_accessor long.to_sym
			
			long  = long.to_s
			short = short.to_s if short
			
			add_option Option.new(long, short, @help_string, @next_default,
			                      conversions.nil? ? block : conversions)
			
			@required << long.to_sym if @next_required
			
			# Reset state between option declarations.
			@help_string	= ''
			@next_default	= nil
			@next_required = false
		end
		
		def required(*names)
			if names.empty?
				@next_required = true
			else
				@required += names
			end
		end

		def required_options
			@required
		end
		
		def string_option(long, short = nil)
			option(long, short) { |str| str }
		end
		
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
	
	class Option < Struct.new(:long, :short, :help, :default, :handler)
		def arity
			case self.handler
			when Array	then self.handler.length
			when Proc		then self.handler.arity 
			end
		end
		
		# Layout:
		# |       ||--`long`,|| ||-`short`|| - |
		# |_______||_________||_||________||___|
		#   indent    max_l+3  1   max_s+1   3
		def to_s(max_long, max_short, indent = 0)
			segment_indent	= indent + max_long + max_short + 8
			segmented_help = self.help.segment(segment_indent)
			
			if self.short
				sprintf "#{' ' * indent}%-#{max_long + 3}s %-#{max_short + 1}s - %s", "--#{self.long},", '-' + self.short, segmented_help
			else
				sprintf "#{' ' * indent}%-#{max_long + max_short + 5}s - %s", '--' + self.long, segmented_help
			end
		end
		
		def self.to_s(options, indent = 0)
			lines = []
			
			max_long  = options.inject(0) { |max, opt| max <= opt.long.length  ? opt.long.length  : max }
			max_short = options.inject(0) { |max, opt| !opt.short.nil? && max <= opt.short.length ? opt.short.length : max }
		
			options.each do |opt|
				lines << opt.to_s(max_long, max_short, indent)
			end
			
			lines.join("\n")
		end
	end
	
	#######################
	# Pre-defined Options #
	#######################
	
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
