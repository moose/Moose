#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    unless ( eval 'use Test::Warn 0.10; 1' )  {
        plan skip_all => 'These tests require Test::Warn 0.10';
    }
    else {
        plan tests => 40;
    }
}


{
    package HasOwnImmutable;

    use Moose;

    no Moose;

    ::warning_is( sub { eval q[sub make_immutable { return 'foo' }] },
                  '',
                  'no warning when defining our own make_immutable sub' );
}

{
    is( HasOwnImmutable->make_immutable(), 'foo',
        'HasOwnImmutable->make_immutable does not get overwritten' );
}

{
    package MooseX::Empty;

    use Moose ();
    Moose::Exporter->setup_import_methods( also => 'Moose' );
}

{
    package WantsMoose;

    MooseX::Empty->import();

    sub foo { 1 }

    ::can_ok( 'WantsMoose', 'has' );
    ::can_ok( 'WantsMoose', 'with' );
    ::can_ok( 'WantsMoose', 'foo' );

    MooseX::Empty->unimport();
}

{
    # Note: it's important that these methods be out of scope _now_,
    # after unimport was called. We tried a
    # namespace::clean(0.08)-based solution, but had to abandon it
    # because it cleans the namespace _later_ (when the file scope
    # ends).
    ok( ! WantsMoose->can('has'),  'WantsMoose::has() has been cleaned' );
    ok( ! WantsMoose->can('with'), 'WantsMoose::with() has been cleaned' );
    can_ok( 'WantsMoose', 'foo' );

    # This makes sure that Moose->init_meta() happens properly
    isa_ok( WantsMoose->meta(), 'Moose::Meta::Class' );
    isa_ok( WantsMoose->new(), 'Moose::Object' );

}

{
    package MooseX::Sugar;

    use Moose ();

    sub wrapped1 {
        my $caller = shift;
        return $caller . ' called wrapped1';
    }

    Moose::Exporter->setup_import_methods(
        with_caller => ['wrapped1'],
        also        => 'Moose',
    );
}

{
    package WantsSugar;

    MooseX::Sugar->import();

    sub foo { 1 }

    ::can_ok( 'WantsSugar', 'has' );
    ::can_ok( 'WantsSugar', 'with' );
    ::can_ok( 'WantsSugar', 'wrapped1' );
    ::can_ok( 'WantsSugar', 'foo' );
    ::is( wrapped1(), 'WantsSugar called wrapped1',
          'wrapped1 identifies the caller correctly' );

    MooseX::Sugar->unimport();
}

{
    ok( ! WantsSugar->can('has'),  'WantsSugar::has() has been cleaned' );
    ok( ! WantsSugar->can('with'), 'WantsSugar::with() has been cleaned' );
    ok( ! WantsSugar->can('wrapped1'), 'WantsSugar::wrapped1() has been cleaned' );
    can_ok( 'WantsSugar', 'foo' );
}

{
    package MooseX::MoreSugar;

    use Moose ();

    sub wrapped2 {
        my $caller = shift;
        return $caller . ' called wrapped2';
    }

    sub as_is1 {
        return 'as_is1';
    }

    Moose::Exporter->setup_import_methods(
        with_caller => ['wrapped2'],
        as_is       => ['as_is1'],
        also        => 'MooseX::Sugar',
    );
}

{
    package WantsMoreSugar;

    MooseX::MoreSugar->import();

    sub foo { 1 }

    ::can_ok( 'WantsMoreSugar', 'has' );
    ::can_ok( 'WantsMoreSugar', 'with' );
    ::can_ok( 'WantsMoreSugar', 'wrapped1' );
    ::can_ok( 'WantsMoreSugar', 'wrapped2' );
    ::can_ok( 'WantsMoreSugar', 'as_is1' );
    ::can_ok( 'WantsMoreSugar', 'foo' );
    ::is( wrapped1(), 'WantsMoreSugar called wrapped1',
          'wrapped1 identifies the caller correctly' );
    ::is( wrapped2(), 'WantsMoreSugar called wrapped2',
          'wrapped2 identifies the caller correctly' );
    ::is( as_is1(), 'as_is1',
          'as_is1 works as expected' );

    MooseX::MoreSugar->unimport();
}

{
    ok( ! WantsMoreSugar->can('has'),  'WantsMoreSugar::has() has been cleaned' );
    ok( ! WantsMoreSugar->can('with'), 'WantsMoreSugar::with() has been cleaned' );
    ok( ! WantsMoreSugar->can('wrapped1'), 'WantsMoreSugar::wrapped1() has been cleaned' );
    ok( ! WantsMoreSugar->can('wrapped2'), 'WantsMoreSugar::wrapped2() has been cleaned' );
    ok( ! WantsMoreSugar->can('as_is1'), 'WantsMoreSugar::as_is1() has been cleaned' );
    can_ok( 'WantsMoreSugar', 'foo' );
}

{
    package My::Metaclass;
    use Moose;
    BEGIN { extends 'Moose::Meta::Class' }

    package My::Object;
    use Moose;
    BEGIN { extends 'Moose::Object' }

    package HasInitMeta;

    use Moose ();

    sub init_meta {
        shift;
        return Moose->init_meta( @_,
                                 metaclass  => 'My::Metaclass',
                                 base_class => 'My::Object',
                               );
    }

    Moose::Exporter->setup_import_methods( also => 'Moose' );
}

{
    package NewMeta;

    HasInitMeta->import();
}

{
    isa_ok( NewMeta->meta(), 'My::Metaclass' );
    isa_ok( NewMeta->new(), 'My::Object' );
}

{
    package MooseX::CircularAlso;

    use Moose ();

    ::dies_ok(
        sub {
            Moose::Exporter->setup_import_methods(
                also => [ 'Moose', 'MooseX::CircularAlso' ],
            );
        },
        'a circular reference in also dies with an error'
    );

    ::like(
        $@,
        qr/\QCircular reference in also parameter to Moose::Exporter between MooseX::CircularAlso and MooseX::CircularAlso/,
        'got the expected error from circular reference in also'
    );
}

{
    package MooseX::CircularAlso;

    use Moose ();

    ::dies_ok(
        sub {
            Moose::Exporter->setup_import_methods(
                also => [ 'NoSuchThing' ],
            );
        },
        'a package which does not use Moose::Exporter in also dies with an error'
    );

    ::like(
        $@,
        qr/\QPackage in also (NoSuchThing) does not seem to use Moose::Exporter/,
        'got the expected error from a reference in also to a package which does not use Moose::Exporter'
    );
}
