package Class::MOP::Class;
our $VERSION = '2.2006';

use strict;
use warnings;

use Class::MOP::Instance;
use Class::MOP::Method::Wrapped;
use Class::MOP::Method::Accessor;
use Class::MOP::Method::Constructor;
use Class::MOP::MiniTrait;

use Carp         'confess';
use Module::Runtime 'use_package_optimistically';
use Scalar::Util 'blessed';
use Sub::Name    'subname';
use Try::Tiny;
use List::Util 1.33 'all';

use parent 'Class::MOP::Module',
         'Class::MOP::Mixin::HasAttributes',
         'Class::MOP::Mixin::HasMethods',
         'Class::MOP::Mixin::HasOverloads';

# Creation

sub initialize {
    my $class = shift;

    my $package_name;

    if ( @_ % 2 ) {
        $package_name = shift;
    } else {
        my %options = @_;
        $package_name = $options{package};
    }

    ($package_name && !ref($package_name))
        || ($class||__PACKAGE__)->_throw_exception( InitializeTakesUnBlessedPackageName => package_name => $package_name );
    return Class::MOP::get_metaclass_by_name($package_name)
        || $class->_construct_class_instance(package => $package_name, @_);
}

sub reinitialize {
    my ( $class, @args ) = @_;
    unshift @args, "package" if @args % 2;
    my %options = @args;
    my $old_metaclass = blessed($options{package})
        ? $options{package}
        : Class::MOP::get_metaclass_by_name($options{package});
    $options{weaken} = Class::MOP::metaclass_is_weak($old_metaclass->name)
        if !exists $options{weaken}
        && blessed($old_metaclass)
        && $old_metaclass->isa('Class::MOP::Class');
    $old_metaclass->_remove_generated_metaobjects
        if $old_metaclass && $old_metaclass->isa('Class::MOP::Class');
    my $new_metaclass = $class->SUPER::reinitialize(%options);
    $new_metaclass->_restore_metaobjects_from($old_metaclass)
        if $old_metaclass && $old_metaclass->isa('Class::MOP::Class');
    return $new_metaclass;
}

# NOTE: (meta-circularity)
# this is a special form of _construct_instance
# (see below), which is used to construct class
# meta-object instances for any Class::MOP::*
# class. All other classes will use the more
# normal &construct_instance.
sub _construct_class_instance {
    my $class        = shift;
    my $options      = @_ == 1 ? $_[0] : {@_};
    my $package_name = $options->{package};
    (defined $package_name && $package_name)
        || $class->_throw_exception("ConstructClassInstanceTakesPackageName");
    # NOTE:
    # return the metaclass if we have it cached,
    # and it is still defined (it has not been
    # reaped by DESTROY yet, which can happen
    # annoyingly enough during global destruction)

    if (defined(my $meta = Class::MOP::get_metaclass_by_name($package_name))) {
        return $meta;
    }

    $class
        = ref $class
        ? $class->_real_ref_name
        : $class;

    # now create the metaclass
    my $meta;
    if ($class eq 'Class::MOP::Class') {
        $meta = $class->_new($options);
    }
    else {
        # NOTE:
        # it is safe to use meta here because
        # class will always be a subclass of
        # Class::MOP::Class, which defines meta
        $meta = $class->meta->_construct_instance($options)
    }

    # and check the metaclass compatibility
    $meta->_check_metaclass_compatibility();

    Class::MOP::store_metaclass_by_name($package_name, $meta);

    # NOTE:
    # we need to weaken any anon classes
    # so that they can call DESTROY properly
    Class::MOP::weaken_metaclass($package_name) if $options->{weaken};

    $meta;
}

sub _real_ref_name {
    my $self = shift;

    # NOTE: we need to deal with the possibility of class immutability here,
    # and then get the name of the class appropriately
    return $self->is_immutable
        ? $self->_get_mutable_metaclass_name()
        : ref $self;
}

sub _new {
    my $class = shift;

    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $options = @_ == 1 ? $_[0] : {@_};

    return bless {
        # inherited from Class::MOP::Package
        'package' => $options->{package},

        # NOTE:
        # since the following attributes will
        # actually be loaded from the symbol
        # table, and actually bypass the instance
        # entirely, we can just leave these things
        # listed here for reference, because they
        # should not actually have a value associated
        # with the slot.
        'namespace' => \undef,
        'methods'   => {},

        # inherited from Class::MOP::Module
        'version'   => \undef,
        'authority' => \undef,

        # defined in Class::MOP::Class
        'superclasses' => \undef,

        'attributes' => {},
        'attribute_metaclass' =>
            ( $options->{'attribute_metaclass'} || 'Class::MOP::Attribute' ),
        'method_metaclass' =>
            ( $options->{'method_metaclass'} || 'Class::MOP::Method' ),
        'wrapped_method_metaclass' => (
            $options->{'wrapped_method_metaclass'}
                || 'Class::MOP::Method::Wrapped'
        ),
        'instance_metaclass' =>
            ( $options->{'instance_metaclass'} || 'Class::MOP::Instance' ),
        'immutable_trait' => (
            $options->{'immutable_trait'}
                || 'Class::MOP::Class::Immutable::Trait'
        ),
        'constructor_name' => ( $options->{constructor_name} || 'new' ),
        'constructor_class' => (
            $options->{constructor_class} || 'Class::MOP::Method::Constructor'
        ),
        'destructor_class' => $options->{destructor_class},
    }, $class;
}

