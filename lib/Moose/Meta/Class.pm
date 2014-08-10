package Moose::Meta::Class;
our $VERSION = '2.2006';

use strict;
use warnings;

use Class::MOP;
use Data::OptList;
use List::Util 1.33 qw( any );
use Scalar::Util 'blessed';

use Moose::Meta::Method::Overridden;
use Moose::Meta::Method::Augmented;
use Moose::Meta::Class::Immutable::Trait;
use Moose::Meta::Method::Constructor;
use Moose::Meta::Method::Destructor;
use Moose::Meta::Method::Meta;
use Moose::Util 'throw_exception';
use Class::MOP::MiniTrait;

use parent 'Class::MOP::Class';

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

__PACKAGE__->meta->add_attribute('roles' => (
    reader  => 'roles',
    default => sub { [] },
    Class::MOP::_definition_context(),
));

__PACKAGE__->meta->add_attribute('role_applications' => (
    reader  => '_get_role_applications',
    default => sub { [] },
    Class::MOP::_definition_context(),
));

__PACKAGE__->meta->add_attribute(
    Class::MOP::Attribute->new('immutable_trait' => (
        accessor => "immutable_trait",
        default  => 'Moose::Meta::Class::Immutable::Trait',
        Class::MOP::_definition_context(),
    ))
);

__PACKAGE__->meta->add_attribute('constructor_class' => (
    accessor => 'constructor_class',
    default  => 'Moose::Meta::Method::Constructor',
    Class::MOP::_definition_context(),
));

__PACKAGE__->meta->add_attribute('destructor_class' => (
    accessor => 'destructor_class',
    default  => 'Moose::Meta::Method::Destructor',
    Class::MOP::_definition_context(),
));

sub initialize {
    my $class = shift;
    my @args = @_;
    unshift @args, 'package' if @args % 2;
    my %opts = @args;
    my $package = delete $opts{package};
    return Class::MOP::get_metaclass_by_name($package)
        || $class->SUPER::initialize($package,
                'attribute_metaclass' => 'Moose::Meta::Attribute',
                'method_metaclass'    => 'Moose::Meta::Method',
                'instance_metaclass'  => 'Moose::Meta::Instance',
                %opts,
            );
}

sub create {
    my $class = shift;
    my @args = @_;

    unshift @args, 'package' if @args % 2 == 1;
    my %options = @args;

    (ref $options{roles} eq 'ARRAY')
        || throw_exception( RolesInCreateTakesAnArrayRef => params => \%options )
            if exists $options{roles};

    my $package = delete $options{package};
    my $roles   = delete $options{roles};

    my $new_meta = $class->SUPER::create($package, %options);

    if ($roles) {
        Moose::Util::apply_all_roles( $new_meta, @$roles );
    }

    return $new_meta;
}

sub _meta_method_class { 'Moose::Meta::Method::Meta' }

sub _anon_package_prefix { 'Moose::Meta::Class::__ANON__::SERIAL::' }

sub _anon_cache_key {
    my $class = shift;
    my %options = @_;

    my $superclass_key = join('|',
        map { $_->[0] } @{ Data::OptList::mkopt($options{superclasses} || []) }
    );

    my $roles = Data::OptList::mkopt(($options{roles} || []), {
        moniker  => 'role',
        val_test => sub { ref($_[0]) eq 'HASH' },
    });

    my @role_keys;
    for my $role_spec (@$roles) {
        my ($role, $params) = @$role_spec;
        $params = { %$params } if $params;

        my $key = blessed($role) ? $role->name : $role;

        if ($params && %$params) {
            my $alias    = delete $params->{'-alias'}
                        || delete $params->{'alias'}
                        || {};
            my $excludes = delete $params->{'-excludes'}
                        || delete $params->{'excludes'}
                        || [];
            $excludes = [$excludes] unless ref($excludes) eq 'ARRAY';

            if (%$params) {
                warn "Roles with parameters cannot be cached. Consider "
                   . "applying the parameters before calling "
                   . "create_anon_class, or using 'weaken => 0' instead";
                return;
            }

            my $alias_key = join('%',
                map { $_ => $alias->{$_} } sort keys %$alias
            );
            my $excludes_key = join('%',
                sort @$excludes
            );
            $key .= '<' . join('+', 'a', $alias_key, 'e', $excludes_key) . '>';
        }

        push @role_keys, $key;
    }

    my $role_key = join('|', sort @role_keys);

    # Makes something like Super::Class|Super::Class::2=Role|Role::1
    return join('=', $superclass_key, $role_key);
}

sub reinitialize {
    my $self = shift;
    my $pkg  = shift;

    my $meta = blessed $pkg ? $pkg : Class::MOP::class_of($pkg);

    my %existing_classes;
    if ($meta) {
        %existing_classes = map { $_ => $meta->$_() } qw(
            attribute_metaclass
            method_metaclass
            wrapped_method_metaclass
            instance_metaclass
            constructor_class
            destructor_class
        );
    }

    return $self->SUPER::reinitialize(
        $pkg,
        %existing_classes,
        @_,
    );
}

sub add_role {
    my ($self, $role) = @_;
    (blessed($role) && $role->isa('Moose::Meta::Role'))
        || throw_exception( AddRoleTakesAMooseMetaRoleInstance => role_to_be_added => $role,
                                                                  class_name       => $self->name,
                          );
    push @{$self->roles} => $role;
}

sub role_applications {
    my ($self) = @_;

    return @{$self->_get_role_applications};
}

