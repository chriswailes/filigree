# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/05/15
# Description:	Test cases the Configuration module.

############
# Requires #
############

# Standard Library
require 'test/unit'

# Filigree
require 'filigree/configuration'

#######################
# Classes and Modules #
#######################

class ConfigurationTester < Test::Unit::TestCase
	class TestConfig
		include Filigree::Configuration
		
		help 'Does foo.'
		default { moo.to_s }
		option 'foo', 'f' do |s|
			s
		end
		
		help 'This is a longer help message to test and see how the string segmentation works.  I hope it is long enough.'
		default 42
		option 'bar', 'b', :to_i
		
		help 'Does baz.'
		option 'baz', 'z', :to_sym, :to_sym
		
		help 'Does moo.'
		required
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
	
	def setup
		@defaults = ['--moo', '10']
	end
	
	def test_auto
		conf = TestConfig.new @defaults
		
		assert_equal 20, conf.cow
	end
	
	def test_defaults
		conf = TestConfig.new @defaults
		
		assert_equal 42, conf.bar
		assert_equal '60', conf.foo
	end
	
	def test_long_option
		conf = TestConfig.new @defaults
		
		assert_equal 60, conf.moo
	end
	
	def test_proc_handler
		conf = TestConfig.new (@defaults + ['--foo', 'hello world'])
		
		assert_equal 'hello world', conf.foo
	end
	
	def test_required
		assert_raise(ArgumentError)	{ TestConfig.new([]) }
		assert_nothing_raised		{ TestConfig.new(@defaults) }
	end
	
	def test_short_option
		conf = TestConfig.new ['-m', 10]
		
		assert_equal 60, conf.moo
	end
	
	def test_splat
		conf = TestConfig.new (['-d', 'a', 'b', 'c'] + @defaults)
		
		assert_equal [:a, :b, :c], conf.daf
	end
	
	def test_symbol_handler
		conf = TestConfig.new (@defaults + ['-b', '42'])
		assert_equal 42, conf.bar
		
		conf = TestConfig.new (@defaults + ['-z', 'a', 'b'])
		assert_equal [:a, :b], conf.baz
	end
end
