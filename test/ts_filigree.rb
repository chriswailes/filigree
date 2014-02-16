# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/04/19
# Description:	This file contains the test suit for Filigree.  It requires the
#			individual tests from their respective files.

############
# Requires #
############

# Filigree
require 'filigree/request_file'

request_file('simplecov', 'SimpleCov is not installed.') do
	SimpleCov.start do
		add_filter 'tc_*'
	end
end

# Test Cases
require 'tc_abstract_class'
require 'tc_application'
require 'tc_array'
require 'tc_boolean'
require 'tc_class'
require 'tc_class_methods_module'
require 'tc_commands'
require 'tc_configuration'
require 'tc_match'
require 'tc_object'
require 'tc_string'
require 'tc_types'
require 'tc_visitor'
