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

my ($foo_start_1, $foo_end_1, $foo_start_2, $foo_end_2);

# Simple Moose package
{
    package Foo;
    use Moose;

    # Track the start/end line numbers of method foo(), for comparison later
    $foo_start_1 = __LINE__ + 1;
    sub foo {
        return 'foo';
    }
    $foo_end_1 = __LINE__ - 1;

    no Moose;
}

# Extend our simple Moose package, with overriding method
{
    package Bar;
    use Moose;

    extends 'Foo';

    # Track the start/end line numbers of method foo(), for comparison later
    $foo_start_2 = __LINE__ + 1;
    sub foo {
        return 'bar';
    }
    $foo_end_2 = __LINE__ - 1;

    no Moose;
}

# Check that Foo and Bar classes were set up correctly
my $bar_meta = Bar->meta;
isa_ok(Bar->meta->get_method('foo'), 'Moose::Meta::Method');
isa_ok(Bar->meta->get_method('foo'), 'Moose::Meta::Method');

# Call reinitialize explicitly, which triggers HasMethods::add_method
is( exception {
    $bar_meta = $bar_meta->reinitialize('Bar');
}, undef );
isa_ok(Bar->meta->get_method('foo'), 'Moose::Meta::Method');

# Check that method line numbers are still listed as part of this file, and not a MOP file
like($DB::sub{"Foo::foo"}, qr/add_method_debugmode\.t:($foo_start_1)-($foo_end_1)/, "Check line numbers for Foo::foo (1)");
like($DB::sub{"Bar::foo"}, qr/add_method_debugmode\.t:($foo_start_2)-($foo_end_2)/, "Check line numbers for Bar::foo (1)");

# Add a method to Bar; this triggers reinitialize as well
$bar_meta->add_method('foo2' => sub { return 'new method foo2'; });

# Check that method line numbers are still listed as part of this file, and not a MOP file
like($DB::sub{"Foo::foo"}, qr/add_method_debugmode\.t:($foo_start_1)-($foo_end_1)/, "Check line numbers for Foo::foo (2)");
like($DB::sub{"Bar::foo"}, qr/add_method_debugmode\.t:($foo_start_2)-($foo_end_2)/, "Check line numbers for Bar::foo (2)");
# The new method foo2 will not have line numbers defined in add_method_debugmode.t
like($DB::sub{"Bar::foo2"}, qr/(.*):(\d+)-(\d+)/, "Check for existence of Bar::foo2");

# Clobber Bar::foo by adding a method with the same name
$bar_meta->add_method('foo' => sub { return 'clobbered Bar::foo'; });

# Check that DB::sub info for Bar::foo has changed
unlike($DB::sub{"Bar::foo"}, qr/add_method_debugmode.\t/, "Check that source file for Bar::foo has changed");

done_testing;
