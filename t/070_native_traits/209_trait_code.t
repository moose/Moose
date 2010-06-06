use strict;
use warnings;

use Test::Exception;
use Test::More;

{
    package Thingy;
    use Moose;

    has callback => (
        traits   => ['Code'],
        isa      => 'CodeRef',
        required => 1,
        handles  => { 'invoke_callback' => 'execute' },
        clearer  => '_clear_callback',
    );

    has callback_method => (
        traits   => ['Code'],
        isa      => 'CodeRef',
        required => 1,
        handles  => { 'invoke_method_callback' => 'execute_method' },
        clearer  => '_clear_callback_method',
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

$thingy->_clear_callback;
$thingy->_clear_callback_method;

for my $meth (qw( invoke_callback invoke_method_callback )) {
    throws_ok { $thingy->$meth() }
    qr{^The callback(?:_method)?\Q attribute does not contain a subroutine reference at \E.+\Q209_trait_code.t line \E\d+},
        "$meth dies with useful error";
}

done_testing;
