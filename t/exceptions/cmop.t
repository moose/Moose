use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

{
    my $exception = exception {
        Class::MOP::Mixin->_throw_exception(Legacy => message => 'oh hai');
    };
    ok(
        $exception->isa('Moose::Exception::Legacy'),
        'threw the right type',
    );
    is($exception->message, 'oh hai', 'got the message attribute');
}

done_testing;
