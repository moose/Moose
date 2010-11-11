
package Moose::Meta::Method::Accessor;

use strict;
use warnings;

use Try::Tiny;

our $VERSION   = '1.19';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

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

    my $attr                = $self->associated_attribute;
    my $type_constraint_obj = $attr->type_constraint;

    return {
        '$attr'                => \$attr,
        '$meta'                => \$self,
        '$type_constraint_obj' => \$type_constraint_obj,
        '$type_constraint'     => \(
              $type_constraint_obj
                  ? $type_constraint_obj->_compiled_type_constraint
                  : undef
        ),
    };
}

sub _generate_accessor_method_inline {
    my $self        = shift;

    my $inv         = '$_[0]';
    my $slot_access = $self->_get_value($inv);
    my $value       = $self->_value_needs_copy ? '$val' : '$_[1]';
    my $old         = '@old';

    $self->_compile_code([
        'sub {',
            $self->_inline_pre_body(@_),
            'if (scalar(@_) >= 2) {',
                $self->_inline_copy_value($value),
                $self->_inline_check_required,
                $self->_inline_tc_code($value),
                $self->_inline_get_old_value_for_trigger($inv, $old),
                $self->_inline_store_value($inv, $value),
                $self->_inline_trigger($inv, $value, $old),
            '}',
            $self->_inline_check_lazy($inv),
            $self->_inline_post_body(@_),
            $self->_inline_return_auto_deref($slot_access),
        '}',
    ]);
}

sub _generate_writer_method_inline {
    my $self        = shift;

    my $inv   = '$_[0]';
    my $value = $self->_value_needs_copy ? '$val' : '$_[1]';
    my $old   = '@old';

    $self->_compile_code([
        'sub {',
            $self->_inline_pre_body(@_),
            $self->_inline_copy_value($value),
            $self->_inline_check_required,
            $self->_inline_tc_code($value),
            $self->_inline_get_old_value_for_trigger($inv, $old),
            $self->_inline_store_value($inv, $value),
            $self->_inline_post_body(@_),
            $self->_inline_trigger($inv, $value, $old),
        '}',
    ]);
}

sub _generate_reader_method_inline {
    my $self        = shift;

    my $inv         = '$_[0]';
    my $slot_access = $self->_get_value($inv);

    $self->_compile_code([
        'sub {',
            $self->_inline_pre_body(@_),
            'if (@_ > 1) {',
                $self->_inline_throw_error(
                    '"Cannot assign a value to a read-only accessor"',
                    'data => \@_'
                ) . ';',
            '}',
            $self->_inline_check_lazy($inv),
            $self->_inline_post_body(@_),
            $self->_inline_return_auto_deref($slot_access),
        '}',
    ]);
}

sub _inline_copy_value {
    my $self = shift;
    my ($value) = @_;

    return unless $self->_value_needs_copy;
    return 'my ' . $value . ' = $_[1];'
}

