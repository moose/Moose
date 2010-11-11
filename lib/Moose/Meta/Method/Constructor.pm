
package Moose::Meta::Method::Constructor;

use strict;
use warnings;

use Carp ();
use Scalar::Util 'blessed', 'weaken', 'looks_like_number', 'refaddr';
use Try::Tiny;

our $VERSION   = '1.19';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Constructor';

sub new {
    my $class   = shift;
    my %options = @_;

    my $meta = $options{metaclass};

    (ref $options{options} eq 'HASH')
        || $class->throw_error("You must pass a hash of options", data => $options{options});

    ($options{package_name} && $options{name})
        || $class->throw_error("You must supply the package_name and name parameters $Class::MOP::Method::UPGRADE_ERROR_TEXT");

    my $self = bless {
        'body'          => undef,
        'package_name'  => $options{package_name},
        'name'          => $options{name},
        'options'       => $options{options},
        'associated_metaclass' => $meta,
        '_expected_method_class' => $options{_expected_method_class} || 'Moose::Object',
    } => $class;

    # we don't want this creating
    # a cycle in the code, if not
    # needed
    weaken($self->{'associated_metaclass'});

    $self->_initialize_body;

    return $self;
}

## method

sub _initialize_body {
    my $self = shift;
    $self->{'body'} = $self->_generate_constructor_method_inline;
}

sub _eval_environment {
    my $self = shift;

    my $attrs = $self->_attributes;

    my $defaults = [map { $_->default } @$attrs];

    # We need to check if the attribute ->can('type_constraint')
    # since we may be trying to immutabilize a Moose meta class,
    # which in turn has attributes which are Class::MOP::Attribute
    # objects, rather than Moose::Meta::Attribute. And
    # Class::MOP::Attribute attributes have no type constraints.
    # However we need to make sure we leave an undef value there
    # because the inlined code is using the index of the attributes
    # to determine where to find the type constraint

    my @type_constraints = map {
        $_->can('type_constraint') ? $_->type_constraint : undef
    } @$attrs;

    my @type_constraint_bodies = map {
        defined $_ ? $_->_compiled_type_constraint : undef;
    } @type_constraints;

    return {
        '$meta'  => \$self,
        '$attrs' => \$attrs,
        '$defaults' => \$defaults,
        '@type_constraints' => \@type_constraints,
        '@type_constraint_bodies' => \@type_constraint_bodies,
    };
}

sub _generate_constructor_method_inline {
    my $self = shift;
    # TODO:
    # the %options should also include a both
    # a call 'initializer' and call 'SUPER::'
    # options, which should cover approx 90%
    # of the possible use cases (even if it
    # requires some adaption on the part of
    # the author, after all, nothing is free)

    my @source = (
        'sub {',
            'my $_instance = shift;',
            'my $class = Scalar::Util::blessed($_instance) || $_instance;',
            'if ($class ne \'' . $self->associated_metaclass->name . '\') {',
                'return ' . $self->_generate_fallback_constructor('$class') . ';',
            '}',
            $self->_generate_params('$params', '$class'),
            $self->_generate_instance('$instance', '$class'),
            $self->_generate_slot_initializers,
            $self->_generate_triggers,
            $self->_generate_BUILDALL,
            'return $instance;',
        '}'
    );
    warn join("\n", @source) if $self->options->{debug};

    return try {
        $self->_compile_code(\@source);
    }
    catch {
        my $source = join("\n", @source);
        $self->throw_error(
            "Could not eval the constructor :\n\n$source\n\nbecause :\n\n$_",
            error => $_,
            data  => $source,
        );
    };
}

sub _generate_fallback_constructor {
    my $self = shift;
    my ($class_var) = @_;
    return $class_var . '->Moose::Object::new(@_)'
}

sub _generate_params {
    my $self = shift;
    my ($var, $class_var) = @_;
    return (
        'my ' . $var . ' = ',
        $self->_generate_BUILDARGS($class_var, '@_'),
        ';',
    );
}

sub _generate_instance {
    my $self = shift;
    my ($var, $class_var) = @_;
    my $meta = $self->associated_metaclass;

    return (
        'my ' . $var . ' = ',
        $meta->inline_create_instance($class_var) . ';',
    );
}

sub _generate_slot_initializers {
    my $self = shift;
    return map { $self->_generate_slot_initializer($_) }
               0 .. (@{$self->_attributes} - 1);
}

sub _generate_BUILDARGS {
    my $self = shift;
    my ($class, $args) = @_;

    my $buildargs = $self->associated_metaclass->find_method_by_name("BUILDARGS");

    if ($args eq '@_'
     && (!$buildargs or $buildargs->body == \&Moose::Object::BUILDARGS)) {

        return (
            'do {',
                'my $params;',
                'if (scalar @_ == 1) {',
                    'if (!defined($_[0]) || ref($_[0]) ne \'HASH\') {',
                        $self->_inline_throw_error(
                            '"Single parameters to new() must be a HASH ref"',
                            'data => $_[0]',
                        ) . ';',
                    '}',
                    '$params = { %{ $_[0] } };',
                '}',
                'elsif (@_ % 2) {',
                    'Carp::carp(',
                        '"The new() method for ' . $class . ' expects a '
                      . 'hash reference or a key/value list. You passed an '
                      . 'odd number of arguments"',
                    ');',
                    '$params = {@_, undef};',
                '}',
                'else {',
                    '$params = {@_};',
                '}',
                '$params;',
            '}',
        );
    }
    else {
        return $class . '->BUILDARGS(' . $args . ')';
    }
}

