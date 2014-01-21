# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2014/01/20
# Description:	Class extensions for the String class.

############
# Requires #
############

# Standard Library

# Filigree

#######################
# Classes and Modules #
#######################

class String
	def segment(indent, max_length = 80)
		lines = Array.new
		line  = ''
		
		self.split(/\s/).each do |word|
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
end
