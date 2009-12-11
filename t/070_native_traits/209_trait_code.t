use strict;
use warnings;

use Test::More tests => 3;

{
    package Thingy;
    use Moose;

    has callback => (
        traits => ['Code'],
        is     => 'ro',
        isa    => 'CodeRef',
        required => 1,
        handles => { 'invoke_callback' => 'execute' },
    );

    has multiplier => (
        traits   => ['Code'],
        is       => 'ro',
        isa      => 'CodeRef',
        required => 1,
        handles  => { 'multiply' => 'execute' },
    );
}

my $i = 0;
my $thingy = Thingy->new(
    callback => sub { ++$i },
    multiplier => sub { $_[0] * 2 }
);

is($i, 0);
$thingy->invoke_callback;
is($i, 1);
is($thingy->multiply(3), 6);
