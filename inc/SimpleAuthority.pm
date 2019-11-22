use strict;
use warnings;
package inc::SimpleAuthority;

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

sub metadata
{
    return +{ x_authority => 'cpan:STEVAN' };
}

1;
