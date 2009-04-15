#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use Moose ();

BEGIN {

    package My::Meta::Role;
    use Moose;
    extends 'Moose::Meta::Role';

    has test_serial => (
        is      => 'ro',
        isa     => 'Int',
        default => 1,
    );
    no Moose;

}
{

    package MyRole;
    use metaclass 'Moose::Meta::Class' =>
        ( role_metaclass => 'My::Meta::Role' );
    use Moose::Role;

    no Moose::Role;

    package MyOtherRole;
    use Moose::Role;

    no Moose::Role;
};

isa_ok( MyRole->meta, 'My::Meta::Role' );
isa_ok( MyOtherRole->meta, 'Moose::Meta::Role' );

# my $role = MyRole->meta->create_anon_role;
# is( $role->test_serial, 1, "default value for the serial attribute" );
