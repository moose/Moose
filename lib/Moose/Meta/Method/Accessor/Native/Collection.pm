package Moose::Meta::Method::Accessor::Native::Collection;

use strict;
use warnings;

our $VERSION = '1.19';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

requires qw( _adds_members );

sub _inline_coerce_new_values {
    my $self = shift;

    return unless $self->associated_attribute->should_coerce;

    return unless $self->_tc_member_type_can_coerce;

    return (
        '(' . $self->_new_members . ') = map { $member_tc_obj->coerce($_) }',
                                             $self->_new_members . ';',
    );
}

sub _tc_member_type_can_coerce {
    my $self = shift;

    my $member_tc = $self->_tc_member_type;

    return $member_tc && $member_tc->has_coercion;
}

sub _tc_member_type {
    my $self = shift;

    my $tc = $self->associated_attribute->type_constraint;
    while ($tc) {
        return $tc->type_parameter
            if $tc->can('type_parameter');
        $tc = $tc->parent;
    }

    return;
}

sub _value_needs_copy {
    my $self = shift;

    return $self->_constraint_must_be_checked
        && !$self->_check_new_members_only;
}

sub _inline_tc_code {
    my $self = shift;
    my ($potential_value) = @_;

    return unless $self->_constraint_must_be_checked;

    if ($self->_check_new_members_only) {
        return unless $self->_adds_members;

        return $self->_inline_check_member_constraint($self->_new_members);
    }
    else {
        return (
            $self->_inline_check_coercion($potential_value),
            $self->_inline_check_constraint($potential_value),
        );
    }
}

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
    my $self = shift;
    my ($new_value) = @_;

    my $attr_name = $self->associated_attribute->name;

    return (
        'for (' . $new_value . ') {',
            'if (!$member_tc->($_)) {',
                $self->_inline_throw_error(
                    '"A new member value for ' . $attr_name
                  . ' does not pass its type constraint because: "'
                  . ' . $member_tc->get_message($_)',
                    'data => $_',
                ) . ';',
            '}',
        '}',
    );
}

sub _inline_get_old_value_for_trigger {
    my $self = shift;
    my ($instance, $old) = @_;

    my $attr = $self->associated_attribute;
    return unless $attr->has_trigger;

    return (
        'my ' . $old . ' = ' . $self->_has_value($instance),
            '? ' . $self->_copy_old_value($self->_get_value($instance)),
            ': ();',
    );
}

around _eval_environment => sub {
    my $orig = shift;
    my $self = shift;

    my $env = $self->$orig(@_);

    my $member_tc = $self->_tc_member_type;

    return $env unless $member_tc;

    $env->{'$member_tc_obj'} = \($member_tc);

    $env->{'$member_tc'} = \( $member_tc->_compiled_type_constraint );

    return $env;
};

no Moose::Role;

1;
