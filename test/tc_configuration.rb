# Author:		Chris Wailes <chris.wailes+filigree@gmail.com>
# Project: 	Filigree
# Date:		2013/05/15
# Description:	Test cases the Configuration module.

############
# Requires #
############

# Gems
require 'minitest/autorun'

# Filigree
require 'filigree/configuration'

#######################
# Classes and Modules #
#######################

class ConfigurationTester < Minitest::Test
	class TestConfig
		include Filigree::Configuration

		help 'Does foo.'
		default { moo.to_s }
		string_option 'foo', 'f'

		help 'This is a longer help message to test and see how the string segmentation works. I hope it is long enough.'
		default 42
		option 'bar', 'b', conversions: [:to_i]

		help 'Does baz.'
		option 'baz', 'z', conversions: [:to_sym, :to_sym]

		help 'Does moo.'
		required
		option 'moo', 'm' do |i|
			i.to_i * 6
		end

		help 'This does daf'
		option 'daf', 'd' do |*strings|
			strings.map { |str| str.to_sym }
		end

		help 'Storage testing parameter'
		required
		string_option 'cat', 'c', storage: 'chaos'

		bool_option :bool

		help 'Default argument param test option'
		option 'dog' do |arg = 'woof'|
			arg
		end

		auto :cow do
			self.moo / 3
		end
	end

	def setup
		@defaults = ['--moo', '10', '--cat', 'meow']
	end

	def test_auto
		conf = TestConfig.new(@defaults)

		assert_equal(20, conf.cow)
	end

	def test_bool_option
		conf = TestConfig.new(@defaults)
		assert(!conf.bool, 'Boolean flag set in config object')

		conf = TestConfig.new(@defaults + ['--bool'])
		assert(conf.bool, 'Boolean flag not set in config object')
	end

	def test_defaults
		conf = TestConfig.new(@defaults)

		assert_equal(42, conf.bar)
		assert_equal('60', conf.foo)
	end

	def test_defualt_arguments
		conf = TestConfig.new(@defaults + ['--dog'])
		assert_equal('woof', conf.dog)

		conf = TestConfig.new(@defaults + ['--dog', 'bark'])
		assert_equal('bark', conf.dog)
	end

	def test_long_option
		conf = TestConfig.new(@defaults)

		assert_equal(60, conf.moo)
	end

	def test_proc_handler
		conf = TestConfig.new(@defaults + ['--foo', 'hello world'])

		assert_equal('hello world', conf.foo)
	end

	def test_required
		assert_raises(ArgumentError) { TestConfig.new([]) }
		TestConfig.new(@defaults)
	end

	def test_serialization
		require 'tempfile'

		conf = TestConfig.new(@defaults + ['-f', 'hello world', '-b', '32', '-z', 'a', 'b'])

		yaml_string = conf.dump

		conf = TestConfig.new(yaml_string)

		assert_equal(60,            conf.moo)
		assert_equal('hello world',	conf.foo)
		assert_equal(32,            conf.bar)
		assert_equal([:a, :b],      conf.baz)

		yaml_file      = Tempfile.new('tc_configuration_serialization')
		yaml_file_path = yaml_file.path
		yaml_file.close

		# Dump the file.
		File.open(yaml_file_path, 'w') { |f| conf.dump f }

		# Load the configuration from the file.
		conf = File.open(yaml_file_path, 'r') { |f| TestConfig.new f }

		assert_equal(60,            conf.moo)
		assert_equal('hello world', conf.foo)
		assert_equal(32,            conf.bar)
		assert_equal([:a, :b],      conf.baz)

		# Remove the file.
		FileUtils.rm(yaml_file_path)

		# Re-create an empty file.
		FileUtils.touch(yaml_file_path)

		# Dump the config again.
		conf.dump(yaml_file_path)

		# Load the configuration again.
		conf = TestConfig.new(yaml_file_path)

		assert_equal(60,            conf.moo)
		assert_equal('hello world', conf.foo)
		assert_equal(32,            conf.bar)
		assert_equal([:a, :b],      conf.baz)

		#########################
		# Partial Serialization #
		#########################

		yaml_string = conf.dump(nil, :moo, :foo, :bar, :chaos)

		conf = TestConfig.new(yaml_string)

		assert_equal(60,			conf.moo)
		assert_equal('hello world',	conf.foo)
		assert_equal(32,			conf.bar)
		assert_equal('meow',        conf.chaos)
	end

	def test_short_option
		conf = TestConfig.new(['-m', 10, '-c', 'meow'])

		assert_equal 60, conf.moo
	end

	def test_splat
		conf = TestConfig.new(['-d', 'a', 'b', 'c'] + @defaults)

		assert_equal([:a, :b, :c], conf.daf)
	end

	def test_symbol_handler
		conf = TestConfig.new(@defaults + ['-b', '32'])
		assert_equal(32, conf.bar)

		conf = TestConfig.new(@defaults + ['-z', 'a', 'b'])
		assert_equal([:a, :b], conf.baz)
	end
end
