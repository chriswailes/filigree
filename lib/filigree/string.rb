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
		
		words = self.split(/\s/)
		line  = words.shift
		
		line_length = indent + line.length
		
		words.each do |word|
			new_length = line_length + 1 + word.length
			
			if new_length < max_length
				line       += " #{word}"
				line_length = new_length
				
			else
				lines << line
				
				line        = word
				line_length = indent + word.length
			end
		end
		
		lines << line unless line.empty?
		
		lines.join("\n" + (' ' * indent))
	end
end
