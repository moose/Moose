use strict;
use warnings;

use Test::More tests => 2;

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
}

my $i = 0;
my $thingy = Thingy->new(callback => sub { ++$i });

is($i, 0);
$thingy->invoke_callback;
is($i, 1);
