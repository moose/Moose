use strict;
use warnings;

use Test::More;

{
    package Thingy;
    use Moose;

    has callback => (
        traits   => ['Code'],
        isa      => 'CodeRef',
        required => 1,
        handles  => { 'invoke_callback' => 'execute' },
    );

    has callback_method => (
        traits   => ['Code'],
        isa      => 'CodeRef',
        required => 1,
        handles  => { 'invoke_method_callback' => 'execute_method' },
    );

    has multiplier => (
        traits   => ['Code'],
        isa      => 'CodeRef',
        required => 1,
        handles  => { 'multiply' => 'execute' },
    );
}

my $i = 0;
my $thingy = Thingy->new(
    callback        => sub { ++$i },
    multiplier      => sub { $_[0] * 2 },
    callback_method => sub { shift->multiply(@_) },
);

is($i, 0);
$thingy->invoke_callback;
is($i, 1);
is($thingy->multiply(3), 6);
is($thingy->invoke_method_callback(3), 6);

ok(!$thingy->can($_), "Code trait didn't create reader method for $_")
    for qw(callback callback_method multiplier);

done_testing;
