use strict;
use warnings;

use Test::More;
use Test::Exception;
BEGIN {
    eval "use Test::Output;";
    plan skip_all => "Test::Output is required for this test" if $@;
    plan tests => 2;
}

{
    package Foo;
    use Moose;
}

{
    my $foo = Foo->new();
    stderr_like { $foo->new() }
    qr/\QCalling new() on an instance is deprecated/,
        '$object->new() is deprecated';

    Foo->meta->make_immutable, redo
        if Foo->meta->is_mutable;
}
