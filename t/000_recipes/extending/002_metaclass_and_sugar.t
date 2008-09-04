#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;


{
    package MyApp::Meta::Class;
    use Moose;

    extends 'Moose::Meta::Class';

    has 'table' => ( is => 'rw' );

    no Moose;

    package MyApp::Mooseish;

    use strict;
    use warnings;

    use Moose ();
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        with_caller => ['has_table'],
        also        => 'Moose',
    );

    sub init_meta {
        shift;
        Moose->init_meta( @_, metaclass => 'MyApp::Meta::Class' );
    }

    sub has_table {
        my $caller = shift;
        $caller->meta()->table(shift);
    }
}

{
    package MyApp::User;

    MyApp::Mooseish->import;

    has_table( 'User' );

    has( 'username' => ( is => 'ro' ) );
    has( 'password' => ( is => 'ro' ) );

    sub login { }
}

isa_ok( MyApp::User->meta, 'MyApp::Meta::Class' );
is( MyApp::User->meta->table, 'User',
    'MyApp::User->meta->table returns User' );
ok( MyApp::User->can('username'),
    'MyApp::User has username method' );
