#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
use Scalar::Util 'blessed';

BEGIN {
    use_ok('Moose');
    use_ok("Moose::Util::TypeConstraints");
}

subtype 'Positive'
     => as 'Num'
     => where { $_ > 0 };

{
    package Parent;
    use Moose;

    has name => (
        is       => 'rw',
        isa      => 'Str',
    );

    has lazy_classname => (
        is      => 'ro',
        lazy    => 1,
        default => sub { "Parent" },
    );

    has type_constrained => (
        is      => 'rw',
        isa     => 'Num',
        default => 5.5,
    );

    package Child;
    use Moose;
    extends 'Parent';

    has '+name' => (
        default => 'Junior',
    );

    has '+lazy_classname' => (
        default => sub { "Child" },
    );

    has '+type_constrained' => (
        isa     => 'Int',
        default => 100,
    );
}

my $foo = Parent->new;
my $bar = Parent->new;

is(blessed($foo), 'Parent', 'Parent->new gives a Parent object');
is($foo->name, undef, 'No name yet');
is($foo->lazy_classname, 'Parent', "lazy attribute initialized");
lives_ok { $foo->type_constrained(10.5) } "Num type constraint for now..";

# try to rebless, except it will fail due to Child's stricter type constraint
throws_ok { Child->meta->rebless_instance($foo) } 
qr/^Attribute \(type_constrained\) does not pass the type constraint because\: Validation failed for 'Int' failed with value 10\.5/,
'... this failed cause of type check';
throws_ok { Child->meta->rebless_instance($bar) } 
qr/^Attribute \(type_constrained\) does not pass the type constraint because\: Validation failed for 'Int' failed with value 5\.5/,
'... this failed cause of type check';;

$foo->type_constrained(10);
$bar->type_constrained(5);

Child->meta->rebless_instance($foo);
Child->meta->rebless_instance($bar);

is(blessed($foo), 'Child', 'successfully reblessed into Child');
is($foo->name, 'Junior', "Child->name's default came through");

is($foo->lazy_classname, 'Parent', "lazy attribute was already initialized");
is($bar->lazy_classname, 'Child', "lazy attribute just now initialized");

throws_ok { $foo->type_constrained(10.5) } 
qr/^Attribute \(type_constrained\) does not pass the type constraint because\: Validation failed for 'Int' failed with value 10\.5/,
'... this failed cause of type check';
