use strict;
use warnings;

use lib 't/lib';
use Test::More tests => 1;

my @warnings;
BEGIN {
    $SIG{__WARN__} = sub { push @warnings, @_ };
}

use Demolition::OnceRemoved;

is scalar @warnings, 0, "No warnings"
 or diag explain \@warnings;
