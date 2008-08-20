
package Moose::Meta::Method::Accessor;

use strict;
use warnings;

use Carp 'confess';

our $VERSION   = '0.55_01';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Accessor';

## Inline method generators

sub _eval_code {
    my ( $self, $code ) = @_;

    # NOTE:
    # set up the environment
    my $attr        = $self->associated_attribute;
    my $attr_name   = $attr->name;

    my $type_constraint_obj  = $attr->type_constraint;
    my $type_constraint_name = $type_constraint_obj && $type_constraint_obj->name;
    my $type_constraint      = $type_constraint_obj
                                   ? $type_constraint_obj->_compiled_type_constraint
                                   : undef;

    #warn "code for $attr_name =>\n" . $code . "\n";
    my $sub = eval $code;
    confess "Could not create writer for '$attr_name' because $@ \n code: $code" if $@;
    return $sub;

}

sub generate_accessor_method_inline {
    my $self        = $_[0];
    my $attr        = $self->associated_attribute;
    my $attr_name   = $attr->name;
    my $inv         = '$_[0]';
    my $slot_access = $self->_inline_access($inv, $attr_name);
    my $value_name  = $self->_value_needs_copy ? '$val' : '$_[1]';

    $self->_eval_code('sub { ' . "\n"
    . $self->_inline_pre_body(@_) . "\n"
    . 'if (scalar(@_) >= 2) {' . "\n"
        . $self->_inline_copy_value . "\n"
        . $self->_inline_check_required . "\n"
        . $self->_inline_check_coercion . "\n"
        . $self->_inline_check_constraint($value_name) . "\n"
        . $self->_inline_store($inv, $value_name) . "\n"
        . $self->_inline_trigger($inv, $value_name) . "\n"
    . ' }' . "\n"
    . $self->_inline_check_lazy . "\n"
    . $self->_inline_post_body(@_) . "\n"
    . 'return ' . $self->_inline_auto_deref($self->_inline_get($inv)) . "\n"
    . ' }');
}

sub generate_writer_method_inline {
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
    . $self->_inline_check_coercion
    . $self->_inline_check_constraint($value_name)
    . $self->_inline_store($inv, $value_name)
    . $self->_inline_post_body(@_)
    . $self->_inline_trigger($inv, $value_name)
    . ' }');
}

