#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';;

{

    package Foo;
    use Moose;

    has foo => ( is => "ro" );

    package Bar;
    use metaclass (
        metaclass   => "Moose::Meta::Class",
        error_class => "Moose::Error::Croak",
    );
    use Moose;

    has foo => ( is => "ro" );

    package Baz::Error;
    use Moose;

    has message    => ( isa => "Str",                    is => "ro" );
    has attr       => ( isa => "Moose::Meta::Attribute", is => "ro" );
    has method     => ( isa => "Moose::Meta::Method",    is => "ro" );
    has metaclass  => ( isa => "Moose::Meta::Class",     is => "ro" );
    has data       => ( is  => "ro" );
    has line       => ( isa => "Int",                    is => "ro" );
    has file       => ( isa => "Str",                    is => "ro" );
    has last_error => ( isa => "Any",                    is => "ro" );

    package Baz;
    use metaclass (
        metaclass   => "Moose::Meta::Class",
        error_class => "Baz::Error",
    );
    use Moose;

    has foo => ( is => "ro" );
}

my $line;
sub blah { $line = __LINE__; shift->foo(4) }

sub create_error {
    eval {
        eval { die "Blah" };
        blah(shift);
    };
    ok( my $e = $@, "got some error" );
    return {
        file  => __FILE__,
        line  => $line,
        error => $e,
    };
}

{
    my $e = create_error( Foo->new );
    ok( !ref( $e->{error} ), "error is a string" );
    like( $e->{error}, qr/line $e->{line}\n.*\n/s, "confess" );
}

{
    my $e = create_error( Bar->new );
    ok( !ref( $e->{error} ), "error is a string" );
    like( $e->{error}, qr/line $e->{line}$/s, "croak" );
}

{
    my $e = create_error( my $baz = Baz->new );
    isa_ok( $e->{error}, "Baz::Error" );
    unlike( $e->{error}->message, qr/line $e->{line}/s,
        "no line info, just a message" );
    isa_ok( $e->{error}->metaclass, "Moose::Meta::Class", "metaclass" );
    is( $e->{error}->metaclass, Baz->meta, "metaclass value" );
    isa_ok( $e->{error}->attr, "Moose::Meta::Attribute", "attr" );
    is( $e->{error}->attr, Baz->meta->get_attribute("foo"), "attr value" );
    isa_ok( $e->{error}->method, "Moose::Meta::Method", "method" );
    is( $e->{error}->method, Baz->meta->get_method("foo"), "method value" );
    is( $e->{error}->line,   $e->{line},                   "line attr" );
    is( $e->{error}->file,   $e->{file},                   "file attr" );
    is_deeply( $e->{error}->data, [ $baz, 4 ], "captured args" );
    like( $e->{error}->last_error, qr/Blah/, "last error preserved" );
}
