#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;


{
    package AClass;

    use Moose;

    has 'foo' => (is => 'rw', isa => 'Maybe[Str]', trigger => sub {
        die "Pulling the Foo trigger\n"
    });

    has 'bar' => (is => 'rw', isa => 'Maybe[Str]');

    has 'baz' => (is => 'rw', isa => 'Maybe[Str]', trigger => sub {
        die "Pulling the Baz trigger\n"
    });

    __PACKAGE__->meta->make_immutable; #(debug => 1);

    no Moose;
}

eval { AClass->new(foo => 'bar') };
like ($@, qr/^Pulling the Foo trigger/, "trigger from immutable constructor");

eval { AClass->new(baz => 'bar') };
like ($@, qr/^Pulling the Baz trigger/, "trigger from immutable constructor");

lives_ok { AClass->new(bar => 'bar') } '... no triggers called';

done_testing;
