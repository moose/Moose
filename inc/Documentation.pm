use strict;
use warnings;
package inc::Documentation;

# add x_documentation metadata
# see https://github.com/metacpan/metacpan-web/issues/1468#event-283925638

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

sub mvp_multivalue_args { 'module' }

has module => (
    is => 'ro', isa => 'ArrayRef[Str]',
    required => 1,
);

sub metadata
{
    my $self = shift;
    return +{ x_documentation => $self->module };
}

1;
