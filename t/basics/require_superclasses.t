use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;


{

    package Bar;
    use Moose;

    ::is( ::exception { extends 'Foo' }, undef, 'loaded Foo superclass correctly' );
}

{

    package Baz;
    use Moose;

    ::is( ::exception { extends 'Bar' }, undef, 'loaded (inline) Bar superclass correctly' );
}

{

    package Foo::Bar;
    use Moose;

    ::is( ::exception { extends 'Foo', 'Bar' }, undef, 'loaded Foo and (inline) Bar superclass correctly' );
}

{

    package Bling;
    use Moose;

    my $warnings = '';
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    ::is( ::exception { extends 'No::Class' }, undef, "extending an empty package is a valid thing to do" );
    ::like( $warnings, qr/^Can't locate package No::Class for \@Bling::ISA/, "but it does give a warning" );
}

{
    package Affe;
    our $VERSION = 23;
}

{
    package Tiger;
    use Moose;

    ::is( ::exception { extends 'Foo', Affe => { -version => 13 } }, undef, 'extends with version requirement' );
}

{
    package Birne;
    use Moose;

    ::like( ::exception { extends 'Foo', Affe => { -version => 42 } }, qr/Affe version 42 required--this is only version 23/, 'extends with unsatisfied version requirement' );
}

done_testing;
