use strict;
use warnings;
package SimpleAuthority;

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

sub metadata
{
    return +{ x_authority => 'cpan:STEVAN' };
}

1;
