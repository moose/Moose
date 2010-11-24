
package Moose::Meta::Method::Constructor;

use strict;
use warnings;

use Carp ();
use Scalar::Util 'blessed', 'weaken', 'looks_like_number', 'refaddr';

our $VERSION   = '1.21';
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
    # TODO:
    # the %options should also include a both
    # a call 'initializer' and call 'SUPER::'
    # options, which should cover approx 90%
    # of the possible use cases (even if it
    # requires some adaption on the part of
    # the author, after all, nothing is free)
    my $source = 'sub {';
    $source .= "\n" . 'my $_instance = shift;';

    $source .= "\n" . 'my $class = Scalar::Util::blessed($_instance) || $_instance;';

    $source .= "\n" . "if (\$class ne '" . $self->associated_metaclass->name
            .  "') {";
    $source .= "\n    return "
            .  $self->_generate_fallback_constructor('$class') . ";";
    $source .= "\n}\n";

    $source .= $self->_generate_params('$params', '$class');
    $source .= $self->_generate_instance('$instance', '$class');
    $source .= $self->_generate_slot_initializers;

    $source .= $self->_generate_triggers();
    $source .= ";\n" . $self->_generate_BUILDALL();

    $source .= ";\nreturn \$instance";
    $source .= ";\n" . '}';
    warn $source if $self->options->{debug};

    # We need to check if the attribute ->can('type_constraint')
    # since we may be trying to immutabilize a Moose meta class,
    # which in turn has attributes which are Class::MOP::Attribute
    # objects, rather than Moose::Meta::Attribute. And
    # Class::MOP::Attribute attributes have no type constraints.
    # However we need to make sure we leave an undef value there
    # because the inlined code is using the index of the attributes
    # to determine where to find the type constraint

    my $attrs = $self->_attributes;

    my @type_constraints = map {
        $_->can('type_constraint') ? $_->type_constraint : undef
    } @$attrs;

    my @type_constraint_bodies = map {
        defined $_ ? $_->_compiled_type_constraint : undef;
    } @type_constraints;

    my $defaults = [map { $_->default } @$attrs];

    my ( $code, $e ) = $self->_compile_code(
        code => $source,
        environment => {
            '$meta'  => \$self,
            '$attrs' => \$attrs,
            '$defaults' => \$defaults,
            '@type_constraints' => \@type_constraints,
            '@type_constraint_bodies' => \@type_constraint_bodies,
        },
    );

    $self->throw_error(
        "Could not eval the constructor :\n\n$source\n\nbecause :\n\n$e",
        error => $e, data => $source )
        if $e;

    $self->{'body'} = $code;
}

sub _generate_fallback_constructor {
    my ( $self, $class_var ) = @_;
    "${class_var}->Moose::Object::new(\@_)";
}

sub _generate_params {
    my ( $self, $var, $class_var ) = @_;
    "my $var = " . $self->_generate_BUILDARGS( $class_var, '@_' ) . ";\n";
}

sub _generate_instance {
    my ( $self, $var, $class_var ) = @_;
    "my $var = "
        . $self->associated_metaclass->inline_create_instance($class_var) . ";\n";
}

sub _generate_slot_initializers {
    my ($self) = @_;
    return (join ";\n" => map {
        $self->_generate_slot_initializer($_)
    } 0 .. (@{$self->_attributes} - 1)) . ";\n";
}

sub _generate_BUILDARGS {
    my ( $self, $class, $args ) = @_;

    my $buildargs = $self->associated_metaclass->find_method_by_name("BUILDARGS");

    if ( $args eq '@_'
        and ( !$buildargs or $buildargs->body == \&Moose::Object::BUILDARGS )
        ) {

        # This is the same logic as Moose::Object::BUILDARGS
        return sprintf( <<'EOF', $self->_inline_throw_error( q{'Single parameters to new() must be a HASH ref'}, 'data => $_[0]' ) );
do {
    my $params;
    if ( scalar @_ == 1 ) {
        unless ( defined $_[0] && ref $_[0] eq 'HASH' ) {
            %s
        }
        $params = { %%{ $_[0] } };
    }
    elsif ( @_ %% 2 ) {
        Carp::carp(
            "The new() method for $class expects a hash reference or a key/value list."
                . " You passed an odd number of arguments" );
        $params = { @_, undef };
    }
    else {
        $params = {@_};
    }
    $params
};
EOF
            ;
    }
    else {
        return $class . "->BUILDARGS($args)";
    }
}

sub _generate_BUILDALL {
    my $self = shift;
    my @BUILD_calls;
    foreach my $method (reverse $self->associated_metaclass->find_all_methods_by_name('BUILD')) {
        push @BUILD_calls => '$instance->' . $method->{class} . '::BUILD($params)';
    }
    return join ";\n" => @BUILD_calls;
}

