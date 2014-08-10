package Class::MOP::Attribute;
our $VERSION = '2.2006';

use strict;
use warnings;

use Class::MOP::Method::Accessor;

use Carp         'confess';
use Scalar::Util 'blessed', 'weaken';
use Try::Tiny;

use parent 'Class::MOP::Object', 'Class::MOP::Mixin::AttributeCore';

# NOTE: (meta-circularity)
# This method will be replaced in the
# boostrap section of Class::MOP, by
# a new version which uses the
# &Class::MOP::Class::construct_instance
# method to build an attribute meta-object
# which itself is described with attribute
# meta-objects.
#     - Ain't meta-circularity grand? :)
sub new {
    my ( $class, @args ) = @_;

    unshift @args, "name" if @args % 2 == 1;
    my %options = @args;

    my $name = $options{name};

    (defined $name)
        || $class->_throw_exception( MOPAttributeNewNeedsAttributeName => class  => $class,
                                                                 params => \%options
                          );

    $options{init_arg} = $name
        if not exists $options{init_arg};
    if(exists $options{builder}){
        $class->_throw_exception( BuilderMustBeAMethodName => class  => $class,
                                                     params => \%options
                       )
            if ref $options{builder} || !(defined $options{builder});
        $class->_throw_exception( BothBuilderAndDefaultAreNotAllowed => class  => $class,
                                                               params => \%options
                       )
            if exists $options{default};
    } else {
        ($class->is_default_a_coderef(\%options))
            || $class->_throw_exception( ReferencesAreNotAllowedAsDefault => class          => $class,
                                                                    params         => \%options,
                                                                    attribute_name => $options{name}
                              )
                if exists $options{default} && ref $options{default};
    }

    if( $options{required} and not( defined($options{builder}) || defined($options{init_arg}) || exists $options{default} ) ) {
        $class->_throw_exception( RequiredAttributeLacksInitialization => class  => $class,
                                                                 params => \%options
                       );
    }

    $class->_new(\%options);
}

sub _new {
    my $class = shift;

    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $options = @_ == 1 ? $_[0] : {@_};

    bless {
        'name'               => $options->{name},
        'accessor'           => $options->{accessor},
        'reader'             => $options->{reader},
        'writer'             => $options->{writer},
        'predicate'          => $options->{predicate},
        'clearer'            => $options->{clearer},
        'builder'            => $options->{builder},
        'init_arg'           => $options->{init_arg},
        exists $options->{default}
            ? ('default'     => $options->{default})
            : (),
        'initializer'        => $options->{initializer},
        'definition_context' => $options->{definition_context},
        # keep a weakened link to the
        # class we are associated with
        'associated_class' => undef,
        # and a list of the methods
        # associated with this attr
        'associated_methods' => [],
        # this let's us keep track of
        # our order inside the associated
        # class
        'insertion_order'    => undef,
    }, $class;
}

# NOTE:
# this is a primitive (and kludgy) clone operation
# for now, it will be replaced in the Class::MOP
# bootstrap with a proper one, however we know
# that this one will work fine for now.
sub clone {
    my $self    = shift;
    my %options = @_;
    (blessed($self))
        || confess "Can only clone an instance";
    # this implementation is overwritten by the bootstrap process,
    # so this exception will never trigger. If it ever does occur,
    # it indicates a gigantic problem with the most internal parts
    # of Moose, so we wouldn't want a Moose-based exception object anyway

    return bless { %{$self}, %options } => ref($self);
}

sub initialize_instance_slot {
    my ($self, $meta_instance, $instance, $params) = @_;
    my $init_arg = $self->{'init_arg'};

    # try to fetch the init arg from the %params ...

    # if nothing was in the %params, we can use the
    # attribute's default value (if it has one)
    if(defined $init_arg and exists $params->{$init_arg}){
        $self->_set_initial_slot_value(
            $meta_instance,
            $instance,
            $params->{$init_arg},
        );
    }
    elsif (exists $self->{'default'}) {
        $self->_set_initial_slot_value(
            $meta_instance,
            $instance,
            $self->default($instance),
        );
    }
    elsif (defined( my $builder = $self->{'builder'})) {
        if ($builder = $instance->can($builder)) {
            $self->_set_initial_slot_value(
                $meta_instance,
                $instance,
                $instance->$builder,
            );
        }
        else {
            $self->_throw_exception( BuilderMethodNotSupportedForAttribute => attribute => $self,
                                                                      instance  => $instance
                           );
        }
    }
}

