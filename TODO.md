# Bugs

* Change auto-initialized variables in Configuration classes so that they are only initialized once.
  * A new dictionary should keep name/proc pairs during definition time.  During initialization,
    after ARGV has been processed, the procs should be evaluated and a new method with the give name
    should be defined that returns this value.

# Features

* Move help option and command testing to unit tests.
* Add support for including one Visitor in another?

# Review

# Updates
