# Author:		Chris Wailes <chris.wailes@gmail.com>
# Project: 	Filigree
# Date:		2013/4/19
# Description:	Filigree's Rakefile.

############
# Requires #
############

# Project
require File.expand_path("../lib/filigree/version", __FILE__)

###########
# Bundler #
###########

begin
	require 'bundler'
	
	Bundler::GemHelper.install_tasks
	
rescue LoadError
	warn "Bundler isn't installed. `gem install bundler` to bundle."
end

############
# MiniTest #
############

begin
	require 'rake/testtask'
	
	Rake::TestTask.new do |t|
		t.libs << 'test'
		t.test_files = FileList['test/ts_filigree.rb']
	end
rescue LoadError
	warn "Minitest isn't installed. `gem install minitest` to test."
end

#########
# Notes #
#########

begin
	require 'rake/notes/rake_task'
rescue LoadError
	warn "Rake-notes isn't installed."
end

########
# Reek #
########

begin
	require 'reek/rake/task'

	Reek::Rake::Task.new do |t|
	  t.fail_on_error = false
	end
	
rescue LoadError
	warn "Reek ins't installed.  `gem install reek` to smell."
end

##################
# Rubygems Tasks #
##################

begin
	require 'rubygems/tasks'
	
	Gem::Tasks.new do |t|
		t.console.command = 'pry'
	end
	
rescue LoadError
	warn "rubygems-tasks isn't installed."
end

########
# YARD #
########

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
	warn "Yard isn't installed. `gem install yard` to build documentation."
end