sub _set_initial_slot_value {
    my ($self, $meta_instance, $instance, $value) = @_;

    my $slot_name = $self->name;

    return $meta_instance->set_slot_value($instance, $slot_name, $value)
        unless $self->has_initializer;

    my $callback = $self->_make_initializer_writer_callback(
        $meta_instance, $instance, $slot_name
    );

    my $initializer = $self->initializer;

    # most things will just want to set a value, so make it first arg
    $instance->$initializer($value, $callback, $self);
}

sub _make_initializer_writer_callback {
    my $self = shift;
    my ($meta_instance, $instance, $slot_name) = @_;

    return sub {
        $meta_instance->set_slot_value($instance, $slot_name, $_[0]);
    };
}

sub get_read_method  {
    my $self   = shift;
    my $reader = $self->reader || $self->accessor;
    # normal case ...
    return $reader unless ref $reader;
    # the HASH ref case
    my ($name) = %$reader;
    return $name;
}

sub get_write_method {
    my $self   = shift;
    my $writer = $self->writer || $self->accessor;
    # normal case ...
    return $writer unless ref $writer;
    # the HASH ref case
    my ($name) = %$writer;
    return $name;
}

sub get_read_method_ref {
    my $self = shift;
    if ((my $reader = $self->get_read_method) && $self->associated_class) {
        return $self->associated_class->get_method($reader);
    }
    else {
        my $code = sub { $self->get_value(@_) };
        if (my $class = $self->associated_class) {
            return $class->method_metaclass->wrap(
                $code,
                package_name => $class->name,
                name         => '__ANON__'
            );
        }
        else {
            return $code;
        }
    }
}

sub get_write_method_ref {
    my $self = shift;
    if ((my $writer = $self->get_write_method) && $self->associated_class) {
        return $self->associated_class->get_method($writer);
    }
    else {
        my $code = sub { $self->set_value(@_) };
        if (my $class = $self->associated_class) {
            return $class->method_metaclass->wrap(
                $code,
                package_name => $class->name,
                name         => '__ANON__'
            );
        }
        else {
            return $code;
        }
    }
}

# slots

sub slots { (shift)->name }

# class association

sub attach_to_class {
    my ($self, $class) = @_;
    (blessed($class) && $class->isa('Class::MOP::Class'))
        || $self->_throw_exception( AttachToClassNeedsAClassMOPClassInstanceOrASubclass => attribute => $self,
                                                                                   class     => $class
                          );
    weaken($self->{'associated_class'} = $class);
}

sub detach_from_class {
    my $self = shift;
    $self->{'associated_class'} = undef;
}

# method association

sub associate_method {
    my ($self, $method) = @_;
    push @{$self->{'associated_methods'}} => $method;
}

## Slot management

sub set_initial_value {
    my ($self, $instance, $value) = @_;
    $self->_set_initial_slot_value(
        Class::MOP::Class->initialize(ref($instance))->get_meta_instance,
        $instance,
        $value
    );
}

sub set_value { shift->set_raw_value(@_) }

sub set_raw_value {
    my $self = shift;
    my ($instance, $value) = @_;

    my $mi = Class::MOP::Class->initialize(ref($instance))->get_meta_instance;
    return $mi->set_slot_value($instance, $self->name, $value);
}

sub _inline_set_value {
    my $self = shift;
    return $self->_inline_instance_set(@_) . ';';
}

sub _inline_instance_set {
    my $self = shift;
    my ($instance, $value) = @_;

    my $mi = $self->associated_class->get_meta_instance;
    return $mi->inline_set_slot_value($instance, $self->name, $value);
}

sub get_value { shift->get_raw_value(@_) }

sub get_raw_value {
    my $self = shift;
    my ($instance) = @_;

    my $mi = Class::MOP::Class->initialize(ref($instance))->get_meta_instance;
    return $mi->get_slot_value($instance, $self->name);
}

sub _inline_get_value {
    my $self = shift;
    return $self->_inline_instance_get(@_) . ';';
}

sub _inline_instance_get {
    my $self = shift;
    my ($instance) = @_;

    my $mi = $self->associated_class->get_meta_instance;
    return $mi->inline_get_slot_value($instance, $self->name);
}

sub has_value {
    my $self = shift;
    my ($instance) = @_;

    my $mi = Class::MOP::Class->initialize(ref($instance))->get_meta_instance;
    return $mi->is_slot_initialized($instance, $self->name);
}

sub _inline_has_value {
    my $self = shift;
    return $self->_inline_instance_has(@_) . ';';
}

sub _inline_instance_has {
    my $self = shift;
    my ($instance) = @_;

    my $mi = $self->associated_class->get_meta_instance;
    return $mi->inline_is_slot_initialized($instance, $self->name);
}

