Filigree: For more beautiful Ruby
=================================

Filigree is a collection of classes, modules, and functions that I found myself re-writing in each of my projects.  In addition, I have thrown in a couple of other features that I've always wanted.  Here are some of Filigree's features:

* Abstract classes and methods
* An implementation of pattern matching
* An implementation of the Visitor pattern
* Extensions to standard library classes
* Module for defining class methods in a mixin
* Modules for configuration and command handling
* Easy dynamic type checking

I'm going to go over some of the more important features below, but I won't be able to cover everything.  Explore the rest of the documentation to discover additional features.

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
  
  # Returns :one
  foo(1)
  # Returns :other
  foo(42)
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

# Returns 42
matcher('hoopy')
# Returns 'hoopy'
matcher(42)
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

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/chriswailes/filigree/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
