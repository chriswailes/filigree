# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/4/19
# Description:	Gem specification for the Filigree project.

require File.expand_path("../lib/filigree/version", __FILE__)

Gem::Specification.new do |s|
	s.platform = Gem::Platform::RUBY
	
	s.name		= 'Filigree'
	s.version		= Filigree::VERSION
	s.summary		= 'Extra functionality for Ruby.'
	s.description	= 'Filigree provides new classes and extensions to core library classes ' +
				  'that add functionality to the Ruby.'
	
	s.files = [
			'LICENSE',
			'AUTHORS',
			'README.md',
			'Rakefile',
			] +
			Dir.glob('lib/**/*.rb')
			
			
	s.require_path	= 'lib'
	
	s.author		= 'Chris Wailes'
	s.email		= 'chris.wailes@gmail.com'
	s.homepage	= 'https://github.com/chriswailes/filigree'
	s.license		= 'University of Illinois/NCSA Open Source License'
	
	s.required_ruby_version = '2.0.0'
	
	s.test_files = Dir.glob('test/tc_*.rb') + Dir.glob('test/ts_*.rb')
	
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
	s.add_development_dependency('pry')
	s.add_development_dependency('rake')
	s.add_development_dependency('rake-notes')
	s.add_development_dependency('reek')
	s.add_development_dependency('rubygems-tasks')
	s.add_development_dependency('simplecov')
	s.add_development_dependency('yard', '>= 0.8.1')
end
