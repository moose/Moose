#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

{
    package My::Role;
    use Moose::Role;

    sub foo { 'Foo::foo' }
    sub bar { 'Foo::bar' }
    sub baz { 'Foo::baz' }

    package My::Class;
    use Moose;

    with 'My::Role' => { excludes => 'bar' };
}

ok(My::Class->meta->has_method($_), "we have a $_ method") for qw(foo baz);
ok(!My::Class->meta->has_method('bar'), '... but we excluded bar');

{
    package My::OtherRole;
    use Moose::Role;

    with 'My::Role' => { excludes => 'foo' };

    sub foo { 'My::OtherRole::foo' }
    sub bar { 'My::OtherRole::bar' }
}

ok(My::OtherRole->meta->has_method($_), "we have a $_ method") for qw(foo bar baz);

ok(!My::OtherRole->meta->requires_method('foo'), '... and the &foo method is not required');
ok(My::OtherRole->meta->requires_method('bar'), '... and the &bar method is required');





