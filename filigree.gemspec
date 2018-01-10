# Author:      Chris Wailes <chris.wailes@gmail.com>
# Project:     Filigree
# Date:        2013/4/19
# Description: Gem specification for the Filigree project.

# Add the Filigree source directory to the load path.
lib_dir = File.expand_path("./lib/", File.dirname(__FILE__))
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'filigree/version'

Gem::Specification.new do |s|
	s.platform = Gem::Platform::RUBY

	s.name        = 'filigree'
	s.version     = Filigree::VERSION
	s.summary     = 'Extra functionality for Ruby.'
	s.description = 'Filigree provides new classes and extensions to core library classes ' +
	                'that add functionality to Ruby.'

	s.files = [
		'LICENSE',
		'AUTHORS',
		'README.md',
		'Rakefile',
	] +
	Dir.glob('lib/**/*.rb')

	s.test_files = Dir.glob('test/tc_*.rb') +
	               Dir.glob('test/ts_*.rb')

	s.require_path	= 'lib'

	s.author   = 'Chris Wailes'
	s.email    = 'chris.wailes+filigree@gmail.com'
	s.homepage = 'https://github.com/chriswailes/filigree'
	s.license  = 'University of Illinois/NCSA Open Source License'

	s.required_ruby_version = '>= 2.4.0'

	################
	# Dependencies #
	################

	############################
	# Development Dependencies #
	############################

	s.add_development_dependency('bundler')
	s.add_development_dependency('flay')
	s.add_development_dependency('flog')
	s.add_development_dependency('minitest')
	s.add_development_dependency('rake')
	s.add_development_dependency('rake-notes')
	s.add_development_dependency('reek')
	s.add_development_dependency('simplecov')
	s.add_development_dependency('yard', '>= 0.9.9')
end
