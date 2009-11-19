
package Moose::Meta::Method::Accessor;

use strict;
use warnings;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Accessor';

sub _error_thrower {
    my $self = shift;
    ( ref $self && $self->associated_attribute ) || $self->SUPER::_error_thrower();
}

sub _eval_code {
    my ( $self, $source ) = @_;

    # NOTE:
    # set up the environment
    my $attr = $self->associated_attribute;
    my $type_constraint_obj = $attr->type_constraint;
    my $environment = {
        '$attr' => \$attr,
        '$attr_name' => \$attr->name,
        '$meta' => \$self,
        '$type_constraint_obj' => \$type_constraint_obj,
        '$type_constraint_name' => \($type_constraint_obj && $type_constraint_obj->name),
        '$type_constraint' => \($type_constraint_obj
                                   ? $type_constraint_obj->_compiled_type_constraint
                                   : undef),
    };

    #warn "code for " . $attr->name . " =>\n" . $source . "\n";
    my ( $code, $e ) = $self->_compile_code( environment => $environment, code => $source );

    $self->throw_error(
        "Could not create writer for '${\$self->associated_attribute->name}' because $e \n code: $source",
        error => $e, data => $source )
        if $e;

    return $code;
}

sub _generate_accessor_method_inline {
    my $self        = $_[0];
    my $attr        = $self->associated_attribute;
    my $attr_name   = $attr->name;
    my $inv         = '$_[0]';
    my $value_name  = $self->_value_needs_copy ? '$val' : '$_[1]';

    $self->_eval_code('sub { ' . "\n"
    . $self->_inline_pre_body(@_) . "\n"
    . 'if (scalar(@_) >= 2) {' . "\n"
        . $self->_inline_copy_value . "\n"
        . $self->_inline_check_required . "\n"
        . $self->_inline_check_coercion($value_name) . "\n"
        . $self->_inline_check_constraint($value_name) . "\n"
        . $self->_inline_get_old_value_for_trigger($inv, $value_name) . "\n"
        . $self->_inline_store($inv, $value_name) . "\n"
        . $self->_inline_trigger($inv, $value_name, '@old') . "\n"
    . ' }' . "\n"
    . $self->_inline_check_lazy($inv) . "\n"
    . $self->_inline_post_body(@_) . "\n"
    . 'return ' . $self->_inline_auto_deref($self->_inline_get($inv)) . "\n"
    . ' }');
}

sub _generate_writer_method_inline {
    my $self        = $_[0];
    my $attr        = $self->associated_attribute;
    my $attr_name   = $attr->name;
    my $inv         = '$_[0]';
    my $slot_access = $self->_inline_get($inv, $attr_name);
    my $value_name  = $self->_value_needs_copy ? '$val' : '$_[1]';

    $self->_eval_code('sub { '
    . $self->_inline_pre_body(@_)
    . $self->_inline_copy_value
    . $self->_inline_check_required
    . $self->_inline_check_coercion($value_name)
    . $self->_inline_check_constraint($value_name)
    . $self->_inline_get_old_value_for_trigger($inv, $value_name) . "\n"
    . $self->_inline_store($inv, $value_name)
    . $self->_inline_post_body(@_)
    . $self->_inline_trigger($inv, $value_name, '@old')
    . ' }');
}

sub _generate_reader_method_inline {
    my $self        = $_[0];
    my $attr        = $self->associated_attribute;
    my $attr_name   = $attr->name;
    my $inv         = '$_[0]';
    my $slot_access = $self->_inline_get($inv, $attr_name);

    $self->_eval_code('sub {'
    . $self->_inline_pre_body(@_)
    . $self->_inline_throw_error('"Cannot assign a value to a read-only accessor"', 'data => \@_') . ' if @_ > 1;'
    . $self->_inline_check_lazy($inv)
    . $self->_inline_post_body(@_)
    . 'return ' . $self->_inline_auto_deref( $slot_access ) . ';'
    . '}');
}

sub _inline_copy_value {
    return '' unless shift->_value_needs_copy;
    return 'my $val = $_[1];'
}

sub _value_needs_copy {
    my $attr = (shift)->associated_attribute;
    return $attr->should_coerce;
}

sub _generate_reader_method { shift->_generate_reader_method_inline(@_) }
sub _generate_writer_method { shift->_generate_writer_method_inline(@_) }
sub _generate_accessor_method { shift->_generate_accessor_method_inline(@_) }
sub _generate_predicate_method { shift->_generate_predicate_method_inline(@_) }
sub _generate_clearer_method { shift->_generate_clearer_method_inline(@_) }

sub _inline_pre_body  { '' }
sub _inline_post_body { '' }

sub _inline_check_constraint {
    my ($self, $value) = @_;

    my $attr = $self->associated_attribute;
    my $attr_name = $attr->name;

    return '' unless $attr->has_type_constraint;

    my $type_constraint_name = $attr->type_constraint->name;

    qq{\$type_constraint->($value) || } . $self->_inline_throw_error(qq{"Attribute ($attr_name) does not pass the type constraint because: " . \$type_constraint_obj->get_message($value)}, "data => $value") . ";";
}