sub _value_needs_copy {
    my $self = shift;
    return $self->associated_attribute->should_coerce;
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

sub _inline_pre_body  { return }
sub _inline_post_body { return }

sub _inline_tc_code {
    my $self = shift;
    return (
        $self->_inline_check_coercion(@_),
        $self->_inline_check_constraint(@_),
    );
}

sub _inline_check_constraint {
    my $self = shift;
    my ($value) = @_;

    my $attr = $self->associated_attribute;
    return unless $attr->has_type_constraint;

    my $attr_name = quotemeta($attr->name);

    return (
        'if (!$type_constraint->(' . $value . ')) {',
            $self->_inline_throw_error(
                '"Attribute (' . $attr_name . ') does not pass the type '
              . 'constraint because: " . '
              . '$type_constraint_obj->get_message(' . $value . ')',
                'data => ' . $value
            ) . ';',
        '}',
    );
}

sub _inline_check_coercion {
    my $self = shift;
    my ($value) = @_;

    my $attr = $self->associated_attribute;
    return unless $attr->should_coerce && $attr->type_constraint->has_coercion;

    return $value . ' = $type_constraint_obj->coerce(' . $value . ');';
}

sub _inline_check_required {
    my $self = shift;

    my $attr = $self->associated_attribute;
    return unless $attr->is_required;

    my $attr_name = quotemeta($attr->name);

    return (
        'if (@_ < 2) {',
            $self->_inline_throw_error(
                '"Attribute (' . $attr_name . ') is required, so cannot '
              . 'be set to undef"' # defined $_[1] is not good enough
            ) . ';',
        '}',
    );
}

sub _inline_check_lazy {
    my $self = shift;
    my ($instance, $default) = @_;

    my $attr = $self->associated_attribute;
    return unless $attr->is_lazy;

    my $slot_exists = $self->_has_value($instance);

    return (
        'if (!' . $slot_exists . ') {',
            $self->_inline_init_from_default($instance, '$default', 'lazy'),
        '}',
    );
}

sub _inline_init_from_default {
    my $self = shift;
    my ($instance, $default, $for_lazy) = @_;

    my $attr = $self->associated_attribute;

    if (!($attr->has_default || $attr->has_builder)) {
        $self->throw_error(
            'You cannot have a lazy attribute '
          . '(' . $attr->name . ') '
          . 'without specifying a default value for it',
            attr => $attr,
        );
    }

    return (
        $self->_inline_generate_default($instance, $default),
        # intentionally not using _inline_tc_code, since that can be overridden
        # to do things like possibly only do member tc checks, which isn't
        # appropriate for checking the result of a default
        $attr->has_type_constraint
            ? ($self->_inline_check_coercion($default, $for_lazy),
               $self->_inline_check_constraint($default, $for_lazy))
            : (),
        $self->_inline_init_slot($attr, $instance, $default),
    );
}

sub _inline_generate_default {
    my $self = shift;
    my ($instance, $default) = @_;

    my $attr = $self->associated_attribute;

    if ($attr->has_default) {
        return 'my ' . $default . ' = $attr->default(' . $instance . ');';
    }
    elsif ($attr->has_builder) {
        return (
            'my ' . $default . ';',
            'if (my $builder = ' . $instance . '->can($attr->builder)) {',
                $default . ' = ' . $instance . '->$builder;',
            '}',
            'else {',
                'my $class = ref(' . $instance . ') || ' . $instance . ';',
                'my $builder_name = $attr->builder;',
                'my $attr_name = $attr->name;',
                $self->_inline_throw_error(
                    '"$class does not support builder method '
                  . '\'$builder_name\' for attribute \'$attr_name\'"'
                ) . ';',
            '}',
        );
    }
    else {
        $self->throw_error(
            "Can't generate a default for " . $attr->name
          . " since no default or builder was specified"
        );
    }
}

sub _inline_init_slot {
    my $self = shift;
    my ($attr, $inv, $value) = @_;

    if ($attr->has_initializer) {
        return '$attr->set_initial_value(' . $inv . ', ' . $value . ');';
    }
    else {
        return $self->_inline_store_value($inv, $value);
    }
}

sub _inline_store_value {
    my $self = shift;
    my ($inv, $value) = @_;

    return $self->associated_attribute->_inline_set_value($inv, $value);
}

sub _inline_get_old_value_for_trigger {
    my $self = shift;
    my ($instance, $old) = @_;

    my $attr = $self->associated_attribute;
    return unless $attr->has_trigger;

    return (
        'my ' . $old . ' = ' . $self->_has_value($instance),
            '? ' . $self->_get_value($instance),
            ': ();',
    );
}

sub _inline_trigger {
    my $self = shift;
    my ($instance, $value, $old) = @_;

    my $attr = $self->associated_attribute;
    return unless $attr->has_trigger;

    return '$attr->trigger->(' . $instance . ', ' . $value . ', ' . $old . ');';
}

sub _inline_return_auto_deref {
    my $self = shift;

    return 'return ' . $self->_auto_deref(@_) . ';';
}

# expressions

sub _get_value {
    my ($self, $instance) = @_;

    return $self->associated_attribute->_inline_instance_get($instance);
}

sub _has_value {
    my ($self, $instance) = @_;

    return $self->associated_attribute->_inline_instance_has($instance);
}

sub _auto_deref {
    my $self = shift;
    my ($ref_value) = @_;

    my $attr = $self->associated_attribute;
    return $ref_value unless $attr->should_auto_deref;

    my $type_constraint = $attr->type_constraint;

    my $sigil;
    if ($type_constraint->is_a_type_of('ArrayRef')) {
        $sigil = '@';
    }
    elsif ($type_constraint->is_a_type_of('HashRef')) {
        $sigil = '%';
    }
    else {
        $self->throw_error(
            'Can not auto de-reference the type constraint \''
          . $type_constraint->name
          . '\'',
            type_constraint => $type_constraint,
        );
    }

    return 'wantarray '
             . '? ' . $sigil . '{ (' . $ref_value . ') || return } '
             . ': (' . $ref_value . ')';
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Method::Accessor - A Moose Method metaclass for accessors

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method::Accessor> that
provides additional Moose-specific functionality, all of which is
private.

To understand this class, you should read the the
L<Class::MOP::Method::Accessor> documentation.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
