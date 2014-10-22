use strict;
use warnings;

use Test::More;
use Try::Tiny;

{
    my $e;
    {
        package Foo;
        use Moose;
        use Try::Tiny;

        try {
            has '+foo' => ( is => 'ro' );
        }
        catch {
            $e = $_;
        };
    }

    ok( $e, q{got an exception from a bad has '+foo' declaration} );
    like(
        $e->as_string,
        qr/\QCould not find an attribute by the name of 'foo' to inherit from in Foo/,
        'stringification includes the error message'
    );
    like(
        $e->as_string,
        qr/\s+Moose::has/,
        'stringification includes the call to Moose::has'
    );
    unlike(
        $e->as_string,
        qr/Moose::Meta/,
        'stringification does not include internal calls to Moose meta classes'
    );

    try {
        Foo->meta->clone_object( [] );
    }
    catch {
        $e = $_;
    };

    like(
        $e->as_string,
        qr/Class::MOP::Class::clone_object/,
        'exception include first Class::MOP::Class frame'
    );
    unlike(
        $e->as_string,
        qr/Class::MOP::Mixin::_throw_exception/,
        'exception does not include internal calls toClass::MOP::Class meta classes'
    );
}

local $ENV{MOOSE_FULL_EXCEPTION} = 1;
{
    my $e;
    {
        package Bar;
        use Moose;
        use Try::Tiny;

        try {
            has '+foo' => ( is => 'ro' );
        }
        catch {
            $e = $_;
        };
    }

    ok( $e, q{got an exception from a bad has '+foo' declaration} );
    like(
        $e->as_string,
        qr/\QCould not find an attribute by the name of 'foo' to inherit from in Bar/,
        'stringification includes the error message'
    );
    like(
        $e->as_string,
        qr/\s+Moose::has/,
        'stringification includes the call to Moose::has'
    );
    like(
        $e->as_string,
        qr/Moose::Meta/,
        'stringification includes internal calls to Moose meta classes when MOOSE_FULL_EXCEPTION env var is true'
    );


    try {
        Foo->meta->clone_object( [] );
    }
    catch {
        $e = $_;
    };

    like(
        $e->as_string,
        qr/Class::MOP::Class::clone_object/,
        'exception include first Class::MOP::Class frame'
    );
    like(
        $e->as_string,
        qr/Class::MOP::Mixin::_throw_exception/,
        'exception includes internal calls toClass::MOP::Class meta classes when MOOSE_FULL_EXCEPTION env var is true'
    );
}

done_testing;
