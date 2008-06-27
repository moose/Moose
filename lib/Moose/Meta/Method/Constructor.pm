
package Moose::Meta::Method::Constructor;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed', 'weaken', 'looks_like_number';

our $VERSION   = '0.52';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Generated';

sub new {
    my $class   = shift;
    my %options = @_;

    (exists $options{options} && ref $options{options} eq 'HASH')
        || confess "You must pass a hash of options";

    ($options{package_name} && $options{name})
        || confess "You must supply the package_name and name parameters $Class::MOP::Method::UPGRADE_ERROR_TEXT";

    my $self = bless {
        # from our superclass
        '&!body'          => undef, 
        '$!package_name'  => $options{package_name},
        '$!name'          => $options{name},
        # specific to this subclass
        '%!options'       => $options{options},
        '$!meta_instance' => $options{metaclass}->get_meta_instance,
        '@!attributes'    => [ $options{metaclass}->compute_all_applicable_attributes ],
        # ...
        '$!associated_metaclass' => $options{metaclass},
    } => $class;

    # we don't want this creating
    # a cycle in the code, if not
    # needed
    weaken($self->{'$!associated_metaclass'});

    $self->initialize_body;

    return $self;
}

## accessors

sub options       { (shift)->{'%!options'}       }
sub meta_instance { (shift)->{'$!meta_instance'} }
sub attributes    { (shift)->{'@!attributes'}    }

sub associated_metaclass { (shift)->{'$!associated_metaclass'} }

## method

# this was changed in 0.41, but broke MooseX::Singleton, so try to catch
# any other code using the original broken spelling
sub intialize_body { confess "Please correct the spelling of 'intialize_body' to 'initialize_body'" }

sub initialize_body {
    my $self = shift;
    # TODO:
    # the %options should also include a both
    # a call 'initializer' and call 'SUPER::'
    # options, which should cover approx 90%
    # of the possible use cases (even if it
    # requires some adaption on the part of
    # the author, after all, nothing is free)
    my $source = 'sub {';
    $source .= "\n" . 'my $class = shift;';

    $source .= "\n" . 'return $class->Moose::Object::new(@_)';
    $source .= "\n" . '    if $class ne \'' . $self->associated_metaclass->name . '\';';

    $source .= "\n" . 'my $params = ' . $self->_generate_BUILDARGS('$class', '@_');

    $source .= ";\n" . 'my $instance = ' . $self->meta_instance->inline_create_instance('$class');

    $source .= ";\n" . (join ";\n" => map {
        $self->_generate_slot_initializer($_)
    } 0 .. (@{$self->attributes} - 1));

    $source .= ";\n" . $self->_generate_triggers();    
    $source .= ";\n" . $self->_generate_BUILDALL();

    $source .= ";\n" . 'return $instance';
    $source .= ";\n" . '}';
    warn $source if $self->options->{debug};

    my $code;
    {
        # NOTE:
        # create the nessecary lexicals
        # to be picked up in the eval
        my $attrs = $self->attributes;

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

        $code = eval $source;
        confess "Could not eval the constructor :\n\n$source\n\nbecause :\n\n$@" if $@;
    }
    $self->{'&!body'} = $code;
}

