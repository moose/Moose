use strict;
use warnings;

BEGIN {
    # t/exceptions/without-debugging.t and t/exceptions/with-debugging.t are
    # identical except for this one line.
    $^P &= ~0x200;
}

use Test::More tests => 2;
use Test::Moose;
use Moose::Exception;

# with_immutable only toggles on, not off
Moose::Exception->meta->make_mutable;

sub foo
{
    return Moose::Exception->new(
        message => 'something bad happened',
    );
}

my $filename = __FILE__;

with_immutable {
    my $immutable = shift;

    note "testing with immutable = $immutable, \$\^P is $^P";

    like(
        foo(),
        qr{^something bad happened at $filename line \d+\n\tmain::foo at $filename line \d+},
        "exception is well-formed (immutable = $immutable)",
    );
}
'Moose::Exception';
