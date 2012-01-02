#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Scalar::Util qw/weaken/;

{
    package Foo;
    use Moose;
    use Test::More;

    our @NOT_CLEARED;

    has bar => (
        is => 'ro',
        default => sub {[]},
        leak_check => 1,
    );

    has baz => (
        is => 'ro',
        default => sub {[]},
        leak_check => sub {
            my $self = shift;
            my ( $attr_name, $ref ) = @_;
            # Get address of self for compare as self will be destroyed
            push @NOT_CLEARED => [ "$self", $attr_name, $ref ];
        }
    );

    has boo => (
        is => 'ro',
        default => sub {[]},
        leak_check => 0,
    );
}

my $one = Foo->new();
my @hold = ( $one->bar, $one->baz, $one->boo );

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings => @_ };
    my $self_string = "$one";
    $one = undef;

    is( @warnings, 2, "2 warning" );
    like(
        $warnings[@_],
        qr/^External ref to attribute 'bar' detected on instance 'Foo=HASH/,
        "Got warning $_"
    ) for 0 .. 1;

    is_deeply(
        \@Foo::NOT_CLEARED,
        [[ $self_string, 'baz', \$hold[1] ]],
        "Custom handler ran."
    );
}

# Ensure holds is not cleared early
my $x = @hold;

done_testing;
