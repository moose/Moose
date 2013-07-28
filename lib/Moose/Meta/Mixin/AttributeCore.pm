package Moose::Meta::Mixin::AttributeCore;

use strict;
use warnings;

use List::MoreUtils qw(uniq);
use Class::Load qw(is_class_loaded load_class);
use Scalar::Util qw(blessed);

use base 'Class::MOP::Mixin::AttributeCore';

__PACKAGE__->meta->add_attribute(
    'isa' => (
        reader => '_isa_metadata',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'does' => (
        reader => '_does_metadata',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'is' => (
        reader => '_is_metadata',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'required' => (
        reader => 'is_required',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'lazy' => (
        reader => 'is_lazy', Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'lazy_build' => (
        reader => 'is_lazy_build',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'coerce' => (
        reader => 'should_coerce',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'weak_ref' => (
        reader => 'is_weak_ref',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'auto_deref' => (
        reader => 'should_auto_deref',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'type_constraint' => (
        reader    => 'type_constraint',
        predicate => 'has_type_constraint',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'trigger' => (
        reader    => 'trigger',
        predicate => 'has_trigger',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'handles' => (
        reader    => 'handles',
        writer    => '_set_handles',
        predicate => 'has_handles',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'documentation' => (
        reader    => 'documentation',
        predicate => 'has_documentation',
        Class::MOP::_definition_context(),
    )
);

sub _theoretically_associated_method_names {
    my $self = shift;

    # An attribute attached to a class; should have all
    # associated methods recorded in the associated_methods array.
    if ($self->isa('Class::MOP::Attribute')) {
        return map { $_->name } @{ $self->associated_methods };
    }

    # Moose role attribute with no traits; has predictable accessors.
    if (ref($self) eq 'Moose::Meta::Role::Attribute'
    and !@{ $self->original_options->{traits} || [] }) {
        return $self->_default_associated_method_names(@_);
    }

    # Otherwise compose the attribute into an anonymous class and see
    # what happens!
    if ($self->isa('Moose::Meta::Role::Attribute')) {
        my $anon_class = 'Moose::Meta::Class'->create_anon_class;
        my $concrete   = $self->attribute_for_class($anon_class);
        $anon_class->add_attribute($concrete);
        return map { $_->name } @{ $concrete->associated_methods };
    }

    # We should never reach here (I ran through the Moose test suite
    # with a die statement at this point and never hit it), but just
    # in case, fall back to default behaviour.
    return $self->_default_associated_method_names(@_);
}

sub _default_associated_method_names {
    my $self = shift;
    my @methods;

    if ($self->_is_metadata ne 'bare') {
        push @methods, $self->name;
    }

    foreach my $thing (qw/ accessor reader writer predicate clearer /) {
        my $name = $self->${\"has_$thing"} ? $self->$thing : next;
        push @methods, ref $name ? keys(%$name) : $name;
    }

    if ($self->has_handles) {
        my %delegation = $self->_canonicalize_handles;
        push @methods, keys %delegation;
    }

    return uniq(@methods);
}

sub _canonicalize_handles {
    my $self    = shift;
    my $handles = $self->handles;
    if (my $handle_type = ref($handles)) {
        if ($handle_type eq 'HASH') {
            return %{$handles};
        }
        elsif ($handle_type eq 'ARRAY') {
            return map { $_ => $_ } @{$handles};
        }
        elsif ($handle_type eq 'Regexp') {
            ($self->has_type_constraint)
                || $self->throw_error("Cannot delegate methods based on a Regexp without a type constraint (isa)", data => $handles);
            return map  { ($_ => $_) }
                   grep { /$handles/ } $self->_get_delegate_method_list;
        }
        elsif ($handle_type eq 'CODE') {
            return $handles->($self, $self->_find_delegate_metaclass);
        }
        elsif (blessed($handles) && $handles->isa('Moose::Meta::TypeConstraint::DuckType')) {
            return map { $_ => $_ } @{ $handles->methods };
        }
        elsif (blessed($handles) && $handles->isa('Moose::Meta::TypeConstraint::Role')) {
            $handles = $handles->role;
        }
        else {
            $self->throw_error("Unable to canonicalize the 'handles' option with $handles", data => $handles);
        }
    }

    load_class($handles);
    my $role_meta = Class::MOP::class_of($handles);

    (blessed $role_meta && $role_meta->isa('Moose::Meta::Role'))
        || $self->throw_error("Unable to canonicalize the 'handles' option with $handles because its metaclass is not a Moose::Meta::Role", data => $handles);

    return map { $_ => $_ }
        map { $_->name }
        grep { !$_->isa('Class::MOP::Method::Meta') } (
        $role_meta->_get_local_methods,
        $role_meta->get_required_method_list,
        );
}

sub _get_delegate_method_list {
    my $self = shift;
    my $meta = $self->_find_delegate_metaclass;
    if ($meta->isa('Class::MOP::Class')) {
        return map  { $_->name }  # NOTE: !never! delegate &meta
               grep { $_->package_name ne 'Moose::Object' && !$_->isa('Class::MOP::Method::Meta') }
                    $meta->get_all_methods;
    }
    elsif ($meta->isa('Moose::Meta::Role')) {
        return $meta->get_method_list;
    }
    else {
        $self->throw_error("Unable to recognize the delegate metaclass '$meta'", data => $meta);
    }
}

sub _find_delegate_metaclass {
    my $self = shift;
    if (my $class = $self->_isa_metadata) {
        unless ( is_class_loaded($class) ) {
            $self->throw_error(
                sprintf(
                    'The %s attribute is trying to delegate to a class which has not been loaded - %s',
                    $self->name, $class
                )
            );
        }
        # we might be dealing with a non-Moose class,
        # and need to make our own metaclass. if there's
        # already a metaclass, it will be returned
        return Class::MOP::Class->initialize($class);
    }
    elsif (my $role = $self->_does_metadata) {
        unless ( is_class_loaded($class) ) {
            $self->throw_error(
                sprintf(
                    'The %s attribute is trying to delegate to a role which has not been loaded - %s',
                    $self->name, $role
                )
            );
        }

        return Class::MOP::class_of($role);
    }
    else {
        $self->throw_error("Cannot find delegate metaclass for attribute " . $self->name);
    }
}

1;

# ABSTRACT: Core attributes shared by attribute metaclasses

__END__

=pod

=head1 DESCRIPTION

This class implements the core attributes (aka properties) shared by all Moose
attributes. See the L<Moose::Meta::Attribute> documentation for API details.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