sub _generate_BUILDALL {
    my $self = shift;

    my @methods = reverse $self->associated_metaclass->find_all_methods_by_name('BUILD');
    my @BUILD_calls;

    foreach my $method (@methods) {
        push @BUILD_calls,
            '$instance->' . $method->{class} . '::BUILD($params);';
    }

    return @BUILD_calls;
}

sub _generate_triggers {
    my $self = shift;
    my @trigger_calls;

    for my $i (0 .. $#{ $self->_attributes }) {
        my $attr = $self->_attributes->[$i];

        next unless $attr->can('has_trigger') && $attr->has_trigger;

        my $init_arg = $attr->init_arg;
        next unless defined $init_arg;

        push @trigger_calls,
            'if (exists $params->{\'' . $init_arg . '\'}) {',
                '$attrs->[' . $i . ']->trigger->(',
                    '$instance,',
                    $attr->_inline_instance_get('$instance') . ',',
                ');',
            '}';
    }

    return @trigger_calls;
}

sub _generate_slot_initializer {
    my $self  = shift;
    my ($index) = @_;

    my $attr = $self->_attributes->[$index];

    my @source = ('## ' . $attr->name);

    push @source, $self->_check_required_attr($attr);

    if (defined $attr->init_arg) {
        push @source,
            'if (exists $params->{\'' . $attr->init_arg . '\'}) {',
                $self->_init_attr_from_constructor($attr, $index),
            '}';
        if (my @default = $self->_init_attr_from_default($attr, $index)) {
            push @source,
                'else {',
                    @default,
                '}';
        }
    }
    else {
        if (my @default = $self->_init_attr_from_default($attr, $index)) {
            push @source,
                '{', # _init_attr_from_default creates variables
                    @default,
                '}';
        }
    }

    return @source;
}

sub _check_required_attr {
    my $self = shift;
    my ($attr) = @_;

    return unless defined $attr->init_arg;
    return unless $attr->can('is_required') && $attr->is_required;
    return if $attr->has_default || $attr->has_builder;

    return (
        'if (!exists $params->{\'' . $attr->init_arg . '\'}) {',
            $self->_inline_throw_error(
                '"Attribute (' . quotemeta($attr->name) . ') is required"'
            ) . ';',
        '}',
    );
}

sub _init_attr_from_constructor {
    my $self = shift;
    my ($attr, $index) = @_;

    return (
        'my $val = $params->{\'' . $attr->init_arg . '\'};',
        $self->_generate_slot_assignment($attr, $index, '$val'),
    );
}

sub _init_attr_from_default {
    my $self = shift;
    my ($attr, $index) = @_;

    my $default = $self->_generate_default_value($attr, $index);
    return unless $default;

    return (
        'my $val = ' . $default . ';',
        $self->_generate_slot_assignment($attr, $index, '$val'),
    );
}

sub _generate_slot_assignment {
    my $self = shift;
    my ($attr, $index, $value) = @_;

    my @source;

    if ($self->can('_generate_type_constraint_and_coercion')) {
        push @source, $self->_generate_type_constraint_and_coercion(
            $attr, $index, $value,
        );
    }

    if ($attr->has_initializer) {
        push @source, (
            '$attrs->[' . $index . ']->set_initial_value(',
                '$instance' . ',',
                $value . ',',
            ');'
        );
    }
    else {
        push @source, (
            $attr->_inline_instance_set('$instance', $value) . ';',
        );
    }

    return @source;
}

sub _generate_type_constraint_and_coercion {
    my $self = shift;
    my ($attr, $index, $value) = @_;

    return unless $attr->can('has_type_constraint')
               && $attr->has_type_constraint;

    my @source;

    if ($attr->should_coerce && $attr->type_constraint->has_coercion) {
        push @source => $self->_generate_type_coercion(
            '$type_constraints[' . $index . ']',
            $value,
            $value,
        );
    }

    push @source => $self->_generate_type_constraint_check(
        $attr,
        '$type_constraint_bodies[' . $index . ']',
        '$type_constraints[' . $index . ']',
        $value,
    );

    return @source;
}

sub _generate_type_coercion {
    my $self = shift;
    my ($tc_obj, $value, $return_value) = @_;
    return $return_value . ' = ' . $tc_obj . '->coerce(' . $value . ');';
}

sub _generate_type_constraint_check {
    my $self = shift;
    my ($attr, $tc_body, $tc_obj, $value) = @_;
    return (
        $self->_inline_throw_error(
            '"Attribute (' . quotemeta($attr->name) . ') '
          . 'does not pass the type constraint because: " . '
          . $tc_obj . '->get_message(' . $value . ')'
        ),
        'unless ' .  $tc_body . '->(' . $value . ');'
    );
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Method::Constructor - Method Meta Object for constructors

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method::Constructor> that
provides additional Moose-specific functionality

To understand this class, you should read the the
L<Class::MOP::Method::Constructor> documentation as well.

=head1 INHERITANCE

C<Moose::Meta::Method::Constructor> is a subclass of
L<Moose::Meta::Method> I<and> L<Class::MOP::Method::Constructor>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHORS

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