## Metaclass compatibility
{
    my %base_metaclass = (
        attribute_metaclass      => 'Class::MOP::Attribute',
        method_metaclass         => 'Class::MOP::Method',
        wrapped_method_metaclass => 'Class::MOP::Method::Wrapped',
        instance_metaclass       => 'Class::MOP::Instance',
        constructor_class        => 'Class::MOP::Method::Constructor',
        destructor_class         => 'Class::MOP::Method::Destructor',
    );

    sub _base_metaclasses { %base_metaclass }
}

sub _check_metaclass_compatibility {
    my $self = shift;

    my @superclasses = $self->superclasses
        or return;

    $self->_fix_metaclass_incompatibility(@superclasses);

    my %base_metaclass = $self->_base_metaclasses;

    # this is always okay ...
    return
        if ref($self) eq 'Class::MOP::Class'
            && all {
                my $meta = $self->$_;
                !defined($meta) || $meta eq $base_metaclass{$_};
        }
        keys %base_metaclass;

    for my $superclass (@superclasses) {
        $self->_check_class_metaclass_compatibility($superclass);
    }

    for my $metaclass_type ( keys %base_metaclass ) {
        next unless defined $self->$metaclass_type;
        for my $superclass (@superclasses) {
            $self->_check_single_metaclass_compatibility( $metaclass_type,
                $superclass );
        }
    }
}

sub _check_class_metaclass_compatibility {
    my $self = shift;
    my ( $superclass_name ) = @_;

    if (!$self->_class_metaclass_is_compatible($superclass_name)) {
        my $super_meta = Class::MOP::get_metaclass_by_name($superclass_name);

        my $super_meta_type = $super_meta->_real_ref_name;

        $self->_throw_exception( IncompatibleMetaclassOfSuperclass => class_name           => $self->name,
                                                              class_meta_type      => ref( $self ),
                                                              superclass_name      => $superclass_name,
                                                              superclass_meta_type => $super_meta_type
                       );
    }
}

sub _class_metaclass_is_compatible {
    my $self = shift;
    my ( $superclass_name ) = @_;

    my $super_meta = Class::MOP::get_metaclass_by_name($superclass_name)
        || return 1;

    my $super_meta_name = $super_meta->_real_ref_name;

    return $self->_is_compatible_with($super_meta_name);
}

sub _check_single_metaclass_compatibility {
    my $self = shift;
    my ( $metaclass_type, $superclass_name ) = @_;

    if (!$self->_single_metaclass_is_compatible($metaclass_type, $superclass_name)) {
        my $super_meta = Class::MOP::get_metaclass_by_name($superclass_name);

        $self->_throw_exception( MetaclassTypeIncompatible => class_name      => $self->name,
                                                      superclass_name => $superclass_name,
                                                      metaclass_type  => $metaclass_type
                       );
    }
}

sub _single_metaclass_is_compatible {
    my $self = shift;
    my ( $metaclass_type, $superclass_name ) = @_;

    my $super_meta = Class::MOP::get_metaclass_by_name($superclass_name)
        || return 1;

    # for instance, Moose::Meta::Class has a error_class attribute, but
    # Class::MOP::Class doesn't - this shouldn't be an error
    return 1 unless $super_meta->can($metaclass_type);
    # for instance, Moose::Meta::Class has a destructor_class, but
    # Class::MOP::Class doesn't - this shouldn't be an error
    return 1 unless defined $super_meta->$metaclass_type;
    # if metaclass is defined in superclass but not here, it's not compatible
    # this is a really odd case
    return 0 unless defined $self->$metaclass_type;

    return $self->$metaclass_type->_is_compatible_with($super_meta->$metaclass_type);
}

sub _fix_metaclass_incompatibility {
    my $self = shift;
    my @supers = map { Class::MOP::Class->initialize($_) } @_;

    my $necessary = 0;
    for my $super (@supers) {
        $necessary = 1
            if $self->_can_fix_metaclass_incompatibility($super);
    }
    return unless $necessary;

    for my $super (@supers) {
        if (!$self->_class_metaclass_is_compatible($super->name)) {
            $self->_fix_class_metaclass_incompatibility($super);
        }
    }

    my %base_metaclass = $self->_base_metaclasses;
    for my $metaclass_type (keys %base_metaclass) {
        for my $super (@supers) {
            if (!$self->_single_metaclass_is_compatible($metaclass_type, $super->name)) {
                $self->_fix_single_metaclass_incompatibility(
                    $metaclass_type, $super
                );
            }
        }
    }
}

sub _can_fix_metaclass_incompatibility {
    my $self = shift;
    my ($super_meta) = @_;

    return 1 if $self->_class_metaclass_can_be_made_compatible($super_meta);

    my %base_metaclass = $self->_base_metaclasses;
    for my $metaclass_type (keys %base_metaclass) {
        return 1 if $self->_single_metaclass_can_be_made_compatible($super_meta, $metaclass_type);
    }

    return;
}

sub _class_metaclass_can_be_made_compatible {
    my $self = shift;
    my ($super_meta) = @_;

    return $self->_can_be_made_compatible_with($super_meta->_real_ref_name);
}

