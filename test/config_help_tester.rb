#!/usr/bin/ruby

$: << '../lib'

require 'filigree/configuration'

class TestConfig
	include Filigree::Configuration
	
	add_option Filigree::Configuration::HELP_OPTION
	
	usage './config_help_tester [options]'
	
	help 'Does foo.'
	default { moo.to_s }
	option 'foo', 'f' do |s|
		s
	end
	
	help 'This is a longer help message to test and see how the string segmentation works. I hope it is long enough.'
	default 42
	option 'bar', 'b', :to_i
	
	help 'Does baz.'
	option 'baz', 'z', :to_sym, :to_sym
	
	help 'Does moo.'
	option 'moo', 'm' do |i|
		i.to_i * 6
	end
	
	help 'This does zoom'
	option 'daf', 'd' do |*syms|
		syms.map { |syms| syms.to_sym }
	end
	
	auto :cow do
		self.moo / 3
	end
end

TestConfig.new ['-h']
