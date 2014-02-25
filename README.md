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

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/chriswailes/filigree/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
