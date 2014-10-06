#!/usr/bin/ruby

$: << '../lib'

require 'filigree/commands'

class TestCommands
	include Filigree::Commands

	add_command Filigree::Commands::HELP_COMMAND

	param :param_one, 'This is the first parameter.'
	param :param_two, 'This is the second parameter.  It has many uses, many of them mysteriously shrouded in mystery.'
	command 'bar' do |a, b|
		:bar
	end

	config do
		help 'Does baz.'
		bool_option 'baz', 'b'

		help 'Does zap, but a lot of zap so that I can test segmentation alignment.'
		bool_option 'zap'
	end
	param :what, 'What the foo to do.'
	command 'foo' do |what|
		:foo
	end
end

TestCommands.new.('help')