sub _single_metaclass_can_be_made_compatible {
    my $self = shift;
    my ($super_meta, $metaclass_type) = @_;

    my $specific_meta = $self->$metaclass_type;

    return unless $super_meta->can($metaclass_type);
    my $super_specific_meta = $super_meta->$metaclass_type;

    # for instance, Moose::Meta::Class has a destructor_class, but
    # Class::MOP::Class doesn't - this shouldn't be an error
    return unless defined $super_specific_meta;

    # if metaclass is defined in superclass but not here, it's fixable
    # this is a really odd case
    return 1 unless defined $specific_meta;

    return 1 if $specific_meta->_can_be_made_compatible_with($super_specific_meta);
}

sub _fix_class_metaclass_incompatibility {
    my $self = shift;
    my ( $super_meta ) = @_;

    if ($self->_class_metaclass_can_be_made_compatible($super_meta)) {
        ($self->is_pristine)
            || $self->_throw_exception( CannotFixMetaclassCompatibility => class_name => $self->name,
                                                                   superclass => $super_meta
                              );

        my $super_meta_name = $super_meta->_real_ref_name;

        $self->_make_compatible_with($super_meta_name);
    }
}

sub _fix_single_metaclass_incompatibility {
    my $self = shift;
    my ( $metaclass_type, $super_meta ) = @_;

    if ($self->_single_metaclass_can_be_made_compatible($super_meta, $metaclass_type)) {
        ($self->is_pristine)
            || $self->_throw_exception( CannotFixMetaclassCompatibility => class_name     => $self->name,
                                                                   superclass     => $super_meta,
                                                                   metaclass_type => $metaclass_type
                              );

        my $new_metaclass = $self->$metaclass_type
            ? $self->$metaclass_type->_get_compatible_metaclass($super_meta->$metaclass_type)
            : $super_meta->$metaclass_type;
        $self->{$metaclass_type} = $new_metaclass;
    }
}

sub _restore_metaobjects_from {
    my $self = shift;
    my ($old_meta) = @_;

    $self->_restore_metamethods_from($old_meta);
    $self->_restore_metaattributes_from($old_meta);
}

sub _remove_generated_metaobjects {
    my $self = shift;

    for my $attr (map { $self->get_attribute($_) } $self->get_attribute_list) {
        $attr->remove_accessors;
    }
}

# creating classes with MOP ...

sub create {
    my $class = shift;
    my @args = @_;

    unshift @args, 'package' if @args % 2 == 1;
    my %options = @args;

    (ref $options{superclasses} eq 'ARRAY')
        || __PACKAGE__->_throw_exception( CreateMOPClassTakesArrayRefOfSuperclasses => class  => $class,
                                                                         params => \%options
                          )
            if exists $options{superclasses};

    (ref $options{attributes} eq 'ARRAY')
        || __PACKAGE__->_throw_exception( CreateMOPClassTakesArrayRefOfAttributes => class  => $class,
                                                                       params => \%options
                          )
            if exists $options{attributes};

    (ref $options{methods} eq 'HASH')
        || __PACKAGE__->_throw_exception( CreateMOPClassTakesHashRefOfMethods => class  => $class,
                                                                   params => \%options
                          )
            if exists $options{methods};

    my $package      = delete $options{package};
    my $superclasses = delete $options{superclasses};
    my $attributes   = delete $options{attributes};
    my $methods      = delete $options{methods};
    my $meta_name    = exists $options{meta_name}
                         ? delete $options{meta_name}
                         : 'meta';

    my $meta = $class->SUPER::create($package => %options);

    $meta->_add_meta_method($meta_name)
        if defined $meta_name;

    $meta->superclasses(@{$superclasses})
        if defined $superclasses;
    # NOTE:
    # process attributes first, so that they can
    # install accessors, but locally defined methods
    # can then overwrite them. It is maybe a little odd, but
    # I think this should be the order of things.
    if (defined $attributes) {
        foreach my $attr (@{$attributes}) {
            $meta->add_attribute($attr);
        }
    }
    if (defined $methods) {
        foreach my $method_name (keys %{$methods}) {
            $meta->add_method($method_name, $methods->{$method_name});
        }
    }
    return $meta;
}

# XXX: something more intelligent here?
sub _anon_package_prefix { 'Class::MOP::Class::__ANON__::SERIAL::' }

sub create_anon_class { shift->create_anon(@_) }
sub is_anon_class     { shift->is_anon(@_)     }

sub _anon_cache_key {
    my $class = shift;
    my %options = @_;
    # Makes something like Super::Class|Super::Class::2
    return join '=' => (
        join( '|', sort @{ $options{superclasses} || [] } ),
    );
}

# Instance Construction & Cloning

sub new_object {
    my $class = shift;

    # NOTE:
    # we need to protect the integrity of the
    # Class::MOP::Class singletons here, so we
    # delegate this to &construct_class_instance
    # which will deal with the singletons
    return $class->_construct_class_instance(@_)
        if $class->name->isa('Class::MOP::Class');
    return $class->_construct_instance(@_);
}

sub _construct_instance {
    my $class = shift;
    my $params = @_ == 1 ? $_[0] : {@_};
    my $meta_instance = $class->get_meta_instance();
    # FIXME:
    # the code below is almost certainly incorrect
    # but this is foreign inheritance, so we might
    # have to kludge it in the end.
    my $instance;
    if (my $instance_class = blessed($params->{__INSTANCE__})) {
        ($instance_class eq $class->name)
            || $class->_throw_exception( InstanceBlessedIntoWrongClass => class_name => $class->name,
                                                                 params     => $params,
                                                                 instance   => $params->{__INSTANCE__}
                              );
        $instance = $params->{__INSTANCE__};
    }
    elsif (exists $params->{__INSTANCE__}) {
        $class->_throw_exception( InstanceMustBeABlessedReference => class_name => $class->name,
                                                            params     => $params,
                                                            instance   => $params->{__INSTANCE__}
                       );
    }
    else {
        $instance = $meta_instance->create_instance();
    }
    foreach my $attr ($class->get_all_attributes()) {
        $attr->initialize_instance_slot($meta_instance, $instance, $params);
    }
    if (Class::MOP::metaclass_is_weak($class->name)) {
        $meta_instance->_set_mop_slot($instance, $class);
    }
    return $instance;
}

