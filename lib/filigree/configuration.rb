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
		set = self.class.options_long.keys.inject(Hash.new) { |h, option| h[option] = false; h }
		
		# Process the command line.
		while str = argv.shift
			
			break if str == '--'
			
			if option = find_option(str)
				args =
				if option.arity == -1
					argv.shift (argv.index { |s| s[0,1] == '-'})
				else
					argv.shift option.arity
				end
				
				case option.handler
				when Array
					tmp = args.zip(option.handler).map { |s, sym| s.send sym }
					
					if option.arity == 1 and tmp.length == 1
						self.send("#{option.long}=", tmp.first)
					else
						self.send("#{option.long}=", tmp)
					end
					
				when Proc
					self.send("#{option.long}=", option.handler.call(*args))
				end
				
				set[option.long] = true
			end
		end
		
		# Save the rest of the command line for later.
		self.rest = argv
		
		# Set defaults.
		set.each do |name, is_set|
			if not is_set
				default = self.class.options_long[name].default
			
				default = self.instance_exec &default if default.is_a? Proc
				
				self.send("#{name}=", default)
			end
		end
		
		# Check to make sure all the required options are set.
		self.class.required_options.each do |option|
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
		
		def auto(name, &block)
			define_method(name, &block)
		end
		
		def default(val = nil, &block)
			@next_default = if block then block else val end
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
		
		def option(long, short, *conversions, &block)
			
			attr_accessor long.to_sym
			
			@options_long[long] = @options_short[short] =
				Option.new(long, short, @help_string, @next_default,
					if not conversions.empty? then conversions else block end)
			
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
		
		def segment(str, indent, max_length = 80)
			lines = Array.new
			line  = ''
			
			str.split(/\s/).each do |word|
				new_length  = line.length + word.length + indent + 1
				
				if new_length < max_length
					line += ' ' if line.length != 0
					line += word
					
				else
					lines << line
					line = word
				end
			end
			
			lines << line if not line.empty?
			
			lines.join("\n\t" + (' ' * indent))
		end
		
		def usage(str)
			@usage = str
		end
		
		#############
		# Callbacks #
		#############
		
		class << self
			def extended(klass)
				klass.install_icvars
				
				#######################
				# Pre-defined Options #
				#######################
		
				klass.instance_exec do
					help 'Prints this help message.'
					option 'help', 'h' do
						option_names	= @options_long.keys.sort
						max_length	= option_names.inject(0) { |m, s| if m <= s.length then s.length else m end }
						segment_indent	= max_length + 3
			
						puts "Usage: #{@usage}"
						puts
						puts 'Options:'
			
						option_names.each do |name|
							printf "\t% #{max_length}s - %s\n", name, segment(@options_long[name].help, segment_indent)
						end
			
						# Quit the application after printing the help message.
						exit
					end
				end
			end
		end
	end
	
	#################
	# Inner Classes #
	#################
	
	Option = Struct.new(:long, :short, :help, :default, :handler)
	
	class Option
		def arity
			case self.handler
			when Array	then self.handler.length
			when Proc		then self.handler.arity 
			end
		end
	end
	
	#############
	# Callbacks #
	#############
end
