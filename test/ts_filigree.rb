# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/4/19
# Description:	This file contains the test suit for Filigree.  It requires the
#			individual tests from their respective files.

############
# Requires #
############

begin
	require 'simplecov'
	SimpleCov.start do
		add_filter 'tc_*'
	end
	
rescue LoadError
	puts 'SimpleCov not installed.  Continuing without it.'
end

# Test Cases
require 'tc_abstract_class'
