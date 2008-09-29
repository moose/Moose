#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    unless ( eval 'use Test::Warn 0.10; 1' )  {
        plan skip_all => 'These tests require Test::Warn 0.10+';
    }
    else {
        plan tests => 4;
    }
}

{
    package MyApp::Base;
    use Moose;

    extends 'Moose::Object';

    before 'new' => sub { warn "Making a new " . $_[0] };

    no Moose;
}

{
    package MyApp::UseMyBase;
    use Moose ();
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods( also => 'Moose' );

    sub init_meta {
        shift;
        Moose->init_meta( @_, base_class => 'MyApp::Base' );
    }
}

{
    package Foo;

    MyApp::UseMyBase->import;

    has( 'size' => ( is => 'rw' ) );
}

ok( Foo->isa('MyApp::Base'),
    'Foo isa MyApp::Base' );

ok( Foo->can('size'),
    'Foo has a size method' );

my $foo;
warning_is( sub { $foo = Foo->new( size => 2 ) },
            'Making a new Foo',
            'got expected warning when calling Foo->new' );

is( $foo->size(), 2, '$foo->size is 2' );