sub _inline_new_object {
    my $self = shift;

    return (
        'my $class = shift;',
        '$class = Scalar::Util::blessed($class) || $class;',
        $self->_inline_fallback_constructor('$class'),
        $self->_inline_params('$params', '$class'),
        $self->_inline_generate_instance('$instance', '$class'),
        $self->_inline_slot_initializers,
        $self->_inline_preserve_weak_metaclasses,
        $self->_inline_extra_init,
        'return $instance',
    );
}

sub _inline_fallback_constructor {
    my $self = shift;
    my ($class) = @_;
    return (
        'return ' . $self->_generate_fallback_constructor($class),
            'if ' . $class . ' ne \'' . $self->name . '\';',
    );
}

sub _generate_fallback_constructor {
    my $self = shift;
    my ($class) = @_;
    return 'Class::MOP::Class->initialize(' . $class . ')->new_object(@_)',
}

sub _inline_params {
    my $self = shift;
    my ($params, $class) = @_;
    return (
        'my ' . $params . ' = @_ == 1 ? $_[0] : {@_};',
    );
}

sub _inline_generate_instance {
    my $self = shift;
    my ($inst, $class) = @_;
    return (
        'my ' . $inst . ' = ' . $self->_inline_create_instance($class) . ';',
    );
}

sub _inline_create_instance {
    my $self = shift;

    return $self->get_meta_instance->inline_create_instance(@_);
}

sub _inline_slot_initializers {
    my $self = shift;

    my $idx = 0;

    return map { $self->_inline_slot_initializer($_, $idx++) }
               sort { $a->name cmp $b->name } $self->get_all_attributes;
}

sub _inline_slot_initializer {
    my $self  = shift;
    my ($attr, $idx) = @_;

    if (defined(my $init_arg = $attr->init_arg)) {
        my @source = (
            'if (exists $params->{\'' . $init_arg . '\'}) {',
                $self->_inline_init_attr_from_constructor($attr, $idx),
            '}',
        );
        if (my @default = $self->_inline_init_attr_from_default($attr, $idx)) {
            push @source, (
                'else {',
                    @default,
                '}',
            );
        }
        return @source;
    }
    elsif (my @default = $self->_inline_init_attr_from_default($attr, $idx)) {
        return (
            '{',
                @default,
            '}',
        );
    }
    else {
        return ();
    }
}

sub _inline_init_attr_from_constructor {
    my $self = shift;
    my ($attr, $idx) = @_;

    my @initial_value = $attr->_inline_set_value(
        '$instance', '$params->{\'' . $attr->init_arg . '\'}',
    );

    push @initial_value, (
        '$attrs->[' . $idx . ']->set_initial_value(',
            '$instance,',
            $attr->_inline_instance_get('$instance'),
        ');',
    ) if $attr->has_initializer;

    return @initial_value;
}

sub _inline_init_attr_from_default {
    my $self = shift;
    my ($attr, $idx) = @_;

    my $default = $self->_inline_default_value($attr, $idx);
    return unless $default;

    my @initial_value = $attr->_inline_set_value('$instance', $default);

    push @initial_value, (
        '$attrs->[' . $idx . ']->set_initial_value(',
            '$instance,',
            $attr->_inline_instance_get('$instance'),
        ');',
    ) if $attr->has_initializer;

    return @initial_value;
}

sub _inline_default_value {
    my $self = shift;
    my ($attr, $index) = @_;

    if ($attr->has_default) {
        # NOTE:
        # default values can either be CODE refs
        # in which case we need to call them. Or
        # they can be scalars (strings/numbers)
        # in which case we can just deal with them
        # in the code we eval.
        if ($attr->is_default_a_coderef) {
            return '$defaults->[' . $index . ']->($instance)';
        }
        else {
            return '$defaults->[' . $index . ']';
        }
    }
    elsif ($attr->has_builder) {
        return '$instance->' . $attr->builder;
    }
    else {
        return;
    }
}

sub _inline_preserve_weak_metaclasses {
    my $self = shift;
    if (Class::MOP::metaclass_is_weak($self->name)) {
        return (
            $self->_inline_set_mop_slot(
                '$instance', 'Class::MOP::class_of($class)'
            ) . ';'
        );
    }
    else {
        return ();
    }
}

sub _inline_extra_init { }

sub _eval_environment {
    my $self = shift;

    my @attrs = sort { $a->name cmp $b->name } $self->get_all_attributes;

    my $defaults = [map { $_->default } @attrs];

    return {
        '$defaults' => \$defaults,
    };
}


sub get_meta_instance {
    my $self = shift;
    $self->{'_meta_instance'} ||= $self->_create_meta_instance();
}

sub _create_meta_instance {
    my $self = shift;

    my $instance = $self->instance_metaclass->new(
        associated_metaclass => $self,
        attributes => [ $self->get_all_attributes() ],
    );

    $self->add_meta_instance_dependencies()
        if $instance->is_dependent_on_superclasses();

    return $instance;
}

