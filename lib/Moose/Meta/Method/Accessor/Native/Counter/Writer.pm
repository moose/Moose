package Moose::Meta::Method::Accessor::Native::Counter::Writer;

use strict;
use warnings;

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer';

sub _constraint_must_be_checked {
    my $self = shift;

    my $attr = $self->associated_attribute;

    return $attr->has_type_constraint
        && ( $attr->type_constraint->name =~ /^(?:Num|Int)$/
        || ( $attr->should_coerce && $attr->type_constraint->has_coercion ) );
}

no Moose::Role;

1;