sub _generate_BUILDARGS {
    my ( $self, $class, $args ) = @_;

    my $buildargs = $self->associated_metaclass->find_method_by_name("BUILDARGS");

    if ( $args eq '@_' and ( !$buildargs or $buildargs->body == \&Moose::Object::BUILDARGS ) ) {
        return join("\n",
            'do {',
            'no warnings "uninitialized";',
            'confess "Single parameters to new() must be a HASH ref"',
            '    if scalar @_ == 1 && defined $_[0] && ref($_[0]) ne q{HASH};',
            '(scalar @_ == 1) ? {%{$_[0]}} : {@_};',
            '}',
        );
    } else {
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
    foreach my $i (0 .. $#{ $self->attributes }) {
        my $attr = $self->attributes->[$i];
        if ($attr->can('has_trigger') && $attr->has_trigger) {
            if (defined(my $init_arg = $attr->init_arg)) {
                push @trigger_calls => (
                    '(exists $params->{\'' . $init_arg . '\'}) && do {' . "\n    "
                    .   '$attrs->[' . $i . ']->trigger->('
                    .       '$instance, ' 
                    .        $self->meta_instance->inline_get_slot_value(
                                 '$instance',
                                 ("'" . $attr->name . "'")
                             ) 
                             . ', '
                    .        '$attrs->[' . $i . ']'
                    .   ');'
                    ."\n}"
                );
            } 
        }
    }
    return join ";\n" => @trigger_calls;    
}

sub _generate_slot_initializer {
    my $self  = shift;
    my $index = shift;

    my $attr = $self->attributes->[$index];

    my @source = ('## ' . $attr->name);

    my $is_moose = $attr->isa('Moose::Meta::Attribute'); # XXX FIXME

    if ($is_moose && defined($attr->init_arg) && $attr->is_required && !$attr->has_default && !$attr->has_builder) {
        push @source => ('(exists $params->{\'' . $attr->init_arg . '\'}) ' .
                        '|| confess "Attribute (' . $attr->name . ') is required";');
    }

    if (($attr->has_default || $attr->has_builder) && !($is_moose && $attr->is_lazy)) {

        if ( defined( my $init_arg = $attr->init_arg ) ) {
            push @source => 'if (exists $params->{\'' . $init_arg . '\'}) {';

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
            push @source => $self->_generate_type_constraint_check(
                $attr,
                ('$type_constraint_bodies[' . $index . ']'),
                ('$type_constraints[' . $index . ']'),                
                '$val'
            ) if ($is_moose && $attr->has_type_constraint);
            
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
    
    if ($attr->has_initializer) {
        $source = (
            '$attrs->[' . $index . ']->set_initial_value($instance, ' . $value . ');'
        );        
    }
    else {
        $source = (
            $self->meta_instance->inline_set_slot_value(
                '$instance',
                ("'" . $attr->name . "'"),
                $value
            ) . ';'
        );        
    }
    
    my $is_moose = $attr->isa('Moose::Meta::Attribute'); # XXX FIXME        

    if ($is_moose && $attr->is_weak_ref) {
        $source .= (
            "\n" .
            $self->meta_instance->inline_weaken_slot_value(
                '$instance',
                ("'" . $attr->name . "'")
            ) .
            ' if ref ' . $value . ';'
        );
    }

    return $source;
}

sub _generate_type_coercion {
    my ($self, $attr, $type_constraint_name, $value_name, $return_value_name) = @_;
    return ($return_value_name . ' = ' . $type_constraint_name .  '->coerce(' . $value_name . ');');
}

sub _generate_type_constraint_check {
    my ($self, $attr, $type_constraint_cv, $type_constraint_obj, $value_name) = @_;
    return (
        $type_constraint_cv . '->(' . $value_name . ')'
        . "\n\t" . '|| confess "Attribute (' 
        . $attr->name 
        . ') does not pass the type constraint because: " . ' 
        . $type_constraint_obj . '->get_message(' . $value_name . ');'
    );
}

sub _generate_default_value {
    my ($self, $attr, $index) = @_;
    # NOTE:
    # default values can either be CODE refs
    # in which case we need to call them. Or
    # they can be scalars (strings/numbers)
    # in which case we can just deal with them
    # in the code we eval.
    if ($attr->is_default_a_coderef) {
        return '$attrs->[' . $index . ']->default($instance)';
    }
    else {
        my $default = $attr->default;
        # make sure to quote strings ...
        unless (looks_like_number($default)) {
            $default = "'$default'";
        }

        return $default;
    }
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Method::Constructor - Method Meta Object for constructors

=head1 DESCRIPTION

This is a subclass of L<Class::MOP::Method> which handles
constructing an approprate Constructor methods. This is primarily
used in the making of immutable metaclasses, otherwise it is
not particularly useful.

=head1 METHODS

=over 4

=item B<new>

=item B<attributes>

=item B<meta_instance>

=item B<options>

=item B<initialize_body>

=item B<associated_metaclass>

=back

=head1 AUTHORS

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