# TODO: this is actually not being used!
sub _inline_rebless_instance {
    my $self = shift;

    return $self->get_meta_instance->inline_rebless_instance_structure(@_);
}

sub _inline_get_mop_slot {
    my $self = shift;

    return $self->get_meta_instance->_inline_get_mop_slot(@_);
}

sub _inline_set_mop_slot {
    my $self = shift;

    return $self->get_meta_instance->_inline_set_mop_slot(@_);
}

sub _inline_clear_mop_slot {
    my $self = shift;

    return $self->get_meta_instance->_inline_clear_mop_slot(@_);
}

sub clone_object {
    my $class    = shift;
    my $instance = shift;
    (blessed($instance) && $instance->isa($class->name))
        || $class->_throw_exception( CloneObjectExpectsAnInstanceOfMetaclass => class_name => $class->name,
                                                                       instance   => $instance,
                          );
    # NOTE:
    # we need to protect the integrity of the
    # Class::MOP::Class singletons here, they
    # should not be cloned.
    return $instance if $instance->isa('Class::MOP::Class');
    $class->_clone_instance($instance, @_);
}

sub _clone_instance {
    my ($class, $instance, %params) = @_;
    (blessed($instance))
        || $class->_throw_exception( OnlyInstancesCanBeCloned => class_name => $class->name,
                                                        instance   => $instance,
                                                        params     => \%params
                          );
    my $meta_instance = $class->get_meta_instance();
    my $clone = $meta_instance->clone_instance($instance);
    foreach my $attr ($class->get_all_attributes()) {
        if ( defined( my $init_arg = $attr->init_arg ) ) {
            if (exists $params{$init_arg}) {
                $attr->set_value($clone, $params{$init_arg});
            }
        }
    }
    return $clone;
}

sub _force_rebless_instance {
    my ($self, $instance, %params) = @_;
    my $old_metaclass = Class::MOP::class_of($instance);

    $old_metaclass->rebless_instance_away($instance, $self, %params)
        if $old_metaclass;

    my $meta_instance = $self->get_meta_instance;

    if (Class::MOP::metaclass_is_weak($old_metaclass->name)) {
        $meta_instance->_clear_mop_slot($instance);
    }

    # rebless!
    # we use $_[1] here because of t/cmop/rebless_overload.t regressions
    # on 5.8.8
    $meta_instance->rebless_instance_structure($_[1], $self);

    $self->_fixup_attributes_after_rebless($instance, $old_metaclass, %params);

    if (Class::MOP::metaclass_is_weak($self->name)) {
        $meta_instance->_set_mop_slot($instance, $self);
    }
}

sub rebless_instance {
    my ($self, $instance, %params) = @_;
    my $old_metaclass = Class::MOP::class_of($instance);

    my $old_class = $old_metaclass ? $old_metaclass->name : blessed($instance);
    $self->name->isa($old_class)
        || $self->_throw_exception( CanReblessOnlyIntoASubclass => class_name     => $self->name,
                                                           instance       => $instance,
                                                           instance_class => blessed( $instance ),
                                                           params         => \%params,
                          );

    $self->_force_rebless_instance($_[1], %params);

    return $instance;
}

sub rebless_instance_back {
    my ( $self, $instance ) = @_;
    my $old_metaclass = Class::MOP::class_of($instance);
    my $old_class
        = $old_metaclass ? $old_metaclass->name : blessed($instance);
    $old_class->isa( $self->name )
        || $self->_throw_exception( CanReblessOnlyIntoASuperclass => class_name     => $self->name,
                                                             instance       => $instance,
                                                             instance_class => blessed( $instance ),
                          );

    $self->_force_rebless_instance($_[1]);

    return $instance;
}

sub rebless_instance_away {
    # this intentionally does nothing, it is just a hook
}

sub _fixup_attributes_after_rebless {
    my $self = shift;
    my ($instance, $rebless_from, %params) = @_;
    my $meta_instance = $self->get_meta_instance;

    for my $attr ( $rebless_from->get_all_attributes ) {
        next if $self->find_attribute_by_name( $attr->name );
        $meta_instance->deinitialize_slot( $instance, $_ ) for $attr->slots;
    }

    foreach my $attr ( $self->get_all_attributes ) {
        if ( $attr->has_value($instance) ) {
            if ( defined( my $init_arg = $attr->init_arg ) ) {
                $params{$init_arg} = $attr->get_value($instance)
                    unless exists $params{$init_arg};
            }
            else {
                $attr->set_value($instance, $attr->get_value($instance));
            }
        }
    }

    foreach my $attr ($self->get_all_attributes) {
        $attr->initialize_instance_slot($meta_instance, $instance, \%params);
    }
}

sub _attach_attribute {
    my ($self, $attribute) = @_;
    $attribute->attach_to_class($self);
}

sub _post_add_attribute {
    my ( $self, $attribute ) = @_;

    $self->invalidate_meta_instances;

    # invalidate package flag here
    try {
        local $SIG{__DIE__};
        $attribute->install_accessors;
    }
    catch {
        $self->remove_attribute( $attribute->name );
        die $_;
    };
}

sub remove_attribute {
    my $self = shift;

    my $removed_attribute = $self->SUPER::remove_attribute(@_)
        or return;

    $self->invalidate_meta_instances;

    $removed_attribute->remove_accessors;
    $removed_attribute->detach_from_class;

    return$removed_attribute;
}

