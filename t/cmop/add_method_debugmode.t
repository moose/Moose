
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Class::MOP::Mixin::HasMethods;

# When the Perl debugger is enabled, %DB::sub tracks method information
# (line numbers and originating file).  However, the reinitialize()
# functionality for classes and roles can sometimes clobber this information,
# causing to reference internal MOP files/lines instead.
# These tests check to make sure the the reinitialize() functionality
# preserves the correct debugging information when it (re)adds methods
# back into a class or role.

BEGIN {
     $^P = 831; # Enable debug mode
}

# Empty debugger
sub DB::DB {}

my ($foo_role_start, $foo_role_end, $foo_start_1, $foo_end_1, $foo_start_2, $foo_end_2);

# Simple Moose Role
{
    package FooRole;
    use Moose::Role;

    $foo_role_start = __LINE__ + 1;
    sub foo_role {
        return 'FooRole::foo_role';
    }
    $foo_role_end = __LINE__ - 1;
}

# Simple Moose package
{
    package Foo;
    use Moose;

    with 'FooRole';

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
my $bar_object = Bar->new();
isa_ok(Foo->meta->get_method('foo'), 'Moose::Meta::Method');
isa_ok(Bar->meta->get_method('foo'), 'Moose::Meta::Method');
isa_ok(Foo->meta->get_method('foo_role'), 'Moose::Meta::Method');
is($bar_object->foo_role(), 'FooRole::foo_role', 'Bar object has access to foo_role method');

# Run tests against Bar meta class...

my $bar_meta = Bar->meta;
like($DB::sub{"Bar::foo"}, qr/add_method_debugmode\.t:($foo_start_2)-($foo_end_2)/, "Check line numbers for  Bar::foo (initial)");

# Run _restore_metamethods_from directly (part of the reinitialize() process)
$bar_meta->_restore_metamethods_from($bar_meta);
like($DB::sub{"Foo::foo"}, qr/add_method_debugmode\.t:($foo_start_1)-($foo_end_1)/, "Check line numbers for Foo::foo (after _restore)");
like($DB::sub{"Bar::foo"}, qr/add_method_debugmode\.t:($foo_start_2)-($foo_end_2)/, "Check line numbers for Bar::foo (after _restore)");

# Call reinitialize explicitly, which triggers HasMethods::add_method
is( exception {
    $bar_meta = $bar_meta->reinitialize('Bar');
}, undef );
isa_ok(Bar->meta->get_method('foo'), 'Moose::Meta::Method');
like($DB::sub{"Foo::foo"}, qr/add_method_debugmode\.t:($foo_start_1)-($foo_end_1)/, "Check line numbers for Foo::foo (after reinitialize)");
like($DB::sub{"Bar::foo"}, qr/add_method_debugmode\.t:($foo_start_2)-($foo_end_2)/, "Check line numbers for Bar::foo (after reinitialize)");

# Add a method to Bar; this triggers reinitialize as well
# Check that method line numbers are still listed as part of this file, and not a MOP file
$bar_meta->add_method('foo2' => sub { return 'new method foo2'; });
like($DB::sub{"Foo::foo"}, qr/add_method_debugmode\.t:($foo_start_1)-($foo_end_1)/, "Check line numbers for Foo::foo (after add_method)");
like($DB::sub{"Bar::foo"}, qr/add_method_debugmode\.t:($foo_start_2)-($foo_end_2)/, "Check line numbers for Bar::foo (after add_method)");
like($DB::sub{"Bar::foo2"}, qr/(.*):(\d+)-(\d+)/, "Check for existence of Bar::foo2");

# Clobber Bar::foo by adding a method with the same name
$bar_meta->add_method(
    'foo' => $bar_meta->method_metaclass->wrap(
        package_name => $bar_meta->name,
        name => 'foo',
        body => sub { return 'clobbered Bar::foo'; }
    )
);
unlike($DB::sub{"Bar::foo"}, qr/add_method_debugmode\.t/, "Check that source file for Bar::foo has changed");

# Run tests against FooRole meta role ...

my $foorole_meta = FooRole->meta;
like($DB::sub{"FooRole::foo_role"}, qr/add_method_debugmode\.t:($foo_role_start)-($foo_role_end)/, "Check line numbers for FooRole::foo_role (initial)");

# Call _restore_metamethods_from directly
$foorole_meta->_restore_metamethods_from($foorole_meta);
like($DB::sub{"FooRole::foo_role"}, qr/add_method_debugmode\.t:($foo_role_start)-($foo_role_end)/, "Check line numbers for FooRole::foo_role (after _restore)");

# Call reinitialize
# Check that method line numbers are still listed as part of this file
is( exception {
    $foorole_meta->reinitialize('FooRole');
}, undef );
isa_ok(FooRole->meta->get_method('foo_role'), 'Moose::Meta::Method');
like($DB::sub{"FooRole::foo_role"}, qr/add_method_debugmode\.t:($foo_role_start)-($foo_role_end)/, "Check line numbers for FooRole::foo_role (after reinitialize)");

# Clobber foo_role method
$foorole_meta->add_method(
    'foo_role' => $foorole_meta->method_metaclass->wrap(
        package_name => $foorole_meta->name,
        name => 'foo_role',
        body => sub { return 'clobbered FooRole::foo_role'; }
    )
);
unlike($DB::sub{"FooRole::foo_role"}, qr/add_method_debugmode\.t/, "Check that source file for FooRole::foo_role has changed");

done_testing;