sub _inline_check_coercion {
    my ($self, $value) = @_;

    my $attr = $self->associated_attribute;

    return '' unless $attr->should_coerce;
    return "$value = \$attr->type_constraint->coerce($value);";
}

sub _inline_check_required {
    my $self = shift;
    my $attr = $self->associated_attribute;

    my $attr_name = $attr->name;

    return '' unless $attr->is_required;
    return qq{(\@_ >= 2) || } . $self->_inline_throw_error(qq{"Attribute ($attr_name) is required, so cannot be set to undef"}) . ';' # defined $_[1] is not good enough
}

sub _inline_check_lazy {
    my ($self, $instance) = @_;

    my $attr = $self->associated_attribute;

    return '' unless $attr->is_lazy;

    my $slot_exists = $self->_inline_has($instance, $attr->name);

    my $code = 'unless (' . $slot_exists . ') {' . "\n";
    if ($attr->has_type_constraint) {
        if ($attr->has_default || $attr->has_builder) {
            if ($attr->has_default) {
                $code .= '    my $default = $attr->default(' . $instance . ');'."\n";
            }
            elsif ($attr->has_builder) {
                $code .= '    my $default;'."\n".
                         '    if(my $builder = '.$instance.'->can($attr->builder)){ '."\n".
                         '        $default = '.$instance.'->$builder; '. "\n    } else {\n" .
                         '        ' . $self->_inline_throw_error(q{sprintf "%s does not support builder method '%s' for attribute '%s'", ref(} . $instance . ') || '.$instance.', $attr->builder, $attr->name') .
                         ';'. "\n    }";
            }
            $code .= $self->_inline_check_coercion('$default') . "\n";
            $code .= $self->_inline_check_constraint('$default') . "\n";
            $code .= '    ' . $self->_inline_init_slot($attr, $instance, '$default') . "\n";
        }
        else {
            $code .= '    ' . $self->_inline_init_slot($attr, $instance, 'undef') . "\n";
        }

    } else {
        if ($attr->has_default) {
            $code .= '    ' . $self->_inline_init_slot($attr, $instance, ('$attr->default(' . $instance . ')')) . "\n";
        }
        elsif ($attr->has_builder) {
            $code .= '    if (my $builder = '.$instance.'->can($attr->builder)) { ' . "\n"
                  .  '       ' . $self->_inline_init_slot($attr, $instance, ($instance . '->$builder'))
                  .  "\n    } else {\n"
                  .  '        ' . $self->_inline_throw_error(q{sprintf "%s does not support builder method '%s' for attribute '%s'", ref(} . $instance . ') || '.$instance.', $attr->builder, $attr->name')
                  .  ';'. "\n    }";
        }
        else {
            $code .= '    ' . $self->_inline_init_slot($attr, $instance, 'undef') . "\n";
        }
    }
    $code .= "}\n";
    return $code;
}

sub _inline_init_slot {
    my ($self, $attr, $inv, $value) = @_;
    if ($attr->has_initializer) {
        return ('$attr->set_initial_value(' . $inv . ', ' . $value . ');');
    }
    else {
        return $self->_inline_store($inv, $value);
    }
}

sub _inline_store {
    my ($self, $instance, $value) = @_;
    my $attr = $self->associated_attribute;

    my $mi = $attr->associated_class->get_meta_instance;

    my $code = $mi->inline_set_slot_value($instance, $attr->slots, $value)    . ";";
    $code   .= $mi->inline_weaken_slot_value($instance, $attr->slots, $value) . ";"
        if $attr->is_weak_ref;
    return $code;
}

sub _inline_get_old_value_for_trigger {
    my ( $self, $instance ) = @_;

    my $attr = $self->associated_attribute;
    return '' unless $attr->has_trigger;

    my $mi = $attr->associated_class->get_meta_instance;
    my $pred = $mi->inline_is_slot_initialized($instance, $attr->name);

    return
          'my @old = '
        . $pred . q{ ? }
        . $self->_inline_get($instance) . q{ : ()} . ";\n";
}

sub _inline_trigger {
    my ($self, $instance, $value, $old_value) = @_;
    my $attr = $self->associated_attribute;
    return '' unless $attr->has_trigger;
    return sprintf('$attr->trigger->(%s, %s, %s);', $instance, $value, $old_value);
}

sub _inline_get {
    my ($self, $instance) = @_;
    my $attr = $self->associated_attribute;

    my $mi = $attr->associated_class->get_meta_instance;

    return $mi->inline_get_slot_value($instance, $attr->slots);
}

sub _inline_access {
    my ($self, $instance) = @_;
    my $attr = $self->associated_attribute;

    my $mi = $attr->associated_class->get_meta_instance;

    return $mi->inline_slot_access($instance, $attr->slots);
}

sub _inline_has {
    my ($self, $instance) = @_;
    my $attr = $self->associated_attribute;

    my $mi = $attr->associated_class->get_meta_instance;

    return $mi->inline_is_slot_initialized($instance, $attr->slots);
}

sub _inline_auto_deref {
    my ( $self, $ref_value ) = @_;
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
        $self->throw_error("Can not auto de-reference the type constraint '" . $type_constraint->name . "'", type_constraint => $type_constraint );
    }

    "(wantarray() ? $sigil\{ ( $ref_value ) || return } : ( $ref_value ) )";
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

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