sub find_attribute_by_name {
    my ( $self, $attr_name ) = @_;

    foreach my $class ( $self->linearized_isa ) {
        # fetch the meta-class ...
        my $meta = Class::MOP::Class->initialize($class);
        return $meta->get_attribute($attr_name)
            if $meta->has_attribute($attr_name);
    }

    return;
}

sub get_all_attributes {
    my $self = shift;
    my %attrs = map { %{ Class::MOP::Class->initialize($_)->_attribute_map } }
        reverse $self->linearized_isa;
    return values %attrs;
}

# Inheritance

sub superclasses {
    my $self     = shift;

    my $isa = $self->get_or_add_package_symbol('@ISA');

    if (@_) {
        my @supers = @_;
        @{$isa} = @supers;

        # NOTE:
        # on 5.8 and below, we need to call
        # a method to get Perl to detect
        # a cycle in the class hierarchy
        my $class = $self->name;
        $class->isa($class);

        # NOTE:
        # we need to check the metaclass
        # compatibility here so that we can
        # be sure that the superclass is
        # not potentially creating an issues
        # we don't know about

        $self->_check_metaclass_compatibility();
        $self->_superclasses_updated();
    }

    return @{$isa};
}

sub _superclasses_updated {
    my $self = shift;
    $self->update_meta_instance_dependencies();
    # keep strong references to all our parents, so they don't disappear if
    # they are anon classes and don't have any direct instances
    $self->_superclass_metas(
        map { Class::MOP::class_of($_) } $self->superclasses
    );
}

sub _superclass_metas {
    my $self = shift;
    $self->{_superclass_metas} = [@_];
}

sub subclasses {
    my $self = shift;
    my $super_class = $self->name;

    return @{ $super_class->mro::get_isarev() };
}

sub direct_subclasses {
    my $self = shift;
    my $super_class = $self->name;

    return grep {
        grep {
            $_ eq $super_class
        } Class::MOP::Class->initialize($_)->superclasses
    } $self->subclasses;
}

sub linearized_isa {
    return @{ mro::get_linear_isa( (shift)->name ) };
}

sub class_precedence_list {
    my $self = shift;
    my $name = $self->name;

    unless (Class::MOP::IS_RUNNING_ON_5_10()) {
        # NOTE:
        # We need to check for circular inheritance here
        # if we are not on 5.10, cause 5.8 detects it late.
        # This will do nothing if all is well, and blow up
        # otherwise. Yes, it's an ugly hack, better
        # suggestions are welcome.
        # - SL
        ($name || return)->isa('This is a test for circular inheritance')
    }

    # if our mro is c3, we can
    # just grab the linear_isa
    if (mro::get_mro($name) eq 'c3') {
        return @{ mro::get_linear_isa($name) }
    }
    else {
        # NOTE:
        # we can't grab the linear_isa for dfs
        # since it has all the duplicates
        # already removed.
        return (
            $name,
            map {
                Class::MOP::Class->initialize($_)->class_precedence_list()
            } $self->superclasses()
        );
    }
}

sub _method_lookup_order {
    return (shift->linearized_isa, 'UNIVERSAL');
}

## Methods

{
    my $fetch_and_prepare_method = sub {
        my ($self, $method_name) = @_;
        my $wrapped_metaclass = $self->wrapped_method_metaclass;
        # fetch it locally
        my $method = $self->get_method($method_name);
        # if we don't have local ...
        unless ($method) {
            # try to find the next method
            $method = $self->find_next_method_by_name($method_name);
            # die if it does not exist
            (defined $method)
                || $self->_throw_exception( MethodNameNotFoundInInheritanceHierarchy => class_name  => $self->name,
                                                                                method_name => $method_name
                                  );
            # and now make sure to wrap it
            # even if it is already wrapped
            # because we need a new sub ref
            $method = $wrapped_metaclass->wrap($method,
                package_name => $self->name,
                name         => $method_name,
            );
        }
        else {
            # now make sure we wrap it properly
            $method = $wrapped_metaclass->wrap($method,
                package_name => $self->name,
                name         => $method_name,
            ) unless $method->isa($wrapped_metaclass);
        }
        $self->add_method($method_name => $method);
        return $method;
    };

    sub add_before_method_modifier {
        my ($self, $method_name, $method_modifier) = @_;
        (defined $method_name && length $method_name)
            || $self->_throw_exception( MethodModifierNeedsMethodName => class_name => $self->name );
        my $method = $fetch_and_prepare_method->($self, $method_name);
        $method->add_before_modifier(
            subname(':before' => $method_modifier)
        );
    }

    sub add_after_method_modifier {
        my ($self, $method_name, $method_modifier) = @_;
        (defined $method_name && length $method_name)
            || $self->_throw_exception( MethodModifierNeedsMethodName => class_name => $self->name );
        my $method = $fetch_and_prepare_method->($self, $method_name);
        $method->add_after_modifier(
            subname(':after' => $method_modifier)
        );
    }

    sub add_around_method_modifier {
        my ($self, $method_name, $method_modifier) = @_;
        (defined $method_name && length $method_name)
            || $self->_throw_exception( MethodModifierNeedsMethodName => class_name => $self->name );
        my $method = $fetch_and_prepare_method->($self, $method_name);
        $method->add_around_modifier(
            subname(':around' => $method_modifier)
        );
    }

    # NOTE:
    # the methods above used to be named like this:
    #    ${pkg}::${method}:(before|after|around)
    # but this proved problematic when using one modifier
    # to wrap multiple methods (something which is likely
    # to happen pretty regularly IMO). So instead of naming
    # it like this, I have chosen to just name them purely
    # with their modifier names, like so:
    #    :(before|after|around)
    # The fact is that in a stack trace, it will be fairly
    # evident from the context what method they are attached
    # to, and so don't need the fully qualified name.
}

