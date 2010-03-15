#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

{
    package parent_role;
    use Moose::Role;

    # I just needed a value to write to, since the 'after' sub return value is ignored.
    has 'value' => (is => 'rw', isa => 'Str');

    sub foo { $_[0]->value('foo'); }
}

{
    package child_role1;
    use Moose::Role;

    with 'parent_role';

    after 'foo' => sub { $_[0]->value('after foo'); }
}

{
    package child_role2;
    use Moose::Role;

    with 'parent_role';
}

{
    package my_class;
    use Moose;

    with 'parent_role', 'child_role1';

    1;
}

my $base_case = new my_class;
$base_case->foo();
is($base_case->value, 'after foo', "after sub called for base case");

my $apply_child_role2 = new my_class;
Moose::Util::apply_all_roles($apply_child_role2, 'child_role2');
$apply_child_role2->foo();
is($apply_child_role2->value, 'after foo', "after sub called for base case + child_role2 added with apply_all_roles()");

my $ensure_child_role2 = new my_class;
Moose::Util::ensure_all_roles($ensure_child_role2, 'child_role2');
$ensure_child_role2->foo();
is($ensure_child_role2->value, 'after foo', "after sub called for base case + child_role2 added with ensure_all_roles()");

done_testing;
