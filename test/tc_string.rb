# Author:      Chris Wailes <chris.wailes@gmail.com>
# Project:     Filigree
# Date:        2014/02/05
# Description: Test cases for the String extensions.

############
# Requires #
############

# Gems
require 'minitest/autorun'

# Filigree
require 'filigree/string'

#######################
# Classes and Modules #
#######################

class ObjectTester < Minitest::Test

	using Filigree

	ORIGINAL = 'Hello, I am a test string. I am really long so that the string segmentation code can be tested.'
	SEGMENTED = <<eos
Hello, I am a test string.
  I am really long so that
  the string segmentation
  code can be tested.
eos

	def test_segmentation
		assert_equal SEGMENTED.chomp, ORIGINAL.segment(2, 30)
	end
end