sub find_method_by_name {
    my ($self, $method_name) = @_;
    (defined $method_name && length $method_name)
        || $self->_throw_exception( MethodNameNotGiven => class_name => $self->name );
    foreach my $class ($self->_method_lookup_order) {
        my $method = Class::MOP::Class->initialize($class)->get_method($method_name);
        return $method if defined $method;
    }
    return;
}

sub get_all_methods {
    my $self = shift;

    my %methods;
    for my $class ( reverse $self->_method_lookup_order ) {
        my $meta = Class::MOP::Class->initialize($class);

        $methods{ $_->name } = $_ for $meta->_get_local_methods;
    }

    return values %methods;
}

sub get_all_method_names {
    my $self = shift;
    map { $_->name } $self->get_all_methods;
}

sub find_all_methods_by_name {
    my ($self, $method_name) = @_;
    (defined $method_name && length $method_name)
        || $self->_throw_exception( MethodNameNotGiven => class_name => $self->name );
    my @methods;
    foreach my $class ($self->_method_lookup_order) {
        # fetch the meta-class ...
        my $meta = Class::MOP::Class->initialize($class);
        push @methods => {
            name  => $method_name,
            class => $class,
            code  => $meta->get_method($method_name)
        } if $meta->has_method($method_name);
    }
    return @methods;
}

sub find_next_method_by_name {
    my ($self, $method_name) = @_;
    (defined $method_name && length $method_name)
        || $self->_throw_exception( MethodNameNotGiven => class_name => $self->name );
    my @cpl = ($self->_method_lookup_order);
    shift @cpl; # discard ourselves
    foreach my $class (@cpl) {
        my $method = Class::MOP::Class->initialize($class)->get_method($method_name);
        return $method if defined $method;
    }
    return;
}

sub update_meta_instance_dependencies {
    my $self = shift;

    if ( $self->{meta_instance_dependencies} ) {
        return $self->add_meta_instance_dependencies;
    }
}

sub add_meta_instance_dependencies {
    my $self = shift;

    $self->remove_meta_instance_dependencies;

    my @attrs = $self->get_all_attributes();

    my %seen;
    my @classes = grep { not $seen{ $_->name }++ }
        map { $_->associated_class } @attrs;

    foreach my $class (@classes) {
        $class->add_dependent_meta_instance($self);
    }

    $self->{meta_instance_dependencies} = \@classes;
}

sub remove_meta_instance_dependencies {
    my $self = shift;

    if ( my $classes = delete $self->{meta_instance_dependencies} ) {
        foreach my $class (@$classes) {
            $class->remove_dependent_meta_instance($self);
        }

        return $classes;
    }

    return;

}

sub add_dependent_meta_instance {
    my ( $self, $metaclass ) = @_;
    push @{ $self->{dependent_meta_instances} }, $metaclass;
}

sub remove_dependent_meta_instance {
    my ( $self, $metaclass ) = @_;
    my $name = $metaclass->name;
    @$_ = grep { $_->name ne $name } @$_
        for $self->{dependent_meta_instances};
}

sub invalidate_meta_instances {
    my $self = shift;
    $_->invalidate_meta_instance()
        for $self, @{ $self->{dependent_meta_instances} };
}

sub invalidate_meta_instance {
    my $self = shift;
    undef $self->{_meta_instance};
}

# check if we can reinitialize
sub is_pristine {
    my $self = shift;

    # if any local attr is defined
    return if $self->get_attribute_list;

    # or any non-declared methods
    for my $method ( map { $self->get_method($_) } $self->get_method_list ) {
        return if $method->isa("Class::MOP::Method::Generated");
        # FIXME do we need to enforce this too? return unless $method->isa( $self->method_metaclass );
    }

    return 1;
}

## Class closing

sub is_mutable   { 1 }
sub is_immutable { 0 }

sub immutable_options { %{ $_[0]{__immutable}{options} || {} } }

sub _immutable_options {
    my ( $self, @args ) = @_;

    return (
        inline_accessors   => 1,
        inline_constructor => 1,
        inline_destructor  => 0,
        debug              => 0,
        immutable_trait    => $self->immutable_trait,
        constructor_name   => $self->constructor_name,
        constructor_class  => $self->constructor_class,
        destructor_class   => $self->destructor_class,
        @args,
    );
}

sub make_immutable {
    my ( $self, @args ) = @_;

    return $self unless $self->is_mutable;

    my ($file, $line) = (caller)[1..2];

    $self->_initialize_immutable(
        file => $file,
        line => $line,
        $self->_immutable_options(@args),
    );
    $self->_rebless_as_immutable(@args);

    return $self;
}

sub make_mutable {
    my $self = shift;

    if ( $self->is_immutable ) {
        my @args = $self->immutable_options;
        $self->_rebless_as_mutable();
        $self->_remove_inlined_code(@args);
        delete $self->{__immutable};
        return $self;
    }
    else {
        return;
    }
}

