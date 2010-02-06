#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# this case started breaking in 0.92
{
    package Foo;
    sub new { bless {}, shift }
}

{
    package Foo::Meta::Trait;
    use Moose::Role;
}

{
    package Foo::Moose;
    use Moose -traits => [qw(Foo::Meta::Trait)];
    extends 'Foo';
}

ok(!Class::MOP::Class->initialize('Foo')->isa('Moose::Meta::Class'),
   "we don't get a moose metaclass for nonmoose classes");

# this case was broken before 0.90, not sure if it ever worked properly
{
    package Bar;
    sub new { bless {}, shift }
}

{
    package Bar::Sub;
    use base 'Bar';
}

{
    package Bar::Meta::Trait;
    use Moose::Role;
}

{
    package Bar::Moose;
    use Moose -traits => [qw(Bar::Meta::Trait)];
    extends 'Bar::Sub';
    __PACKAGE__->meta->make_immutable(inline_constructor => 0);
}

ok(!Class::MOP::Class->initialize('Bar')->isa('Moose::Meta::Class'),
   "we don't get a moose metaclass for nonmoose classes");

done_testing;