sub add_role_application {
    my ($self, $application) = @_;

    (blessed($application) && $application->isa('Moose::Meta::Role::Application::ToClass'))
        || throw_exception( InvalidRoleApplication => class_name  => $self->name,
                                                      application => $application,
                          );

    push @{$self->_get_role_applications} => $application;
}

sub calculate_all_roles {
    my $self = shift;
    my %seen;
    grep { !$seen{$_->name}++ } map { $_->calculate_all_roles } @{ $self->roles };
}

sub _roles_with_inheritance {
    my $self = shift;
    my %seen;
    grep { !$seen{$_->name}++ }
         map { Class::MOP::class_of($_)->can('roles')
                   ? @{ Class::MOP::class_of($_)->roles }
                   : () }
             $self->linearized_isa;
}

sub calculate_all_roles_with_inheritance {
    my $self = shift;
    my %seen;
    grep { !$seen{$_->name}++ }
         map { Class::MOP::class_of($_)->can('calculate_all_roles')
                   ? Class::MOP::class_of($_)->calculate_all_roles
                   : () }
             $self->linearized_isa;
}

sub does_role {
    my ($self, $role_name) = @_;

    (defined $role_name)
        || throw_exception( RoleNameRequired => class_name => $self->name );

    foreach my $class ($self->class_precedence_list) {
        my $meta = Class::MOP::class_of($class);
        # when a Moose metaclass is itself extended with a role,
        # this check needs to be done since some items in the
        # class_precedence_list might in fact be Class::MOP
        # based still.
        next unless $meta && $meta->can('roles');
        foreach my $role (@{$meta->roles}) {
            return 1 if $role->does_role($role_name);
        }
    }
    return 0;
}

sub excludes_role {
    my ($self, $role_name) = @_;

    (defined $role_name)
        || throw_exception( RoleNameRequired => class_name => $self->name );

    foreach my $class ($self->class_precedence_list) {
        my $meta = Class::MOP::class_of($class);
        # when a Moose metaclass is itself extended with a role,
        # this check needs to be done since some items in the
        # class_precedence_list might in fact be Class::MOP
        # based still.
        next unless $meta && $meta->can('roles');
        foreach my $role (@{$meta->roles}) {
            return 1 if $role->excludes_role($role_name);
        }
    }
    return 0;
}

sub new_object {
    my $self   = shift;
    my $params = @_ == 1 ? $_[0] : {@_};
    my $object = $self->SUPER::new_object($params);

    $self->_call_all_triggers($object, $params);

    $object->BUILDALL($params) if $object->can('BUILDALL');

    return $object;
}

sub _call_all_triggers {
    my ($self, $object, $params) = @_;

    foreach my $attr ( $self->get_all_attributes() ) {

        next unless $attr->can('has_trigger') && $attr->has_trigger;

        my $init_arg = $attr->init_arg;
        next unless defined $init_arg;
        next unless exists $params->{$init_arg};

        $attr->trigger->(
            $object,
            (
                  $attr->should_coerce
                ? $attr->get_read_method_ref->($object)
                : $params->{$init_arg}
            ),
        );
    }
}

sub _generate_fallback_constructor {
    my $self = shift;
    my ($class) = @_;
    return $class . '->Moose::Object::new(@_)'
}

sub _inline_params {
    my $self = shift;
    my ($params, $class) = @_;
    return (
        'my ' . $params . ' = ',
        $self->_inline_BUILDARGS($class, '@_'),
        ';',
    );
}

