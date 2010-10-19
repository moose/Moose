package Moose::Meta::Method::Accessor::Native::Collection;

use strict;
use warnings;

our $VERSION = '1.17';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

requires qw( _adds_members );

around _value_needs_copy => sub {
    shift;
    my $self = shift;

    return $self->_constraint_must_be_checked
        && !$self->_check_new_members_only;
};

around _inline_tc_code => sub {
    shift;
    my ( $self, $potential_value ) = @_;

    return q{} unless $self->_constraint_must_be_checked;

    if ( $self->_check_new_members_only ) {
        return q{} unless $self->_adds_members;

        return $self->_inline_check_member_constraint( $self->_new_members );
    }
    else {
        return $self->_inline_check_coercion($potential_value) . "\n"
            . $self->_inline_check_constraint($potential_value);
    }
};

sub _check_new_members_only {
    my $self = shift;

    my $attr = $self->associated_attribute;

    my $tc = $attr->type_constraint;

    # If we have a coercion, we could come up with an entirely new value after
    # coercing, so we need to check everything,
    return 0 if $attr->should_coerce && $tc->has_coercion;

    # If the parent is our root type (ArrayRef, HashRef, etc), that means we
    # can just check the new members of the collection, because we know that
    # we will always be generating an appropriate collection type.
    #
    # However, if this type has its own constraint (it's Parameteriz_able_,
    # not Paramet_erized_), we don't know what is being checked by the
    # constraint, so we need to check the whole value, not just the members.
    return 1
        if $self->_is_root_type( $tc->parent )
            && $tc->isa('Moose::Meta::TypeConstraint::Parameterized');

    return 0;
}

sub _inline_check_member_constraint {
    my ( $self, $new_value ) = @_;

    my $attr_name = $self->associated_attribute->name;

    return '$member_tc->($_) || '
        . $self->_inline_throw_error(
        qq{"A new member value for '$attr_name' does not pass its type constraint because: "}
            . ' . $member_tc->get_message($_)',
        "data => \$_"
        ) . " for $new_value;";
}

around _inline_check_constraint => sub {
    my $orig = shift;
    my $self = shift;

    return q{} unless $self->_constraint_must_be_checked;

    return $self->$orig( $_[0] );
};

around _inline_get_old_value_for_trigger => sub {
    shift;
    my ( $self, $instance ) = @_;

    my $attr = $self->associated_attribute;
    return '' unless $attr->has_trigger;

    return
          'my @old = '
        . $self->_inline_has($instance) . q{ ? }
        . $self->_inline_copy_old_value( $self->_inline_get($instance) )
        . ": ();\n";
};

around _eval_environment => sub {
    my $orig = shift;
    my $self = shift;

    my $env = $self->$orig(@_);

    return $env
        unless $self->_constraint_must_be_checked
            && $self->_check_new_members_only;

    $env->{'$member_tc'}
        = \( $self->associated_attribute->type_constraint->type_parameter
            ->_compiled_type_constraint );

    return $env;
};

no Moose::Role;

1;
