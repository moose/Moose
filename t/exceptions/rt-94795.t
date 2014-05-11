use strict;
use warnings;

use Test::More;
use Test::Fatal;

# https://rt.cpan.org/Ticket/Display.html?id=94795

# the exception produced should be AttributeIsRequired, however
# AttributeIsRequired is throwing the exception ClassNamesDoNotMatch.

{
    package AAA;
    use Moose;
    has my_attr => (
        is => 'ro',
        required => 1,
    );
}

{
    package BBB;
    use Moose;
    extends qw/AAA/;
}

local $TODO = 'Moose::Exceptions needs refactoring';

my $e = exception { BBB->new };
ok(
    $e->isa('AttributeIsRequired'),
    'got the right exception',
)
or note 'got exception ', ref($e), ': ', $e->message;

done_testing;
