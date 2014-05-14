use strict;
use warnings;

use Test::More;
use Test::Fatal;

# https://rt.cpan.org/Ticket/Display.html?id=92818

{
    package Parent;
    use Moose;
    has x => (
        is => 'rw',
        required => 1,
    );
}

{
    my $e = exception { my $obj = Parent->new };
    ok(
        $e->isa('Moose::Exception::AttributeIsRequired'),
        'got the right exception',
    )
    or note 'got exception ', ref($e), ': ', $e->message;
}

{
    package Child;
    use Moose;
    extends 'Parent';
}

# the exception produced should be AttributeIsRequired, however
# AttributeIsRequired was throwing the exception ClassNamesDoNotMatch.

{
    my $e = exception { my $obj = Child->new };
    ok(
        $e->isa('Moose::Exception::AttributeIsRequired'),
        'got the right exception',
    )
    or note 'got exception ', ref($e), ': ', $e->message;
}

done_testing;