sub generate_reader_method_inline {
    my $self        = $_[0];
    my $attr        = $self->associated_attribute;
    my $attr_name   = $attr->name;
    my $inv         = '$_[0]';
    my $slot_access = $self->_inline_get($inv, $attr_name);

    $self->_eval_code('sub {'
    . $self->_inline_pre_body(@_)
    . 'confess "Cannot assign a value to a read-only accessor" if @_ > 1;'
    . $self->_inline_check_lazy
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

sub generate_reader_method { shift->generate_reader_method_inline(@_) }
sub generate_writer_method { shift->generate_writer_method_inline(@_) }
sub generate_accessor_method { shift->generate_accessor_method_inline(@_) }

sub _inline_pre_body  { '' }
sub _inline_post_body { '' }

sub _inline_check_constraint {
    my ($self, $value) = @_;
    
    my $attr = $self->associated_attribute;
    my $attr_name = $attr->name;
    
    return '' unless $attr->has_type_constraint;
    
    my $type_constraint_name = $attr->type_constraint->name;

    # FIXME
    # This sprintf is insanely annoying, we should
    # fix it someday - SL
    return sprintf <<'EOF', $value, $attr_name, $value, $value,
$type_constraint->(%s)
        || confess "Attribute (%s) does not pass the type constraint because: "
       . $type_constraint_obj->get_message(%s);
EOF
}

sub _inline_check_coercion {
    my $attr = (shift)->associated_attribute;
    
    return '' unless $attr->should_coerce;
    return '$val = $attr->type_constraint->coerce($_[1]);'
}

sub _inline_check_required {
    my $attr = (shift)->associated_attribute;

    my $attr_name = $attr->name;
    
    return '' unless $attr->is_required;
    return qq{(\@_ >= 2) || confess "Attribute ($attr_name) is required, so cannot be set to undef";} # defined $_[1] is not good enough
}

sub _inline_check_lazy {
    my $self = $_[0];
    my $attr = $self->associated_attribute;

    return '' unless $attr->is_lazy;

    my $inv         = '$_[0]';
    my $slot_access = $self->_inline_access($inv, $attr->name);

    my $slot_exists = $self->_inline_has($inv, $attr->name);

    my $code = 'unless (' . $slot_exists . ') {' . "\n";
    if ($attr->has_type_constraint) {
        if ($attr->has_default || $attr->has_builder) {
            if ($attr->has_default) {
                $code .= '    my $default = $attr->default(' . $inv . ');'."\n";
            } 
            elsif ($attr->has_builder) {
                $code .= '    my $default;'."\n".
                         '    if(my $builder = '.$inv.'->can($attr->builder)){ '."\n".
                         '        $default = '.$inv.'->$builder; '. "\n    } else {\n" .
                         '        confess(Scalar::Util::blessed('.$inv.')." does not support builder method '.
                         '\'".$attr->builder."\' for attribute \'" . $attr->name . "\'");'. "\n    }";
            }
            $code .= '    $default = $type_constraint_obj->coerce($default);'."\n"  if $attr->should_coerce;
            $code .= '    ($type_constraint->($default))' .
                     '            || confess "Attribute (" . $attr_name . ") does not pass the type constraint ("' .
                     '           . $type_constraint_name . ") with " . (defined($default) ? overload::StrVal($default) : "undef");' 
                     . "\n";
            $code .= '    ' . $self->_inline_init_slot($attr, $inv, $slot_access, '$default') . "\n";
        } 
        else {
            $code .= '    ' . $self->_inline_init_slot($attr, $inv, $slot_access, 'undef') . "\n";
        }

    } else {
        if ($attr->has_default) {
            $code .= '    ' . $self->_inline_init_slot($attr, $inv, $slot_access, ('$attr->default(' . $inv . ')')) . "\n";            
        } 
        elsif ($attr->has_builder) {
            $code .= '    if (my $builder = '.$inv.'->can($attr->builder)) { ' . "\n" 
                  .  '       ' . $self->_inline_init_slot($attr, $inv, $slot_access, ($inv . '->$builder'))           
                     . "\n    } else {\n" .
                     '        confess(Scalar::Util::blessed('.$inv.')." does not support builder method '.
                     '\'".$attr->builder."\' for attribute \'" . $attr->name . "\'");'. "\n    }";
        } 
        else {
            $code .= '    ' . $self->_inline_init_slot($attr, $inv, $slot_access, 'undef') . "\n";
        }
    }
    $code .= "}\n";
    return $code;
}

sub _inline_init_slot {
    my ($self, $attr, $inv, $slot_access, $value) = @_;
    if ($attr->has_initializer) {
        return ('$attr->set_initial_value(' . $inv . ', ' . $value . ');');
    }
    else {
        return ($slot_access . ' = ' . $value . ';');
    }    
}

sub _inline_store {
    my ($self, $instance, $value) = @_;
    my $attr = $self->associated_attribute;
    
    my $mi = $attr->associated_class->get_meta_instance;
    my $slot_name = sprintf "'%s'", $attr->slots;
    
    my $code = $mi->inline_set_slot_value($instance, $slot_name, $value)    . ";";
    $code   .= $mi->inline_weaken_slot_value($instance, $slot_name, $value) . ";"
        if $attr->is_weak_ref;
    return $code;
}

sub _inline_trigger {
    my ($self, $instance, $value) = @_;
    my $attr = $self->associated_attribute;
    return '' unless $attr->has_trigger;
    return sprintf('$attr->trigger->(%s, %s, $attr);', $instance, $value);
}

sub _inline_get {
    my ($self, $instance) = @_;
    my $attr = $self->associated_attribute;
    
    my $mi = $attr->associated_class->get_meta_instance;
    my $slot_name = sprintf "'%s'", $attr->slots;

    return $mi->inline_get_slot_value($instance, $slot_name);
}

sub _inline_access {
    my ($self, $instance) = @_;
    my $attr = $self->associated_attribute;
    
    my $mi = $attr->associated_class->get_meta_instance;
    my $slot_name = sprintf "'%s'", $attr->slots;

    return $mi->inline_slot_access($instance, $slot_name);
}

sub _inline_has {
    my ($self, $instance) = @_;
    my $attr = $self->associated_attribute;
    
    my $mi = $attr->associated_class->get_meta_instance;
    my $slot_name = sprintf "'%s'", $attr->slots;

    return $mi->inline_is_slot_initialized($instance, $slot_name);
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
        confess "Can not auto de-reference the type constraint '" . $type_constraint->name . "'";
    }

    "(wantarray() ? $sigil\{ ( $ref_value ) || return } : ( $ref_value ) )";
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Method::Accessor - A Moose Method metaclass for accessors

=head1 DESCRIPTION

This is a subclass of L<Class::MOP::Method::Accessor> and it's primary
responsibility is to generate the accessor methods for attributes. It
can handle both closure based accessors, as well as inlined source based
accessors.

This is a fairly new addition to the MOP, but this will play an important
role in the optimization strategy we are currently following.

=head1 METHODS

=over 4

=item B<generate_accessor_method>

=item B<generate_reader_method>

=item B<generate_writer_method>

=item B<generate_accessor_method_inline>

=item B<generate_reader_method_inline>

=item B<generate_writer_method_inline>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
