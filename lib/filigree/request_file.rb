# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2014/1/20
# Description:	A helper for require.

############
# Requires #
############

# Standard Library

# Filigree

###########
# Methods #
###########

# Require a file, but fail gracefully if it isn't found.
#
# @param [String]   file           File to be requested
# @param [Boolean]  print_failure  To print a message on failure or not
def request_file(file, print_failure = false)
	begin
		require file
		yield if block_given?
	rescue LoadError
		if print_warning.is_a?(String)
			puts print_failure
		elsif print_failure
			puts "Unable to require file: #{file}"
		end
	end
end