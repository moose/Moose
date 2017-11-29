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

my ($line1, $line2);
sub foo
{
    $line1 = __LINE__; return Moose::Exception->new(
        message => 'something bad happened',
    );
}

with_immutable {
    my $immutable = shift;

    note "testing with immutable = $immutable, \$\^P is $^P";

    like(
        do { $line2 = __LINE__; foo() },
        qr{^something bad happened at .* line $line1\n\tmain::foo at .* line $line2},
        "exception is well-formed (immutable = $immutable)",
    );
}
'Moose::Exception';
