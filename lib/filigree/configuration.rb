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

module Filigree::Configuration
	include ClassMethodsModule
	
	#############
	# Constants #
	#############

	####################
	# Instance Methods #
	####################
	
	attr_accessor :rest
	
	def initialize(argv = ARGV.clone)
		# Process the command line.
		while str = argv.shift
			
			break if str == '--'
			
			if option = find_option str
				args =
				if option.arity == -1
					args.shift (args.index { |s| s[0,1] == '-'})
				else
					args.shift option.arity
				end
				
				value =
				case option.handler
				when Array
					args.zip(options.handler).map { |s, sym| s.send sym }
					
				when Option
					option.handler.call(*args)
				end
				
				self.send("#{option.long}=", value)
			end
		end
		
		# Save the rest of the command line for later.
		self.rest = argv
		
		# Check to make sure all the required options are set.
		self.class.required.each do |option|
			if self.send(option).nil?
				raise ArgumentError, "Option #{option} not set."
			end
		end
	end
	
	def find_option(str)
		if str[0,2] == '--'
			self.class.options_long[str[2..-1]]
			
		elsif str[0,1] == '-'
			self.class.options_short[str[1..-1]]
			
		else
			nil
		end
	end
	
	#################
	# Class Methods #
	#################
	
	module ClassMethods
		attr_reader :options_long
		attr_reader :options_short
		attr_reader :required
		
		def auto(name, &block)
			define_method(name, &block)
		end
		
		def help(str)
			@help_string = str
		end
		
		def install_icvars
			@help_string	= nil
			@next_required	= false
			@options_long	= Hash.new
			@options_short	= Hash.new
			@required		= Array.new
			@usage		= ''
		end
		
		def option(long, short, *conversions, &block)
			
			attr_accessor long.to_sym
			
			@options_long[long] = @options_short[short] =
				Option.new(long, short, @help_string,
					if not conversions.empty? then conversions else block end)
			
			@required << long.to_sym if @next_required
			
			# Reset state between option declarations.
			@help_string	= nil
			@next_required = false
		end
		
		def required(*names)
			if names.empty?
				@next_required = true
			else
				@required += names
			end
		end
		
		def segment(str, indent, max_length = 80)
			lines = Array.new
			line  = ''
			
			str.split(/\s/).each do |word|
				new_length  = line.length + word.length + indent + 1
				
				if  new_length < max_length
					line += ' ' + word
				else
					lines << line
					line = word
				end
			end
			
			lines.join("\n" + (indent * ' '))
		end
		
		def usage(str)
			@usage = str
		end
		
		#######################
		# Pre-defined Options #
		#######################
		
		option 'help', 'h' do
			option_names	= @options_long.keys.sort
			max_length	= option_names.inject(0) { |m, s| if m <= s.length then s.length else m end }
			segment_indent	= max_length + 3
			
			puts "Usage: #{@usage}"
			puts
			puts 'Options:'
			
			option_names.each do |name|
				printf "%#{max_length}s - %s\n", name, segment(@options_long[name].help, segment_indent)
			end
		end
		
		#############
		# Callbacks #
		#############
		
		class << self
			def extended(klass)
				klass.install_icvars
			end
		end
	end
	
	#################
	# Inner Classes #
	#################
	
	Option = Struct.new(:long, :short, :help, :handler)
	
	#############
	# Callbacks #
	#############
end