sub clear_value {
    my $self = shift;
    my ($instance) = @_;

    my $mi = Class::MOP::Class->initialize(ref($instance))->get_meta_instance;
    return $mi->deinitialize_slot($instance, $self->name);
}

sub _inline_clear_value {
    my $self = shift;
    return $self->_inline_instance_clear(@_) . ';';
}

sub _inline_instance_clear {
    my $self = shift;
    my ($instance) = @_;

    my $mi = $self->associated_class->get_meta_instance;
    return $mi->inline_deinitialize_slot($instance, $self->name);
}

## load em up ...

sub accessor_metaclass { 'Class::MOP::Method::Accessor' }

sub _process_accessors {
    my ($self, $type, $accessor, $generate_as_inline_methods) = @_;

    my $method_ctx = { %{ $self->definition_context || {} } };

    if (ref($accessor)) {
        (ref($accessor) eq 'HASH')
            || $self->_throw_exception( BadOptionFormat => attribute    => $self,
                                                   option_value => $accessor,
                                                   option_name  => $type
                              );

        my ($name, $method) = %{$accessor};

        $method_ctx->{description} = $self->_accessor_description($name, $type);

        $method = $self->accessor_metaclass->wrap(
            $method,
            attribute    => $self,
            package_name => $self->associated_class->name,
            name         => $name,
            associated_metaclass => $self->associated_class,
            definition_context => $method_ctx,
        );
        $self->associate_method($method);
        return ($name, $method);
    }
    else {
        my $inline_me = ($generate_as_inline_methods && $self->associated_class->instance_metaclass->is_inlinable);
        my $method;
        try {
            $method_ctx->{description} = $self->_accessor_description($accessor, $type);

            $method = $self->accessor_metaclass->new(
                attribute     => $self,
                is_inline     => $inline_me,
                accessor_type => $type,
                package_name  => $self->associated_class->name,
                name          => $accessor,
                associated_metaclass => $self->associated_class,
                definition_context => $method_ctx,
            );
        }
        catch {
            $self->_throw_exception( CouldNotCreateMethod => attribute    => $self,
                                                     option_value => $accessor,
                                                     option_name  => $type,
                                                     error        => $_
                           );
        };
        $self->associate_method($method);
        return ($accessor, $method);
    }
}

sub _accessor_description {
    my $self = shift;
    my ($name, $type) = @_;

    my $desc = "$type " . $self->associated_class->name . "::$name";
    if ( $name ne $self->name ) {
        $desc .= " of attribute " . $self->name;
    }

    return $desc;
}

sub install_accessors {
    my $self   = shift;
    my $inline = shift;
    my $class  = $self->associated_class;

    $class->add_method(
        $self->_process_accessors('accessor' => $self->accessor(), $inline)
    ) if $self->has_accessor();

    $class->add_method(
        $self->_process_accessors('reader' => $self->reader(), $inline)
    ) if $self->has_reader();

    $class->add_method(
        $self->_process_accessors('writer' => $self->writer(), $inline)
    ) if $self->has_writer();

    $class->add_method(
        $self->_process_accessors('predicate' => $self->predicate(), $inline)
    ) if $self->has_predicate();

    $class->add_method(
        $self->_process_accessors('clearer' => $self->clearer(), $inline)
    ) if $self->has_clearer();

    return;
}

{
    my $_remove_accessor = sub {
        my ($accessor, $class) = @_;
        if (ref($accessor) && ref($accessor) eq 'HASH') {
            ($accessor) = keys %{$accessor};
        }
        my $method = $class->get_method($accessor);
        $class->remove_method($accessor)
            if (ref($method) && $method->isa('Class::MOP::Method::Accessor'));
    };

    sub remove_accessors {
        my $self = shift;
        # TODO:
        # we really need to make sure to remove from the
        # associates methods here as well. But this is
        # such a slimly used method, I am not worried
        # about it right now.
        $_remove_accessor->($self->accessor(),  $self->associated_class()) if $self->has_accessor();
        $_remove_accessor->($self->reader(),    $self->associated_class()) if $self->has_reader();
        $_remove_accessor->($self->writer(),    $self->associated_class()) if $self->has_writer();
        $_remove_accessor->($self->predicate(), $self->associated_class()) if $self->has_predicate();
        $_remove_accessor->($self->clearer(),   $self->associated_class()) if $self->has_clearer();
        return;
    }

}

1;

# ABSTRACT: Attribute Meta Object

__END__

=pod

=head1 DESCRIPTION

See the L<Moose::Meta::Attribute> documentation for API details.

=cut