sub _rebless_as_immutable {
    my ( $self, @args ) = @_;

    $self->{__immutable}{original_class} = ref $self;

    bless $self => $self->_immutable_metaclass(@args);
}

sub _immutable_metaclass {
    my ( $self, %args ) = @_;

    if ( my $class = $args{immutable_metaclass} ) {
        return $class;
    }

    my $trait = $args{immutable_trait} = $self->immutable_trait
        || $self->_throw_exception( NoImmutableTraitSpecifiedForClass => class_name => $self->name,
                                                                 params     => \%args
                          );

    my $meta      = $self->meta;
    my $meta_attr = $meta->find_attribute_by_name("immutable_trait");

    my $class_name;

    if ( $meta_attr and $trait eq $meta_attr->default ) {
        # if the trait is the same as the default we try and pick a
        # predictable name for the immutable metaclass
        $class_name = 'Class::MOP::Class::Immutable::' . ref($self);
    }
    else {
        $class_name = join '::', 'Class::MOP::Class::Immutable::CustomTrait',
            $trait, 'ForMetaClass', ref($self);
    }

    return $class_name
        if Class::MOP::does_metaclass_exist($class_name);

    # If the metaclass is a subclass of CMOP::Class which has had
    # metaclass roles applied (via Moose), then we want to make sure
    # that we preserve that anonymous class (see Fey::ORM for an
    # example of where this matters).
    my $meta_name = $meta->_real_ref_name;

    my $immutable_meta = $meta_name->create(
        $class_name,
        superclasses => [ ref $self ],
    );

    Class::MOP::MiniTrait::apply( $immutable_meta, $trait );

    $immutable_meta->make_immutable(
        inline_constructor => 0,
        inline_accessors   => 0,
    );

    return $class_name;
}

sub _remove_inlined_code {
    my $self = shift;

    $self->remove_method( $_->name ) for $self->_inlined_methods;

    delete $self->{__immutable}{inlined_methods};
}

sub _inlined_methods { @{ $_[0]{__immutable}{inlined_methods} || [] } }

sub _add_inlined_method {
    my ( $self, $method ) = @_;

    push @{ $self->{__immutable}{inlined_methods} ||= [] }, $method;
}

sub _initialize_immutable {
    my ( $self, %args ) = @_;

    $self->{__immutable}{options} = \%args;
    $self->_install_inlined_code(%args);
}

sub _install_inlined_code {
    my ( $self, %args ) = @_;

    # FIXME
    $self->_inline_accessors(%args)   if $args{inline_accessors};
    $self->_inline_constructor(%args) if $args{inline_constructor};
    $self->_inline_destructor(%args)  if $args{inline_destructor};
}

sub _rebless_as_mutable {
    my $self = shift;

    bless $self, $self->_get_mutable_metaclass_name;

    return $self;
}

sub _inline_accessors {
    my $self = shift;

    foreach my $attr_name ( $self->get_attribute_list ) {
        $self->get_attribute($attr_name)->install_accessors(1);
    }
}

sub _inline_constructor {
    my ( $self, %args ) = @_;

    my $name = $args{constructor_name};
    # A class may not even have a constructor, and that's okay.
    return unless defined $name;

    if ( $self->has_method($name) && !$args{replace_constructor} ) {
        my $class = $self->name;
        warn "Not inlining a constructor for $class since it defines"
            . " its own constructor.\n"
            . "If you are certain you don't need to inline your"
            . " constructor, specify inline_constructor => 0 in your"
            . " call to $class->meta->make_immutable\n";
        return;
    }

    my $constructor_class = $args{constructor_class};

    {
        local $@;
        use_package_optimistically($constructor_class);
    }

    my $constructor = $constructor_class->new(
        options      => \%args,
        metaclass    => $self,
        is_inline    => 1,
        package_name => $self->name,
        name         => $name,
        definition_context => {
            description => "constructor " . $self->name . "::" . $name,
            file        => $args{file},
            line        => $args{line},
        },
    );

    if ( $args{replace_constructor} or $constructor->can_be_inlined ) {
        $self->add_method( $name => $constructor );
        $self->_add_inlined_method($constructor);
    }
}

sub _inline_destructor {
    my ( $self, %args ) = @_;

    ( exists $args{destructor_class} && defined $args{destructor_class} )
        || $self->_throw_exception( NoDestructorClassSpecified => class_name => $self->name,
                                                          params     => \%args,
                          );

    if ( $self->has_method('DESTROY') && ! $args{replace_destructor} ) {
        my $class = $self->name;
        warn "Not inlining a destructor for $class since it defines"
            . " its own destructor.\n";
        return;
    }

    my $destructor_class = $args{destructor_class};

    {
        local $@;
        use_package_optimistically($destructor_class);
    }

    return unless $destructor_class->is_needed($self);

    my $destructor = $destructor_class->new(
        options      => \%args,
        metaclass    => $self,
        package_name => $self->name,
        name         => 'DESTROY',
        definition_context => {
            description => "destructor " . $self->name . "::DESTROY",
            file        => $args{file},
            line        => $args{line},
        },
    );

    if ( $args{replace_destructor} or $destructor->can_be_inlined ) {
        $self->add_method( 'DESTROY' => $destructor );
        $self->_add_inlined_method($destructor);
    }
}

1;

# ABSTRACT: Class Meta Object

__END__

=pod

=head1 DESCRIPTION

See the L<Moose::Meta::Class> documentation for API details.

=cut
