#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Class::MOP::Mixin::HasMethods;

BEGIN {
     $^P = 831; # Enable debug mode
}

# Empty debugger
sub DB::DB {}

# Simple Moose package
{
    package Foo;
    use Moose;

    sub foo {
        return 'foo';
    }

    no Moose;
}

# Extend our simple Moose package, with overriding method
{
    package Bar;
    use Moose;

    extends 'Foo';

    sub foo {                  
        return 'bar';          
    }                          

    no Moose;
}

# Check that Foo and Bar classes were set up correctly
my $meta = Bar->meta;
isa_ok(Bar->meta->get_method('foo'), 'Moose::Meta::Method');
isa_ok(Bar->meta->get_method('foo'), 'Moose::Meta::Method');

# Call reinitialize explicitly, which triggers HasMethods::add_method
is( exception {
    $meta = $meta->reinitialize('Bar');
}, undef );
isa_ok(Bar->meta->get_method('foo'), 'Moose::Meta::Method');

# Check that method line numbers are still listed as part of this file, and not a MOP file
like($DB::sub{"Foo::foo"}, qr/add_method_debugmode.t:(\d+)-(\d+)/, "Check line numbers for Foo::foo (1)");
like($DB::sub{"Bar::foo"}, qr/add_method_debugmode.t:(\d+)-(\d+)/, "Check line numbers for Bar::foo (1)");

# Add a method to Bar; this triggers reinitialize as well
$meta->add_method('foo2' => sub { return 0; });

# Check that method line numbers are still listed as part of this file, and not a MOP file
like($DB::sub{"Foo::foo"}, qr/add_method_debugmode.t:(\d+)-(\d+)/, "Check line numbers for Foo::foo (2)");
like($DB::sub{"Bar::foo"}, qr/add_method_debugmode.t:(\d+)-(\d+)/, "Check line numbers for Bar::foo (2)");
# The new method foo2 will not have line numbers defined in add_method_debugmode.t
like($DB::sub{"Bar::foo2"}, qr/(.*):(\d+)-(\d+)/, "Check for existence of Bar::foo2");

done_testing;