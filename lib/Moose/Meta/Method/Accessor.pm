
package Moose::Meta::Method::Accessor;

use strict;
use warnings;

use Try::Tiny;

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Accessor';

sub _error_thrower {
    my $self = shift;
    return $self->associated_attribute
        if ref($self) && defined($self->associated_attribute);
    return $self->SUPER::_error_thrower;
}

sub _compile_code {
    my $self = shift;
    my @args = @_;
    try {
        $self->SUPER::_compile_code(@args);
    }
    catch {
        $self->throw_error(
            'Could not create writer for '
          . "'" . $self->associated_attribute->name . "' "
          . 'because ' . $_,
            error => $_,
        );
    };
}

sub _eval_environment {
    my $self = shift;

    my $env = { };

    my $attr = $self->associated_attribute;

    $env->{'$trigger'} = \($attr->trigger)
        if $attr->has_trigger;
    $env->{'$default'} = \($attr->default)
        if $attr->has_default;

    if ($attr->has_type_constraint) {
        my $tc_obj = $attr->type_constraint;

        # is this going to be an issue? it's currently only used for the tc
        # message. is there a way to inline that too?
        $env->{'$type_constraint_obj'} = \$tc_obj;

        $env->{'$type_constraint'} = \(
            $tc_obj->_compiled_type_constraint
        ) unless $tc_obj->can_be_inlined;
        $env->{'$type_coercion'} = \(
            $tc_obj->coercion->_compiled_type_coercion
        ) if $tc_obj->has_coercion;

        $env = { %$env, %{ $tc_obj->inline_environment } };
    }

    # XXX ugh, fix these
    $env->{'$attr'} = \$attr
        if $attr->has_initializer;
    $env->{'$meta'} = \$self;

    return $env;
}

sub _instance_is_inlinable {
    my $self = shift;
    return $self->associated_attribute->associated_class->instance_metaclass->is_inlinable;
}

sub _generate_reader_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_reader_method_inline(@_)
                                  : $self->SUPER::_generate_reader_method(@_);
}

sub _generate_writer_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_writer_method_inline(@_)
                                  : $self->SUPER::_generate_writer_method(@_);
}

sub _generate_accessor_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_accessor_method_inline(@_)
                                  : $self->SUPER::_generate_accessor_method(@_);
}

sub _generate_predicate_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_predicate_method_inline(@_)
                                  : $self->SUPER::_generate_predicate_method(@_);
}

sub _generate_clearer_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_clearer_method_inline(@_)
                                  : $self->SUPER::_generate_clearer_method(@_);
}

sub _writer_value_needs_copy {
    shift->associated_attribute->_writer_value_needs_copy(@_);
}

sub _inline_tc_code {
    shift->associated_attribute->_inline_tc_code(@_);
}

sub _inline_check_coercion {
    shift->associated_attribute->_inline_check_coercion(@_);
}

sub _inline_check_constraint {
    shift->associated_attribute->_inline_check_constraint(@_);
}

sub _inline_check_lazy {
    shift->associated_attribute->_inline_check_lazy(@_);
}

sub _inline_store_value {
    shift->associated_attribute->_inline_instance_set(@_) . ';';
}

sub _inline_get_old_value_for_trigger {
    shift->associated_attribute->_inline_get_old_value_for_trigger(@_);
}

sub _inline_trigger {
    shift->associated_attribute->_inline_trigger(@_);
}

sub _get_value {
    shift->associated_attribute->_inline_instance_get(@_);
}

sub _has_value {
    shift->associated_attribute->_inline_instance_has(@_);
}

1;

# ABSTRACT: A Moose Method metaclass for accessors

__END__

=pod

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method::Accessor> that
provides additional Moose-specific functionality, all of which is
private.

To understand this class, you should read the the
L<Class::MOP::Method::Accessor> documentation.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
