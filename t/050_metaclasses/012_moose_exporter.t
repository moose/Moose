#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Test::Requires {
    'Test::Output' => '0.01', # skip all if not installed
};

{
    package HasOwnImmutable;

    use Moose;

    no Moose;

    ::stderr_is( sub { eval q[sub make_immutable { return 'foo' }] },
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
        my $meta = shift;
        return $meta->name . ' called wrapped1';
    }

    Moose::Exporter->setup_import_methods(
        with_meta => ['wrapped1'],
        also      => 'Moose',
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
        my $caller = shift->name;
        return $caller . ' called wrapped2';
    }

    sub as_is1 {
        return 'as_is1';
    }

    Moose::Exporter->setup_import_methods(
        with_meta => ['wrapped2'],
        as_is     => ['as_is1'],
        also      => 'MooseX::Sugar',
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

    ::like(
        ::exception{ Moose::Exporter->setup_import_methods(
                also => [ 'Moose', 'MooseX::CircularAlso' ],
            );
            },
        qr/\QCircular reference in 'also' parameter to Moose::Exporter between MooseX::CircularAlso and MooseX::CircularAlso/,
        'a circular reference in also dies with an error'
    );
}

{
    package MooseX::NoAlso;

    use Moose ();

    ::like(
        ::exception{ Moose::Exporter->setup_import_methods(
                also => ['NoSuchThing'],
            );
            },
        qr/\QPackage in also (NoSuchThing) does not seem to use Moose::Exporter (is it loaded?) at /,
        'a package which does not use Moose::Exporter in also dies with an error'
    );
}

{
    package MooseX::NotExporter;

    use Moose ();

    ::like(
        ::exception{ Moose::Exporter->setup_import_methods(
                also => ['Moose::Meta::Method'],
            );
            },
        qr/\QPackage in also (Moose::Meta::Method) does not seem to use Moose::Exporter at /,
        'a package which does not use Moose::Exporter in also dies with an error'
    );
}

{
    package MooseX::OverridingSugar;

    use Moose ();

    sub has {
        my $caller = shift->name;
        return $caller . ' called has';
    }

    Moose::Exporter->setup_import_methods(
        with_meta => ['has'],
        also      => 'Moose',
    );
}

{
    package WantsOverridingSugar;

    MooseX::OverridingSugar->import();

    ::can_ok( 'WantsOverridingSugar', 'has' );
    ::can_ok( 'WantsOverridingSugar', 'with' );
    ::is( has('foo'), 'WantsOverridingSugar called has',
          'has from MooseX::OverridingSugar is called, not has from Moose' );

    MooseX::OverridingSugar->unimport();
}

{
    ok( ! WantsOverridingSugar->can('has'),  'WantsSugar::has() has been cleaned' );
    ok( ! WantsOverridingSugar->can('with'), 'WantsSugar::with() has been cleaned' );
}

{
    package MooseX::OverridingSugar::PassThru;
    
    sub with {
        my $caller = shift->name;
        return $caller . ' called with';
    }
    
    Moose::Exporter->setup_import_methods(
        with_meta => ['with'],
        also      => 'MooseX::OverridingSugar',
    );
    
}

{

    package WantsOverridingSugar::PassThru;

    MooseX::OverridingSugar::PassThru->import();

    ::can_ok( 'WantsOverridingSugar::PassThru', 'has' );
    ::can_ok( 'WantsOverridingSugar::PassThru', 'with' );
    ::is(
        has('foo'),
        'WantsOverridingSugar::PassThru called has',
        'has from MooseX::OverridingSugar is called, not has from Moose'
    );

    ::is(
        with('foo'),
        'WantsOverridingSugar::PassThru called with',
        'with from MooseX::OverridingSugar::PassThru is called, not has from Moose'
    );


    MooseX::OverridingSugar::PassThru->unimport();
}

{
    ok( ! WantsOverridingSugar::PassThru->can('has'),  'WantsOverridingSugar::PassThru::has() has been cleaned' );
    ok( ! WantsOverridingSugar::PassThru->can('with'), 'WantsOverridingSugar::PassThru::with() has been cleaned' );
}

{

    package NonExistentExport;

    use Moose ();

    ::stderr_like {
        Moose::Exporter->setup_import_methods(
            also => ['Moose'],
            with_meta => ['does_not_exist'],
        );
    } qr/^Trying to export undefined sub NonExistentExport::does_not_exist/,
      "warns when a non-existent method is requested to be exported";
}

{
    package WantsNonExistentExport;

    NonExistentExport->import;

    ::ok(!__PACKAGE__->can('does_not_exist'),
         "undefined subs do not get exported");
}

{
    package AllOptions;
    use Moose ();
    use Moose::Deprecated -api_version => '0.88';
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        also        => ['Moose'],
        with_meta   => [ 'with_meta1', 'with_meta2' ],
        with_caller => [ 'with_caller1', 'with_caller2' ],
        as_is       => ['as_is1'],
    );

    sub with_caller1 {
        return @_;
    }

    sub with_caller2 (&) {
        return @_;
    }

    sub as_is1 {2}

    sub with_meta1 {
        return @_;
    }

    sub with_meta2 (&) {
        return @_;
    }
}

{
    package UseAllOptions;

    AllOptions->import();
}

{
    can_ok( 'UseAllOptions', $_ )
        for qw( with_meta1 with_meta2 with_caller1 with_caller2 as_is1 );

    {
        my ( $caller, $arg1 ) = UseAllOptions::with_caller1(42);
        is( $caller, 'UseAllOptions', 'with_caller wrapped sub gets the right caller' );
        is( $arg1, 42, 'with_caller wrapped sub returns argument it was passed' );
    }

    {
        my ( $meta, $arg1 ) = UseAllOptions::with_meta1(42);
        isa_ok( $meta, 'Moose::Meta::Class', 'with_meta first argument' );
        is( $arg1, 42, 'with_meta1 returns argument it was passed' );
    }

    is(
        prototype( UseAllOptions->can('with_caller2') ),
        prototype( AllOptions->can('with_caller2') ),
        'using correct prototype on with_meta function'
    );

    is(
        prototype( UseAllOptions->can('with_meta2') ),
        prototype( AllOptions->can('with_meta2') ),
        'using correct prototype on with_meta function'
    );
}

{
    package UseAllOptions;
    AllOptions->unimport();
}

{
    ok( ! UseAllOptions->can($_), "UseAllOptions::$_ has been unimported" )
        for qw( with_meta1 with_meta2 with_caller1 with_caller2 as_is1 );
}

done_testing;
