
use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    my $exception = exception {
        use Moose;
        Moose->throw_error("Hello, I am an exception object");
    };

    like(
        $exception,
        qr/Hello, I am an exception object/,
        "throw_error stringifies to the message");

    isa_ok(
        $exception,
        'Moose::Exception::Legacy',
        "throw_error stringifies to the message");
}

done_testing();
