use strict;
use warnings;

use Test::More;

use Moose ();
use Moose::Util::TypeConstraints;

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    enum Foo => qw(Bar Baz Quux);
    like($warnings, qr/Passing a list of values to enum is deprecated\. Enum values should be wrapped in an arrayref\./);
}

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    duck_type Bar => qw(baz quux);
    like($warnings, qr/Passing a list of values to duck_type is deprecated\. The method names should be wrapped in an arrayref\./);
}

done_testing;