sub _inline_BUILDARGS {
    my $self = shift;
    my ($class, $args) = @_;

    my $buildargs = $self->find_method_by_name("BUILDARGS");

    if ($args eq '@_'
     && (!$buildargs or $buildargs->body == \&Moose::Object::BUILDARGS)) {
        return (
            'do {',
                'my $params;',
                'if (scalar @_ == 1) {',
                    'if (!defined($_[0]) || ref($_[0]) ne \'HASH\') {',
                        $self->_inline_throw_exception(
                            'SingleParamsToNewMustBeHashRef'
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

sub _inline_slot_initializer {
    my $self  = shift;
    my ($attr, $idx) = @_;

    return (
        '## ' . $attr->name,
        $self->_inline_check_required_attr($attr),
        $self->SUPER::_inline_slot_initializer(@_),
    );
}

sub _inline_check_required_attr {
    my $self = shift;
    my ($attr) = @_;

    return unless defined $attr->init_arg;
    return unless $attr->can('is_required') && $attr->is_required;
    return if $attr->has_default || $attr->has_builder;

    my $throw = $self->_inline_throw_exception(
        'AttributeIsRequired',
        sprintf(
            <<'EOF', quotemeta( $attr->name ), quotemeta( $attr->init_arg ) ), );
params             => $params,
class_name         => $class_name,
attribute_name     => "%s",
attribute_init_arg => "%s",
EOF

    return sprintf( <<'EOF', quotemeta( $attr->init_arg ), $throw )
if ( !exists $params->{"%s"} ) {
    %s;
}
EOF
}

# XXX: these two are duplicated from cmop, because we have to pass the tc stuff
# through to _inline_set_value - this should probably be fixed, but i'm not
# quite sure how. -doy
sub _inline_init_attr_from_constructor {
    my $self = shift;
    my ($attr, $idx) = @_;

    my @initial_value = $attr->_inline_set_value(
        '$instance',
        '$params->{\'' . $attr->init_arg . '\'}',
        '$type_constraint_bodies[' . $idx . ']',
        '$type_coercions[' . $idx . ']',
        '$type_constraint_messages[' . $idx . ']',
        'for constructor',
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

    return if $attr->can('is_lazy') && $attr->is_lazy;
    my $default = $self->_inline_default_value($attr, $idx);
    return unless $default;

    my @initial_value = (
        'my $default = ' . $default . ';',
        $attr->_inline_set_value(
            '$instance',
            '$default',
            '$type_constraint_bodies[' . $idx . ']',
            '$type_coercions[' . $idx . ']',
            '$type_constraint_messages[' . $idx . ']',
            'for constructor',
        ),
    );

    push @initial_value, (
        '$attrs->[' . $idx . ']->set_initial_value(',
            '$instance,',
            $attr->_inline_instance_get('$instance'),
        ');',
    ) if $attr->has_initializer;

    return @initial_value;
}

sub _inline_extra_init {
    my $self = shift;
    return (
        $self->_inline_triggers,
        $self->_inline_BUILDALL,
    );
}

sub _inline_triggers {
    my $self = shift;
    my @trigger_calls;

    my @attrs = sort { $a->name cmp $b->name } $self->get_all_attributes;
    for my $i (0 .. $#attrs) {
        my $attr = $attrs[$i];

        next unless $attr->can('has_trigger') && $attr->has_trigger;

        my $init_arg = $attr->init_arg;
        next unless defined $init_arg;

        push @trigger_calls,
            'if (exists $params->{\'' . $init_arg . '\'}) {',
                '$triggers->[' . $i . ']->(',
                    '$instance,',
                    $attr->_inline_instance_get('$instance') . ',',
                ');',
            '}';
    }

    return @trigger_calls;
}

sub _inline_BUILDALL {
    my $self = shift;

    my @methods = reverse $self->find_all_methods_by_name('BUILD');
    return () unless @methods;

    my @BUILD_calls;

    foreach my $method (@methods) {
        push @BUILD_calls,
            '$instance->' . $method->{class} . '::BUILD($params);';
    }

    return (
        'if (!$params->{__no_BUILD__}) {',
        @BUILD_calls,
        '}',
    );
}

sub _eval_environment {
    my $self = shift;

    my @attrs = sort { $a->name cmp $b->name } $self->get_all_attributes;

    my $triggers = [
        map { $_->can('has_trigger') && $_->has_trigger ? $_->trigger : undef }
            @attrs
    ];

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
    } @attrs;

    my @type_constraint_bodies = map {
        defined $_ ? $_->_compiled_type_constraint : undef;
    } @type_constraints;

    my @type_coercions = map {
        defined $_ && $_->has_coercion
            ? $_->coercion->_compiled_type_coercion
            : undef
    } @type_constraints;

    my @type_constraint_messages = map {
        defined $_
            ? ($_->has_message ? $_->message : $_->_default_message)
            : undef
    } @type_constraints;

    return {
        %{ $self->SUPER::_eval_environment },
        ((any { defined && $_->has_initializer } @attrs)
            ? ('$attrs' => \[@attrs])
            : ()),
        '$triggers' => \$triggers,
        '@type_coercions' => \@type_coercions,
        '@type_constraint_bodies' => \@type_constraint_bodies,
        '@type_constraint_messages' => \@type_constraint_messages,
        ( map { defined($_) ? %{ $_->inline_environment } : () }
              @type_constraints ),
        # pretty sure this is only going to be closed over if you use a custom
        # error class at this point, but we should still get rid of this
        # at some point
        '$meta'  => \$self,
        '$class_name' => \($self->name),
    };
}

sub superclasses {
    my $self = shift;
    my $supers = Data::OptList::mkopt(\@_);
    foreach my $super (@{ $supers }) {
        my ($name, $opts) = @{ $super };
        Moose::Util::_load_user_class($name, $opts);
        my $meta = Class::MOP::class_of($name);
        throw_exception( CanExtendOnlyClasses => role_name => $meta->name )
            if $meta && $meta->isa('Moose::Meta::Role')
    }
    return $self->SUPER::superclasses(map { $_->[0] } @{ $supers });
}

### ---------------------------------------------

sub add_attribute {
    my $self = shift;
    my $attr =
        (blessed $_[0] && $_[0]->isa('Class::MOP::Attribute')
            ? $_[0]
            : $self->_process_attribute(@_));
    $self->SUPER::add_attribute($attr);
    # it may be a Class::MOP::Attribute, theoretically, which doesn't have
    # 'bare' and doesn't implement this method
    if ($attr->can('_check_associated_methods')) {
        $attr->_check_associated_methods;
    }
    return $attr;
}

sub add_override_method_modifier {
    my ($self, $name, $method, $_super_package) = @_;

    my $existing_method = $self->get_method($name);
    (!$existing_method)
        || throw_exception( CannotOverrideLocalMethodIsPresent => class_name => $self->name,
                                                                  method     => $existing_method,
                          );
    $self->add_method($name => Moose::Meta::Method::Overridden->new(
        method  => $method,
        class   => $self,
        package => $_super_package, # need this for roles
        name    => $name,
    ));
}

sub add_augment_method_modifier {
    my ($self, $name, $method) = @_;
    my $existing_method = $self->get_method($name);
    throw_exception( CannotAugmentIfLocalMethodPresent => class_name => $self->name,
                                                          method     => $existing_method,
                   )
        if( $existing_method );

    $self->add_method($name => Moose::Meta::Method::Augmented->new(
        method  => $method,
        class   => $self,
        name    => $name,
    ));
}

## Private Utility methods ...

sub _find_next_method_by_name_which_is_not_overridden {
    my ($self, $name) = @_;
    foreach my $method ($self->find_all_methods_by_name($name)) {
        return $method->{code}
            if blessed($method->{code}) && !$method->{code}->isa('Moose::Meta::Method::Overridden');
    }
    return undef;
}

## Metaclass compatibility

sub _base_metaclasses {
    my $self = shift;
    my %metaclasses = $self->SUPER::_base_metaclasses;
    for my $class (keys %metaclasses) {
        $metaclasses{$class} =~ s/^Class::MOP/Moose::Meta/;
    }
    return (
        %metaclasses,
    );
}

sub _fix_class_metaclass_incompatibility {
    my $self = shift;
    my ($super_meta) = @_;

    $self->SUPER::_fix_class_metaclass_incompatibility(@_);

    if ($self->_class_metaclass_can_be_made_compatible($super_meta)) {
        ($self->is_pristine)
            || throw_exception( CannotFixMetaclassCompatibility => class      => $self,
                                                                   superclass => $super_meta
                              );
        my $super_meta_name = $super_meta->_real_ref_name;
        my $class_meta_subclass_meta_name = Moose::Util::_reconcile_roles_for_metaclass(blessed($self), $super_meta_name);
        my $new_self = $class_meta_subclass_meta_name->reinitialize(
            $self->name,
        );

        $self->_replace_self( $new_self, $class_meta_subclass_meta_name );
    }
}

sub _fix_single_metaclass_incompatibility {
    my $self = shift;
    my ($metaclass_type, $super_meta) = @_;

    $self->SUPER::_fix_single_metaclass_incompatibility(@_);

    if ($self->_single_metaclass_can_be_made_compatible($super_meta, $metaclass_type)) {
        ($self->is_pristine)
            || throw_exception( CannotFixMetaclassCompatibility => class          => $self,
                                                                   superclass     => $super_meta,
                                                                   metaclass_type => $metaclass_type
                              );
        my $super_meta_name = $super_meta->_real_ref_name;
        my $class_specific_meta_subclass_meta_name = Moose::Util::_reconcile_roles_for_metaclass($self->$metaclass_type, $super_meta->$metaclass_type);
        my $new_self = $super_meta->reinitialize(
            $self->name,
            $metaclass_type => $class_specific_meta_subclass_meta_name,
        );

        $self->_replace_self( $new_self, $super_meta_name );
    }
}

sub _replace_self {
    my $self      = shift;
    my ( $new_self, $new_class)   = @_;

    %$self = %$new_self;
    bless $self, $new_class;

    # We need to replace the cached metaclass instance or else when it goes
    # out of scope Class::MOP::Class destroy's the namespace for the
    # metaclass's class, causing much havoc.
    my $weaken = Class::MOP::metaclass_is_weak( $self->name );
    Class::MOP::store_metaclass_by_name( $self->name, $self );
    Class::MOP::weaken_metaclass( $self->name ) if $weaken;
}

sub _process_attribute {
    my ( $self, $name, @args ) = @_;

    @args = %{$args[0]} if scalar @args == 1 && ref($args[0]) eq 'HASH';

    if (($name || '') =~ /^\+(.*)/) {
        return $self->_process_inherited_attribute($1, @args);
    }
    else {
        return $self->_process_new_attribute($name, @args);
    }
}

sub _process_new_attribute {
    my ( $self, $name, @args ) = @_;

    $self->attribute_metaclass->interpolate_class_and_new($name, @args);
}

sub _process_inherited_attribute {
    my ($self, $attr_name, %options) = @_;

    my $inherited_attr = $self->find_attribute_by_name($attr_name);
    (defined $inherited_attr)
        || throw_exception( NoAttributeFoundInSuperClass => class_name     => $self->name,
                                                            attribute_name => $attr_name,
                                                            params         => \%options
                          );
    if ($inherited_attr->isa('Moose::Meta::Attribute')) {
        return $inherited_attr->clone_and_inherit_options(%options);
    }
    else {
        # NOTE:
        # kind of a kludge to handle Class::MOP::Attributes
        return $inherited_attr->Moose::Meta::Attribute::clone_and_inherit_options(%options);
    }
}

# reinitialization support

sub _restore_metaobjects_from {
    my $self = shift;
    my ($old_meta) = @_;

    $self->SUPER::_restore_metaobjects_from($old_meta);

    for my $role ( @{ $old_meta->roles } ) {
        $self->add_role($role);
    }

    for my $application ( @{ $old_meta->_get_role_applications } ) {
        $application->class($self);
        $self->add_role_application ($application);
    }
}

## Immutability

sub _immutable_options {
    my ( $self, @args ) = @_;

    $self->SUPER::_immutable_options(
        inline_destructor => 1,

        # Moose always does this when an attribute is created
        inline_accessors => 0,

        @args,
    );
}

sub _fixup_attributes_after_rebless {
    my $self = shift;
    my ($instance, $rebless_from, %params) = @_;

    $self->SUPER::_fixup_attributes_after_rebless(
        $instance,
        $rebless_from,
        %params
    );

    $self->_call_all_triggers( $instance, \%params );
}

## -------------------------------------------------

our $error_level;

sub _inline_throw_exception {
    my ( $self, $exception_type, $throw_args ) = @_;
    return 'die Module::Runtime::use_module("Moose::Exception::' . $exception_type . '")->new(' . ($throw_args || '') . ')';
}

1;

# ABSTRACT: The Moose metaclass

__END__

=pod

=head1 SYNOPSIS

  # assuming that class Foo has been defined, you can ...

  # get all the methods in a class ...
  for my $method ( Foo->meta->get_all_methods ) { ... }

  # get a list of all the classes searched the method dispatcher in the
  # correct order
  Foo->meta->class_precedence_list()

  # add a method to Foo ...
  Foo->meta->add_method( 'bar' => sub {...} )

  # remove a method from Foo ...
  Foo->meta->remove_method('bar');

  # or use this to actually create classes ...
  Moose::Meta::Class->create(
      'Bar' => (
          version      => '0.01',
          superclasses => ['Foo'],
          attributes   => [
              Moose::Meta::Attribute->new(...),
              Moose::Meta::Attribute->new(...),
          ],
          methods => {
              calculate_bar => sub {...},
              construct_baz => sub {...}
          }
      )
  );

=head1 DESCRIPTION

The Class Protocol is the largest and most complex part of the
Class::MOP meta-object protocol. It controls the introspection and
manipulation of Perl 5 classes, and it can create them as well. The
best way to understand what this module can do is to read the
documentation for each of its methods.

=head1 INHERITANCE

C<Moose::Meta::Class> is a subclass of L<Class::MOP::Class>. All of the
methods provided by both classes are documented here.

However, C<Class::MOP::Class> is itself a subclass of L<Class::MOP::Module>,
which is in turn a subclass of L<Class::MOP::Package>. You may want to look at
those two classes for additional API documentation.

=head1 METHODS

This class provides the following methods.

=head2 Class construction

These methods all create new C<Moose::Meta::Class> objects. These
objects can represent existing classes or they can be used to create
new classes from scratch.

The metaclass object for a given class is a singleton. If you attempt
to create a metaclass for the same class twice, you will just get the
existing object.

=head3 Moose::Meta::Class->create($package_name, %options)

This method creates a new C<Moose::Meta::Class> object with the given
package name. It accepts a number of options:

=over 4

=item * version

An optional version number for the newly created package.

=item * authority

An optional authority for the newly created package.
See L<Class::MOP::Module/authority> for more details.

=item * superclasses

An optional array reference of superclass names.

Each entry in both the C<superclasses> array ref can be followed by a hash
reference with arguments. The only valid key for superclasses is
C<-version>. This ensures the loaded superclass satisfies the required
version.

=item * roles

This should be an array reference containing roles that the class does, each
optionally followed by a hashref of options.

  my $metaclass = Moose::Meta::Class->create( 'New::Class', roles => [...] );

Just as with C<superclasses>, the C<role> option takes the C<-version> as an
argument, but the optional hash reference can also contain any other role
relevant values like exclusions or parameterized role arguments.

=item * methods

An optional hash reference of methods for the class. The keys of the
hash reference are method names and values are subroutine references.

=item * attributes

An optional array reference of L<Class::MOP::Attribute> objects.

=item * meta_name

Specifies the name to install the C<meta> method for this class under.  If it
is not passed, then the method will be named C<meta>. If C<undef> is given
then no meta method will be installed.

=item * weaken

If true, the metaclass that is stored in the global cache will be a
weak reference.

Classes created in this way are destroyed once the metaclass they are
attached to goes out of scope, and will be removed from Perl's internal
symbol table.

All instances of a class with a weakened metaclass keep a special
reference to the metaclass object, which prevents the metaclass from
going out of scope while any instances exist.

This only works if the instance is based on a hash reference, however.

=back

=head3 Moose::Meta::Class->create_anon_class(%options)

This method works just like C<< Moose::Meta::Class->create >> but it
creates an "anonymous" class. In fact, the class does have a name, but
that name is a unique name generated internally by this module.

It accepts the same C<superclasses>, C<methods>, and C<attributes>
parameters that C<create> accepts.

It also accepts a C<cache> option. If this is C<true>, then the anonymous class
will be cached based on its superclasses and roles. If an existing anonymous
class in the cache has the same superclasses and roles, it will be reused.

Anonymous classes default to C<< weaken => 1 >> if cache is C<false>, although
this can be overridden.

=head3 Moose::Meta::Class->initialize($package_name, %options)

This method will initialize a C<Moose::Meta::Class> object for the
named package. Unlike C<create>, this method I<will not> create a new
class.

The purpose of this method is to retrieve a C<Moose::Meta::Class>
object for introspecting an existing class.

If an existing C<Moose::Meta::Class> object exists for the named
package, it will be returned, and any options provided will be
ignored!

If the object does not yet exist, it will be created.

The valid options that can be passed to this method are
C<attribute_metaclass>, C<method_metaclass>, C<wrapped_method_metaclass>, and
C<instance_metaclass>. These are all optional, and default to the appropriate
Moose metaclass.

=head2 Object instance construction and cloning

These methods are all related to creating and/or cloning object
instances.

=head3 $metaclass->new_object(%params)

This method is used to create a new object of the metaclass's class. Any
parameters you provide are used to initialize the instance's attributes. A
special C<__INSTANCE__> key can be passed to provide an already generated
instance, rather than having the metaclass generate it for you. This is mostly
useful for using Moose with foreign classes which generate instances using
their own constructors.

=head3 $metaclass->clone_object($instance, %params)

This method clones an existing object instance. Any parameters you
provide are will override existing attribute values in the object.

This is a convenience method for cloning an object instance, then
blessing it into the appropriate package.

You could implement a clone method in your class, using this method:

  sub clone {
      my ( $self, %params ) = @_;
      $self->meta->clone_object( $self, %params );
  }

=head3 $metaclass->rebless_instance($instance, %params)

This method changes the class of C<$instance> to the metaclass's class.

You can only rebless an instance into a subclass of its current
class. If you pass any additional parameters, these will be treated
like constructor parameters and used to initialize the object's
attributes. Any existing attributes that are already set will be
overwritten.

Before reblessing the instance, this method will call
C<rebless_instance_away> on the instance's current metaclass. This method
will be passed the instance, the new metaclass, and any parameters
specified to C<rebless_instance>. By default, C<rebless_instance_away>
does nothing; it is merely a hook.

=head3 $metaclass->rebless_instance_back($instance)

Does the same thing as C<rebless_instance>, except that you can only
rebless an instance into one of its superclasses. Any attributes that
do not exist in the superclass will be deinitialized.

This is a much more dangerous operation than C<rebless_instance>,
especially when multiple inheritance is involved, so use this carefully!

=head3 $metaclass->instance_metaclass

Returns the class name of the instance metaclass. See
L<Class::MOP::Instance> for more information on the instance
metaclass.

=head3 $metaclass->get_meta_instance

Returns an instance of the C<instance_metaclass> to be used in the
construction of a new instance of the class.

=head2 Informational predicates

These methods allow you to ask for information about the class itself.

=head3 $metaclass->is_anon_class

This returns true if the class was created by calling C<<
Class::MOP::Class->create_anon_class >>.

=head3 $metaclass->is_mutable

This returns true if the class is still mutable.

=head3 $metaclass->is_immutable

This returns true if the class has been made immutable.

=head3 $metaclass->is_pristine

A class is I<not> pristine if it has non-inherited attributes or if it
has any generated methods.

=head2 Inheritance Introspection and Manipulation

These methods are related to inheritance between classes.

=head3 $metaclass->superclasses(?@superclasses)

This is the accessor allowing you to read or change the parents of
the class.

This is basically sugar around getting and setting C<@ISA>.

When called without any arguments, this method simply returns a list of class
I<names> for the parent class(es) of the class this is called on. The classes
are returned in method dispatch order.

You can also set a class's superclasses with this method. The arguments should
be a list of class I<names>, each of which can be followed by an optional hash
reference containing a L<-version|Class::MOP/Class Loading Options> value. If
the version requirement is not satisfied an error will be thrown.

When you pass classes to this method, we will attempt to load them if they are
not already loaded.

After setting the new superclasses, this method always returns the current
superclass names.

=head3 $metaclass->class_precedence_list

This returns a list of all of the class's ancestor classes as a list of class
names. The classes are returned in method dispatch order.

=head3 $metaclass->linearized_isa

This returns a list based on C<class_precedence_list> but with all
duplicates removed.

=head3 $metaclass->subclasses

This returns a list of all descendants for this class, even grandchildren and
other indirect descendants.

=head3 $metaclass->direct_subclasses

This returns a list of immediate subclasses for this class. This is only the
immediate children of the class.

=head2 Role introspection and creation

These methods allow you to introspect a class's role, as well as add or remove
them.

=head3 $metaclass->calculate_all_roles

This will return a unique array of L<Moose::Meta::Role> instances
which are attached to this class.

=head3 $metaclass->calculate_all_roles_with_inheritance

This will return a unique array of L<Moose::Meta::Role> instances
which are attached to this class, and each of this class's ancestors.

=head3 $metaclass->add_role($role)

This takes a L<Moose::Meta::Role> object, and adds it to the class's
list of roles. This I<does not> actually apply the role to the class.

=head3 $metaclass->role_applications

Returns a list of L<Moose::Meta::Role::Application::ToClass>
objects, which contain the arguments to role application.

=head3 $metaclass->add_role_application($application)

This takes a L<Moose::Meta::Role::Application::ToClass> object, and
adds it to the class's list of role applications. This I<does not>
actually apply any role to the class; it is only for tracking role
applications.

=head3 $metaclass->does_role($role)

This returns a boolean indicating whether or not the class does the specified
role. The role provided can be either a role name or a L<Moose::Meta::Role>
object. This tests both the class and its parents.

=head3 $metaclass->excludes_role($role_name)

A class excludes a role if it has already composed a role which
excludes the named role. This tests both the class and its parents.

=head2 Attribute introspection and creation

Because Perl 5 does not have a core concept of attributes in classes,
we can only return information about attributes which have been added
via this class's methods. We cannot discover information about
attributes which are defined in terms of "regular" Perl 5 methods.

=head3 $metaclass->get_attribute($attribute_name)

This will return a L<Class::MOP::Attribute> for the specified
C<$attribute_name>. If the class does not have the specified
attribute, it returns C<undef>.

NOTE that get_attribute does not search superclasses, for that you
need to use C<find_attribute_by_name>.

=head3 $metaclass->has_attribute($attribute_name)

Returns a boolean indicating whether or not the class defines the
named attribute. It does not include attributes inherited from parent
classes.

=head3 $metaclass->get_attribute_list

This will return a list of attributes I<names> for all attributes
defined in this class.  Note that this operates on the current class
only, it does not traverse the inheritance hierarchy.

=head3 $metaclass->get_all_attributes

This will traverse the inheritance hierarchy and return a list of all
the L<Class::MOP::Attribute> objects for this class and its parents.

=head3 $metaclass->find_attribute_by_name($attribute_name)

This will return a L<Class::MOP::Attribute> for the specified
C<$attribute_name>. If the class does not have the specified
attribute, it returns C<undef>.

Unlike C<get_attribute>, this attribute I<will> look for the named
attribute in superclasses.

=head3 $metaclass->add_attribute(...)

This method accepts either an existing L<Class::MOP::Attribute>
object or parameters suitable for passing to that class's C<new>
method.

The attribute provided will be added to the class.

Any accessor methods defined by the attribute will be added to the
class when the attribute is added.

If an attribute of the same name already exists, the old attribute
will be removed first.

=head3 $metaclass->remove_attribute($attribute_name)

This will remove the named attribute from the class, and
L<Class::MOP::Attribute> object.

Removing an attribute also removes any accessor methods defined by the
attribute.

However, note that removing an attribute will only affect I<future>
object instances created for this class, not existing instances.

=head3 $metaclass->attribute_metaclass

Returns the class name of the attribute metaclass for this class. By
default, this is L<Class::MOP::Attribute>.

=head2 Method introspection and creation

These methods allow you to introspect a class's methods, as well as
add, remove, or change methods.

Determining what is truly a method in a Perl 5 class requires some
heuristics (aka guessing).

Methods defined outside the package with a fully qualified name (C<sub
Package::name { ... }>) will be included. Similarly, methods named
with a fully qualified name using L<Sub::Name> are also included.

However, we attempt to ignore imported functions.

Ultimately, we are using heuristics to determine what truly is a
method in a class, and these heuristics may get the wrong answer in
some edge cases. However, for most "normal" cases the heuristics work
correctly.

=head3 $metaclass->get_method($method_name)

This will return a L<Moose::Meta::Method> for the specified
C<$method_name>. If the class does not have the specified method, it returns
C<undef>

=head3 $metaclass->has_method($method_name)

Returns a boolean indicating whether or not the class defines the
named method. It does not include methods inherited from parent
classes.

=head3 $metaclass->get_method_list

This will return a list of method I<names> for all methods defined in
this class.

=head3 $metaclass->add_method($method_name, $method)

This method takes a method name and a subroutine reference, and adds
the method to the class.

The subroutine reference can be a L<Moose::Meta::Method>, and you are strongly
encouraged to pass a meta method object instead of a code reference. If you do
so, that object gets stored as part of the class's method map directly. If
not, the meta information will have to be recreated later, and may be
incorrect.

If you provide a method object, this method will clone that object if the
object's package name does not match the class name. This lets us track the
original source of any methods added from other classes (notably Moose roles).

=head3 $metaclass->remove_method($method_name)

Remove the named method from the class. This method returns the
L<Moose::Meta::Method> object for the method.

=head3 $metaclass->method_metaclass

Returns the class name of the method metaclass, see
L<Moose::Meta::Method> for more information on the method metaclass.

=head3 $metaclass->wrapped_method_metaclass

Returns the class name of the wrapped method metaclass, see
L<Moose::Meta::Method::Wrapped> for more information on the wrapped
method metaclass.

=head3 $metaclass->get_all_methods

This will traverse the inheritance hierarchy and return a list of all
the L<Moose::Meta::Method> objects for this class and its parents.

=head3 $metaclass->find_method_by_name($method_name)

This will return a L<Moose::Meta::Method> for the specified
C<$method_name>. If the class does not have the specified method, it
returns C<undef>

Unlike C<get_method>, this method I<will> look for the named method in
superclasses.

=head3 $metaclass->get_all_method_names

This will return a list of method I<names> for all of this class's
methods, including inherited methods.

=head3 $metaclass->find_all_methods_by_name($method_name)

This method looks for the named method in the class and all of its
parents. It returns every matching method it finds in the inheritance
tree, so it returns a list of methods.

Each method is returned as a hash reference with three keys. The keys
are C<name>, C<class>, and C<code>. The C<code> key has a
L<Moose::Meta::Method> object as its value.

The list of methods is distinct.

=head3 $metaclass->find_next_method_by_name($method_name)

This method returns the first method in any superclass matching the
given name. It is effectively the method that C<SUPER::$method_name>
would dispatch to.

=head2 Overload introspection and creation

These methods provide an API to the core L<overload> functionality.

=head3 $metaclass->is_overloaded

Returns true if overloading is enabled for this class. Corresponds to
L<overload::Overloaded|overload/Public Functions>.

=head3 $metaclass->get_overloaded_operator($op)

Returns the L<Class::MOP::Overload> object corresponding to the operator named
C<$op>, if one exists for this class.

=head3 $metaclass->has_overloaded_operator($op)

Returns whether or not the operator C<$op> is overloaded for this class.

=head3 $metaclass->get_overload_list

Returns a list of operator names which have been overloaded (see
L<overload/Overloadable Operations> for the list of valid operator names).

=head3 $metaclass->get_all_overloaded_operators

Returns a list of L<Class::MOP::Overload> objects corresponding to the
operators that have been overloaded.

=head3 $metaclass->add_overloaded_operator($op, $impl)

Overloads the operator C<$op> for this class, with the implementation C<$impl>.
C<$impl> can be either a coderef or a method name. Corresponds to
C<< use overload $op => $impl; >>

=head3 $metaclass->remove_overloaded_operator($op)

Remove overloading for operator C<$op>. Corresponds to C<< no overload $op; >>

=head3 $metaclass->get_overload_fallback_value

Returns the overload C<fallback> setting for the package.

=head3 $metaclass->set_overload_fallback_value($fallback)

Sets the overload C<fallback> setting for the package.

=head2 Method Modifiers

Method modifiers are hooks which allow a method to be wrapped with
I<before>, I<after> and I<around> method modifiers. Every time a
method is called, its modifiers are also called.

A class can modify its own methods, as well as methods defined in
parent classes.

=head3 How method modifiers work?

Method modifiers work by wrapping the original method and then
replacing it in the class's symbol table. The wrappers will handle
calling all the modifiers in the appropriate order and preserving the
calling context for the original method.

The return values of C<before> and C<after> modifiers are
ignored. This is because their purpose is B<not> to filter the input
and output of the primary method (this is done with an I<around>
modifier).

This may seem like an odd restriction to some, but doing this allows
for simple code to be added at the beginning or end of a method call
without altering the function of the wrapped method or placing any
extra responsibility on the code of the modifier.

Of course if you have more complex needs, you can use the C<around>
modifier which allows you to change both the parameters passed to the
wrapped method, as well as its return value.

Before and around modifiers are called in last-defined-first-called
order, while after modifiers are called in first-defined-first-called
order. So the call tree might looks something like this:

  before 2
   before 1
    around 2
     around 1
      primary
     around 1
    around 2
   after 1
  after 2

=head3 What is the performance impact?

Of course there is a performance cost associated with method
modifiers, but we have made every effort to make that cost directly
proportional to the number of modifier features you use.

The wrapping method does its best to B<only> do as much work as it
absolutely needs to. In order to do this we have moved some of the
performance costs to set-up time, where they are easier to amortize.

All this said, our benchmarks have indicated the following:

  simple wrapper with no modifiers             100% slower
  simple wrapper with simple before modifier   400% slower
  simple wrapper with simple after modifier    450% slower
  simple wrapper with simple around modifier   500-550% slower
  simple wrapper with all 3 modifiers          1100% slower

These numbers may seem daunting, but you must remember, every feature
comes with some cost. To put things in perspective, just doing a
simple C<AUTOLOAD> which does nothing but extract the name of the
method called and return it costs about 400% over a normal method
call.

=head3 $metaclass->add_before_method_modifier($method_name, $code)

This wraps the specified method with the supplied subroutine
reference. The modifier will be called as a method itself, and will
receive the same arguments as are passed to the method.

When the modifier exits, the wrapped method will be called.

The return value of the modifier will be ignored.

=head3 $metaclass->add_after_method_modifier($method_name, $code)

This wraps the specified method with the supplied subroutine
reference. The modifier will be called as a method itself, and will
receive the same arguments as are passed to the method.

When the wrapped methods exits, the modifier will be called.

The return value of the modifier will be ignored.

=head3 $metaclass->add_around_method_modifier($method_name, $code)

This wraps the specified method with the supplied subroutine
reference.

The first argument passed to the modifier will be a subroutine
reference to the wrapped method. The second argument is the object,
and after that come any arguments passed when the method is called.

The around modifier can choose to call the original method, as well as
what arguments to pass if it does so.

The return value of the modifier is what will be seen by the caller.

=head3 $metaclass->add_override_method_modifier($name, $sub)

This adds an C<override> method modifier to the package.

=head3 $metaclass->add_augment_method_modifier($name, $sub)

This adds an C<augment> method modifier to the package.

=head2 Class Immutability

Making a class immutable "freezes" the class definition. You can no
longer call methods which alter the class, such as adding or removing
methods or attributes.

Making a class immutable lets us optimize the class by inlining some
methods, and also allows us to optimize some methods on the metaclass
object itself.

After immutabilization, the metaclass object will cache most informational
methods that returns information about methods or attributes. Methods which
would alter the class, such as C<add_attribute> and C<add_method>, will
throw an error on an immutable metaclass object.

=head3 $metaclass->make_immutable(%options)

This method will create an immutable transformer and use it to make
the class and its metaclass object immutable, and returns true
(you should not rely on the details of this value apart from its truth).

This method accepts the following options:

=over 4

=item * inline_accessors

=item * inline_constructor

=item * inline_destructor

These are all booleans indicating whether the specified method(s)
should be inlined.

By default, accessors and the constructor are inlined, but not the
destructor.

=item * immutable_trait

The name of a class which will be used as a parent class for the
metaclass object being made immutable. This "trait" implements the
post-immutability functionality of the metaclass (but not the
transformation itself).

This defaults to L<Moose::Meta::Class::Immutable::Trait>.

=item * constructor_name

This is the constructor method name. This defaults to "new".

=item * constructor_class

The name of the method metaclass for constructors. It will be used to
generate the inlined constructor. This defaults to
"Moose::Meta::Method::Constructor".

=item * replace_constructor

This is a boolean indicating whether an existing constructor should be
replaced when inlining a constructor. This defaults to false.

=item * destructor_class

The name of the method metaclass for destructors. It will be used to
generate the inlined destructor. This defaults to
"Moose::Meta::Method::Destructor".

=item * replace_destructor

This is a boolean indicating whether an existing destructor should be
replaced when inlining a destructor. This defaults to false.

=back

=head3 $metaclass->immutable_options

Returns a hash of the options used when making the class immutable, including
both defaults and anything supplied by the user in the call to C<<
$metaclass->make_immutable >>. This is useful if you need to temporarily make
a class mutable and then restore immutability as it was before.

=head3 $metaclass->make_mutable

Calling this method reverses the immutabilization transformation.

=head3 $metaclass->constructor_class($class_name), $metaclass->destructor_class($class_name)

These are the names of classes used when making a class immutable. These
default to L<Moose::Meta::Method::Constructor> and
L<Moose::Meta::Method::Destructor> respectively. These accessors are
read-write, so you can use them to change the class names associated with an
existing metaclass.

=head2 Moose::Meta::Class->meta

This will return a L<Class::MOP::Class> instance for this class.

It should also be noted that L<Class::MOP> will actually bootstrap
this module by installing a number of attribute meta-objects into its
metaclass.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
