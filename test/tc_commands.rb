# Author:      Chris Wailes <chris.wailes+filigree@gmail.com>
# Project:     Filigree
# Date:        2013/05/17
# Description: Test cases the Commands module.

############
# Requires #
############

# Standard Library
require 'minitest/autorun'

# Filigree
require 'filigree/commands'

#######################
# Classes and Modules #
#######################

class CommandTester < Minitest::Test
	class TestCommands
		include Filigree::Commands

		command 'foo' do
			:foo
		end

		command 'foo bar' do
			:foobar
		end

		command 'hello1' do |subject|
			"hello #{subject}"
		end

		config do
			default 'world'
			option 'subject', 's', conversions: [:to_s]
		end
		command 'hello2' do
			"hello #{subject}"
		end

		command 'add' do |x, y|
			x.to_i + y.to_i
		end
	end

	def setup
		@commander = TestCommands.new
	end

	def test_command_not_found
		assert_raises(CommandNotFoundError) { @commander.('bar') }
	end

	def test_command_args
		assert_equal 'hello world', @commander.('hello1 world')
		assert_equal 42, @commander.('add 27 15')
	end

	def test_command_with_wrong_args
		assert_raises(CommandArgumentError) { @commander.('hello1 cat dog') }
	end

	def test_configured_command
		assert_equal 'hello world', @commander.('hello2')
		assert_equal 'hello dog', @commander.('hello2 -s dog')
	end

	def test_subcommand
		assert_equal :foobar, @commander.('foo bar')
	end

	def test_zero_arg_command
		assert_equal :foo, @commander.('foo')
	end
end
