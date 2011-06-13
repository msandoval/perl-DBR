A different approach to ORM for perl
===

DBR (stands for Database Repository) is a fairly directed attempt at an Object Relational Mapper. It is not trying to be all things to all people. It's focus is on managing large schemas with an emphasis on metadata, rather than defining schema structure with code.

Get the source:

    git clone git://github.com/dnorman/perl-DBR.git

Examples:

 The examples work right out of the box

    cd example
    perl example_basic.pl
    perl example_join.pl
    perl example_moderate.pl
    ...

To build:

    perl Makefile.PL
    make
    sudo make install

To run the tests:

    make test

The documentation:

    SETUP.md
    doc/objects_and_methods.pdf
    [The wiki (pretty flimsy right now) ](http://code.google.com/p/perl-dbr/w/list)
    *more documentation coming soon*

Resources:
---

  - [The latest source ( Please fork and contribute! )](http://github.com/dnorman/perl-DBR)
  - [CPAN page](http://search.cpan.org/~impious/DBR/)
  - [The wiki (pretty flimsy right now) ](http://code.google.com/p/perl-dbr/w/list)
