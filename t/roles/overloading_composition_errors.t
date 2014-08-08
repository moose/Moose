use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use Test::Warnings;

use lib 't/lib';

{
    package Role::HasFallback;
    use Moose::Role;

    use overload
        q{""}    => '_stringify',
        fallback => 1;

    sub _stringify { __PACKAGE__ }
}

{
    package Role::NoFallback;
    use Moose::Role;

    use overload
        '0+'    => '_numify',
        fallback => 0;

    sub _numify { 42 }
}

{
    package Class1;
    use Moose;
    ::like(
        ::exception { with qw( Role::HasFallback Role::NoFallback ) },
        qr/\QWe have encountered an overloading conflict for the fallback during composition. This is fatal error./,
        'exception from fallback conflict during role summation'
    );
}

{
    package Role::NoOverloading;
    use Moose::Role;

    sub foo { 42 }
}

{
    package Class2;
    use Moose;
    ::like(
        ::exception { with qw( Role::HasFallback Role::NoFallback Role::NoOverloading ) },
        qr/\QWe have encountered an overloading conflict for the fallback during composition. This is fatal error./,
        'exception from fallback conflict during role summation including role without overloading'
    );
}

{
    package Role::StringifiesViaSubref1;
    use Moose::Role;

    use overload q{""} => sub { 'foo' };
}

{
    package Role::StringifiesViaSubref2;
    use Moose::Role;

    use overload q{""} => sub { 'bar' };
}

{
    package Class3;
    use Moose;
    ::like(
        ::exception { with qw( Role::StringifiesViaSubref1 Role::StringifiesViaSubref2 ) },
        qr/\QThe two roles both overload the '""' operator. This is a fatal error./,
        'exception when two roles with different subref overloading conflict during role summation'
    );
}

{
    package Class4;
    use Moose;
    ::like(
        ::exception { with qw( Role::StringifiesViaSubref1 Role::StringifiesViaSubref2 Role::NoOverloading ) },
        qr/\QThe two roles both overload the '""' operator. This is a fatal error./,
        'exception when two roles with different subref overloading conflict during role summation including role without overloading'
    );
}

{
    package Role::StringifiesViaMethod1;
    use Moose::Role;

    use overload q{""} => '_stringify1';
    sub _stringify1 { 'foo' }
}

{
    package Role::StringifiesViaMethod2;
    use Moose::Role;

    use overload q{""} => '_stringify2';
    sub _stringify2 { 'foo' }
}

{
    package Class5;
    use Moose;
    ::like(
        ::exception { with qw( Role::StringifiesViaMethod1 Role::StringifiesViaMethod2 ) },
        qr/\QThe two roles both overload the '""' operator. This is a fatal error./,
        'exception when two roles with different method overloading conflict during role summation'
    );
}

{
    package Class6;
    use Moose;
    ::like(
        ::exception { with qw( Role::StringifiesViaMethod1 Role::StringifiesViaMethod2 Role::NoOverloading ) },
        qr/\QThe two roles both overload the '""' operator. This is a fatal error./,
        'exception when two roles with different method overloading conflict during role summation including role without overloading'
    );
}

{
    package Role::Consumer1;
    use Moose::Role;

    use overload
        '0+' => sub {42},
        fallback => 0;

    ::like(
        ::exception { with 'Role::HasFallback' },
        qr/\QWe have encountered an overloading conflict for the fallback setting when applying Role::HasFallback to Role::Consumer1. This is fatal error./,
        'exception when a role with overloading consumes a role with a conflicting fallback setting'
    );
}

{
    package Role::Consumer2;
    use Moose::Role;

    use overload
        q{""} => sub {'foo'},
        fallback => 1;

    ::like(
        ::exception { with 'Role::HasFallback' },
        qr/\QWe have encountered an overloading conflict between overloading methods when applying Role::HasFallback to Role::Consumer2. The two roles both overload the '""' operator. This is a fatal error./,
        'exception when a role with overloading consumes a role with conflicting overloading methods'
    );
}

done_testing();
