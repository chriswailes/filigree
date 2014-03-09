Filigree: For more beautiful Ruby
=================================

<div style="float: left">
![Filigree: For more beautiful Ruby](https://github.com/chriswailes/filigree/raw/master/resources/filigree_logo_large.jpg)
</div>

Filigree is a collection of classes, modules, and functions that I found myself re-writing in each of my projects.  In addition, I have thrown in a couple of other features that I've always wanted.  Most of these features can be used independently.  Bellow is a list of many of the files and the features that each file provides:

* **filigree/abstract_class.rb** - Abstract class and method implementations
* **filigree/application.rb** - A basic application framework
* **filigree/class_methods_module.rb** - Easy way to include class methods in a mixin
* **filigree/commands.rb** - Framework for defining and processing command lines
* **filigree/configuration.rb** - Framework for parsing configuration strings
* **filigree/match.rb** - An implementation of pattern matching for Ruby
* **filigree/request_file.rb** - Conditionally do something if a file can be included; great for Rakefiles
* **filigree/types.rb** - Helper functions/classes for type checking ruby code; great for FFI integration
* **filigree/visitor.rb** - Implementation of the Visitor pattern based on pattern matching library

The above is not a complete list of files provided by this gem, and the documentation bellow only covers the most important features of the library.  Explore the rest of the documentation to discover additional features.

Abstract Classes and Methods
----------------------------

Abstract classes as methods can be defined as follows:

```Ruby
class Foo
  extend Filigree::AbstractClass

  abstract_method :must_implement
end

class Bar < Foo;

# Raises an AbstractClassError
Foo.new

# Returns a new instance of Bar
Bar.new

# Raieses an AbstractMethodError
Bar.new.must_implement
```

Pattern Matching
----------------

Filigree provides an implementation of pattern matching.  When performing a match objects are tested against patterns defined inside the *match block*:

```Ruby
def fib(n)
  match n do
    with(1)
    with(2) { 1 }
    with(_) { fib(n-1) + fib(n-2) }
  end
end
```

The most basic pattern is the literal.  Here, the object or objects being matched will be tested for equality with the value passed to `with`.  Another simple pattern is the wildcard pattern.  It will match any value; you can think of it as the default case.

```Ruby
  def foo(n)
    match n do
      with(1) { :one   }
      with(2) { :two   }
      with(_) { :other }
    end
  end
  
  foo(1)  # => :one
  foo(42) # => :other
```

You may also match against variables.  This can sometimes conflict with the next kind of pattern, which is a binding pattern.  Here, the pattern will match any object, and then make the object it matched available to the *with block* via an attribute reader.  This is accomplished using the method_missing callback, so if there is a variable or function with that name you might accidentally compare against a variable or returned value.  To bind to a name that is already in scope you can use the {Filigree::MatchEnvironment#Bind} method.  In addition, class and destructuring pattern results (see bellow) can be bound to a variable by using the {Filigree::BasicPattern#as} method. 

```Ruby
var = 42

# Returns :hoopy
match 42 do
  with(var) { :hoopy }
  with(0)   { :zero  }
end

# Returns 42
match 42 do
  with(x) { x }
end

x = 3
# Returns 42
match 42 do
  with(Bind(:x)) { x      }
  with(42)       { :hoopy }
end
```

If you wish to match string patterns you can use regular expressions.  Any object that isn't a string will fail to match against a regular expression. If the object being matched is a string then the regular expressions `match?` method is used.  The result of the regular expression match is available inside the *with block* via the match_data accessor.

```Ruby
def matcher(object)
 match object do
   with(/hoopy/) { 42      }
   with(Integer) { 'hoopy' }
 end
end

matcher('hoopy') # => 42
matcher(42)      # => 'hoopy'
```

When a class is used in a pattern it will match any object that is an instance of that class.  If you wish to compare one regular expression to
another, or one class to another, you can force the comparison using the {Filigree::MatchEnvironment#Literal} method.

Destructuring patterns allow you to match against an instance of a class, while simultaneously binding values stored inside the object to variables in the context of the *with block*.  A class that is destructurable must include the {Filigree::Destructurable} module.  You can then destructure an object like this:

```Ruby
class Foo
  include Filigree::Destructurable
    def initialize(a, b)
    @a = a
    @b = b
  end

  def destructure(_)
    [@a, @b]
  end
end

# Returns true
match Foo.new(4, 2) do
  with(Foo.(4, 2)) { true  }
  with(_)          { false }
end
```

Of particular note is the destructuring of arrays.  When an array is destructured like so, `Array.(xs)`, the array is bound to `xs`.  If an additional pattern is added, `Array.(x, xs)`, then `x` will hold the first element of the array and `xs` will hold the remaining characters.  As more patterns are added more elements will be pulled off of the front of the array.  You can match an array with a specific number of elements by using an empty array literal: `Array.(x, [])`

Both `match` and `with` can take multiple arguments.  When this happens, each object is paired up with the corresponding pattern.  If they all match, then the `with` clause matches.  In this way you can match against tuples.

Any with clause can be given a guard clause by passing a lambda as the last argument to `with`.  These are evaluated after the pattern is matched, and any bindings made in the pattern are available to the guard clause.

```Ruby
match o do
  with(n, -> { n < 0 }) { :NEG  }
  with(0)               { :ZERO }
  with(n, -> { n > 0 }) { :POS  }
end
```

If you wish to evaluate the same body on matching any of several patterns you may list them in order and then specify the body for the last pattern in the group.

Patterns are evaluated in the order in which they are defined and the first pattern to match is the one chosen.  You may define helper methods inside the match block.  They will be re-defined every time the match statement is evaluated, so you should move any definitions outside any match calls that are being evaluated often.

A Visitor Pattern
-----------------

Filigree's implementation of the visitor pattern is built on the pattern matching functionality described above.  It's usage is pretty simple:

```Ruby
class Binary < Struct.new(:x, :y)
  extend  Filigree::Destructurable
  include Filigree::Visitor
  
  def destructure(_)
    [x, y]
  end
end

class Add < Binary; end
class Mul < Binary; end

class MathVisitor
  include Filigree::Visitor
  
  on(Add.(x, y)) do
    x + y
  end
  
  on(Mul.(x, y)) do
    x * y
  end
end

mv = MathVisitor.new

mv.visit(Add.new(6, 8)) # => 14
mv.visit(Mul.new(7, 6)) # => 42
```

The only complicated aspect of the Visitor mixin is the method used to select the order in which the patterns are tested.  If patterns were tested in order of definition then a subclass of a visitor would be unable to define a more specific pattern than one defined int he parent visitor.  To address this issue the most _specific_ patterns are tested first.  This gets a bit complicated when it gets to destructuring patterns, but most cases are fairly simple.  Pattern specificity is as follows:

1. Literals
2. Destructurings
3. Regular expressions
4. Instances
5. Wildcard

There are special rules for destructuring and instance patterns.  In both cases, a pattern for a subclass is preferred to a pattern for a superclass.  Destructuring patterns have the additional rule that longer, more specific destructurings are preferred to shorter, less specific destructurings.  Lastly, any pattern that has a guard expression is more specific than an otherwise equivalent expression that doesn't have a guard expression.

Class Methods
-------------

{Filigree::ClassMethodsModule} makes it easy to add class methods to mixins:

```Ruby
module Foo
  include Filigree::ClassMethodsModule

  def foo
	  :foo
  end

  module ClassMethods
	  def bar
		  :bar
	  end
  end
end

class Baz
  include Foo
end

Baz.new.foo # => :foo
Ba.bar      # => :bar
```

Configuration Handling
----------------------

{Filigree::Configuration} will help you parse command line options:

```Ruby
class MyConfig
  include Filigree::Configuration
  
  add_option Filigree::Configuration::HELP_OPTION
  
  help 'Sets the target'
  required
  string_option 'target', 't'
  
  help 'Set the port for the target'
  default 1025
  option 'port', 'p', conversions: [:to_i]
  
  help 'Set credentials'
  default ['user', 'password']
  option 'credentials', 'c', conversions: [:to_s, :to_s]
  
  help 'Be verbose'
  bool_option 'verbose', 'v'
  
  auto 'next_port' { self.port + 1 }
  
  help 'load data from file'
  option 'file', 'f' do |f|
    process_file f
  end
end

# Defaults to parsing ARGV
conf = MyConfig.new(['-t', 'localhost', '-v'])

conf.target    # => 'localhost'
conf.next_port # => 1026

# You can searialize configurations to a strings, file, or IO objects
serialized_config = conf.dump
# And then load the configuration from the serialized version
conf = MyConfig.new serialized_config
```

Command Handling
----------------

Now that we can parse configuration options, how about we handle commands?

```Ruby
class MyCommands
  include Filigree::Commands
  
  help 'Adds two numbers together'
  param 'x', 'The first number to add'
  param 'y', 'The second number to add'
  command 'add' do |x, y|
    x.to_i + y.to_i
  end
  
  help 'Say hello from the command handler'
  config do
    default 'world'
    string_option 'subject', 's' 
  end
  command 'hello' do
    "hello #{subject}"
  end
end

mc = MyCommands.new

mc.('add 35 7')       # => 42
mc.('hello')          # => 'hello world'
mc.('hello -s chris') # => 'hello chris'
```

Type Checking
-------------

Filigree provides two ways to perform basic type checking at run time:

1. {check_type} and {check_array_type}
2. {Filigree::TypedClass}

The first option will simply check the type of an object or an array of objects.  Optionally, you can assign blame to a named variable, allow the value to be nil, or perform strict checking.  Strict checking uses the `instance_of?` method while non-strict checking uses `is_a?`.

The second option works like so:

```Ruby
class Foo
	include Filigree::TypedClass
	
	typed_ivar :bar, Integer
	typed_ivar :baz, String
	
	default_constructor
end

var = Foo.new(42, '42')
var.bar = '42' # Raises a TypeError
```

Contributing
------------

Do you have bits of code that you use in all of your projects but arn't big enough for theirn own gem?  Well, maybe your code could find a home in Filigree!  Send me a patch that includes the useful bits and some tests and I'll se about adding it.

Other than that, what Filigree really needs is uses.  Add it to your project and let me know what features you use and which you don't; where you would like to see improvements, and what pieces you really liked.  Above all, submit issues if you encountere any bugs!

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/chriswailes/filigree/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
