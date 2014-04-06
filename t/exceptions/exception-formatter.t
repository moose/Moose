
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::ExceptionFormatter::NoTrace;
use Moose::Util 'throw_exception';

# checking default 
{
    my $exception = exception {
            package SubClassNoSuperClass;
            use Moose;
            extends;
    };

    like(
        $exception,
        qr/Must derive at least one class/,
        "extends requires at least one argument");

    isa_ok(
        $exception,
        'Moose::Exception::ExtendsMissingArgs',
        "extends requires at least one argument");

    $exception->formatter( Moose::ExceptionFormatter::NoTrace->new() );

    my @tokens = split /\n/, $exception;

    is(
        $#tokens,
        1,
        "Changed formatter to NoTrace, checking length of the tokens");

    like(
        $tokens[ 0 ],
        qr/Must derive at least one class at/,
        "Changed formatter to NoTrace, checking first line");

    like(
        $tokens[ 1 ],
        qr/Moose::Exception::_build_trace\('Moose::Exception::ExtendsMissingArgs=HASH.+ called at reader Moose::Exception::trace \(defined at .+ line \d\) line \d/,
       "Changed formatter to NoTrace, checking second line");
}

done_testing();
