# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/4/19
# Description:	Filigree's Rakefile.

##############
# Rake Tasks #
##############

# Gems
require 'rake/notes/rake_task'
require 'rake/testtask'
require 'bundler'

require File.expand_path("../lib/filigree/version", __FILE__)

begin
	require 'yard'

	YARD::Rake::YardocTask.new do |t|
		t.options	= [
			'--title',	'Filigree',
			'-m',		'markdown',
			'-M',		'redcarpet',
			'-c',		'.yardoc/cache',
			'--private'
		]
		
		
		t.files	= Dir['lib/**/*.rb']
	end
	
rescue LoadError
	warn 'Yard is not installed. `gem install yard` to build documentation.'
end

Rake::TestTask.new do |t|
	t.libs << 'test'
	t.loader = :testrb
	t.test_files = FileList['test/ts_filigree.rb']
end

# Bundler tasks.
Bundler::GemHelper.install_tasks

# Rubygems Taks
begin
	require 'rubygems/tasks'
	
	Gem::Tasks.new do |t|
		t.console.command = 'pry'
	end
	
rescue LoadError
	'rubygems-tasks not installed.'
end