sub _generate_triggers {
    my $self = shift;
    my @trigger_calls;
    foreach my $i ( 0 .. $#{ $self->_attributes } ) {
        my $attr = $self->_attributes->[$i];

        next unless $attr->can('has_trigger') && $attr->has_trigger;

        my $init_arg = $attr->init_arg;

        next unless defined $init_arg;

        push @trigger_calls => '(exists $params->{\''
            . $init_arg
            . '\'}) && do {'
            . "\n    "
            . '$attrs->['
            . $i
            . ']->trigger->('
            . '$instance, '
            . $attr->inline_get('$instance')
            . ', '
            . ');' . "\n}";
    }

    return join ";\n" => @trigger_calls;
}

sub _generate_slot_initializer {
    my $self  = shift;
    my $index = shift;

    my $attr = $self->_attributes->[$index];

    my @source = ('## ' . $attr->name);

    my $is_moose = $attr->isa('Moose::Meta::Attribute'); # XXX FIXME

    if ($is_moose && defined($attr->init_arg) && $attr->is_required && !$attr->has_default && !$attr->has_builder) {
        push @source => ('(exists $params->{\'' . $attr->init_arg . '\'}) ' .
                        '|| ' . $self->_inline_throw_error('"Attribute (' . quotemeta($attr->name) . ') is required"') .';');
    }

    if (($attr->has_default || $attr->has_builder) && !($is_moose && $attr->is_lazy)) {

        if ( defined( my $init_arg = $attr->init_arg ) ) {
            push @source => 'if (exists $params->{\'' . $init_arg . '\'}) {';
            push @source => ('my $val = $params->{\'' . $init_arg . '\'};');
            push @source => $self->_generate_type_constraint_and_coercion($attr, $index)
                if $is_moose;
            push @source => $self->_generate_slot_assignment($attr, '$val', $index);
            push @source => "} else {";
        }
            my $default;
            if ( $attr->has_default ) {
                $default = $self->_generate_default_value($attr, $index);
            }
            else {
               my $builder = $attr->builder;
               $default = '$instance->' . $builder;
            }

            push @source => '{'; # wrap this to avoid my $val overwrite warnings
            push @source => ('my $val = ' . $default . ';');
            push @source => $self->_generate_type_constraint_and_coercion($attr, $index)
                if $is_moose;
            push @source => $self->_generate_slot_assignment($attr, '$val', $index);
            push @source => '}'; # close - wrap this to avoid my $val overrite warnings

        push @source => "}" if defined $attr->init_arg;
    }
    elsif ( defined( my $init_arg = $attr->init_arg ) ) {
        push @source => '(exists $params->{\'' . $init_arg . '\'}) && do {';

            push @source => ('my $val = $params->{\'' . $init_arg . '\'};');
            if ($is_moose && $attr->has_type_constraint) {
                if ($attr->should_coerce && $attr->type_constraint->has_coercion) {
                    push @source => $self->_generate_type_coercion(
                        $attr,
                        '$type_constraints[' . $index . ']',
                        '$val',
                        '$val'
                    );
                }
                push @source => $self->_generate_type_constraint_check(
                    $attr,
                    '$type_constraint_bodies[' . $index . ']',
                    '$type_constraints[' . $index . ']',
                    '$val'
                );
            }
            push @source => $self->_generate_slot_assignment($attr, '$val', $index);

        push @source => "}";
    }

    return join "\n" => @source;
}

sub _generate_slot_assignment {
    my ($self, $attr, $value, $index) = @_;

    my $source;

    if ( $attr->has_initializer ) {
        return
              '$attrs->['
            . $index
            . ']->set_initial_value($instance, '
            . $value . ');';
    }
    else {
        return $attr->inline_set(
            '$instance',
            $value
        ) . ';';
    }

    return $source;
}

sub _generate_type_constraint_and_coercion {
    my ($self, $attr, $index) = @_;

    return unless $attr->has_type_constraint;

    my @source;
    if ($attr->should_coerce && $attr->type_constraint->has_coercion) {
        push @source => $self->_generate_type_coercion(
            $attr,
            '$type_constraints[' . $index . ']',
            '$val',
            '$val'
        );
    }
    push @source => $self->_generate_type_constraint_check(
        $attr,
        ('$type_constraint_bodies[' . $index . ']'),
        ('$type_constraints[' . $index . ']'),
        '$val'
    );
    return @source;
}

sub _generate_type_coercion {
    my ($self, $attr, $type_constraint_name, $value_name, $return_value_name) = @_;
    return ($return_value_name . ' = ' . $type_constraint_name .  '->coerce(' . $value_name . ');');
}

sub _generate_type_constraint_check {
    my ($self, $attr, $type_constraint_cv, $type_constraint_obj, $value_name) = @_;
    return (
        $self->_inline_throw_error('"Attribute (' # FIXME add 'dad'
        . quotemeta( $attr->name )
        . ') does not pass the type constraint because: " . '
        . $type_constraint_obj . '->get_message(' . $value_name . ')')
        . "\n\t unless " .  $type_constraint_cv . '->(' . $value_name . ');'
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

