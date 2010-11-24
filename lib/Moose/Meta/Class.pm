
package Moose::Meta::Class;

use strict;
use warnings;

use Class::MOP;

use Carp qw( confess );
use Data::OptList;
use List::Util qw( first );
use List::MoreUtils qw( any all uniq first_index );
use Scalar::Util 'weaken', 'blessed';

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Method::Overridden;
use Moose::Meta::Method::Augmented;
use Moose::Error::Default;
use Moose::Meta::Class::Immutable::Trait;
use Moose::Meta::Method::Constructor;
use Moose::Meta::Method::Destructor;
use Moose::Meta::Method::Meta;
use Moose::Util;
use Class::MOP::MiniTrait;

use base 'Class::MOP::Class';

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

__PACKAGE__->meta->add_attribute('roles' => (
    reader  => 'roles',
    default => sub { [] }
));

__PACKAGE__->meta->add_attribute('role_applications' => (
    reader  => '_get_role_applications',
    default => sub { [] }
));

__PACKAGE__->meta->add_attribute(
    Class::MOP::Attribute->new('immutable_trait' => (
        accessor => "immutable_trait",
        default  => 'Moose::Meta::Class::Immutable::Trait',
    ))
);

__PACKAGE__->meta->add_attribute('constructor_class' => (
    accessor => 'constructor_class',
    default  => 'Moose::Meta::Method::Constructor',
));

__PACKAGE__->meta->add_attribute('destructor_class' => (
    accessor => 'destructor_class',
    default  => 'Moose::Meta::Method::Destructor',
));

__PACKAGE__->meta->add_attribute('error_class' => (
    accessor => 'error_class',
    default  => 'Moose::Error::Default',
));

sub initialize {
    my $class = shift;
    my $pkg   = shift;
    return Class::MOP::get_metaclass_by_name($pkg)
        || $class->SUPER::initialize($pkg,
                'attribute_metaclass' => 'Moose::Meta::Attribute',
                'method_metaclass'    => 'Moose::Meta::Method',
                'instance_metaclass'  => 'Moose::Meta::Instance',
                @_
            );
}

sub create {
    my ($class, $package_name, %options) = @_;

    (ref $options{roles} eq 'ARRAY')
        || $class->throw_error("You must pass an ARRAY ref of roles", data => $options{roles})
            if exists $options{roles};
    my $roles = delete $options{roles};

    my $new_meta = $class->SUPER::create($package_name, %options);

    if ($roles) {
        Moose::Util::apply_all_roles( $new_meta, @$roles );
    }

    return $new_meta;
}

my %ANON_CLASSES;

sub create_anon_class {
    my ($self, %options) = @_;

    my $cache_ok = delete $options{cache};

    my $cache_key
        = _anon_cache_key( $options{superclasses}, $options{roles} );

    if ($cache_ok && defined $ANON_CLASSES{$cache_key}) {
        return $ANON_CLASSES{$cache_key};
    }

    $options{weaken} = !$cache_ok
        unless exists $options{weaken};

    my $new_class = $self->SUPER::create_anon_class(%options);

    if ($cache_ok) {
        $ANON_CLASSES{$cache_key} = $new_class;
        weaken($ANON_CLASSES{$cache_key});
    }

    return $new_class;
}

sub _meta_method_class { 'Moose::Meta::Method::Meta' }

sub _anon_cache_key {
    # Makes something like Super::Class|Super::Class::2=Role|Role::1
    return join '=' => (
        join( '|', @{ $_[0]      || [] } ),
        join( '|', sort @{ $_[1] || [] } ),
    );
}

sub reinitialize {
    my $self = shift;
    my $pkg  = shift;

    my $meta = blessed $pkg ? $pkg : Class::MOP::class_of($pkg);

    my $cache_key;

    my %existing_classes;
    if ($meta) {
        %existing_classes = map { $_ => $meta->$_() } qw(
            attribute_metaclass
            method_metaclass
            wrapped_method_metaclass
            instance_metaclass
            constructor_class
            destructor_class
            error_class
        );

        $cache_key = _anon_cache_key(
            [ $meta->superclasses ],
            [ map { $_->name } @{ $meta->roles } ],
        ) if $meta->is_anon_class;
    }

    my $new_meta = $self->SUPER::reinitialize(
        $pkg,
        %existing_classes,
        @_,
    );

    return $new_meta unless defined $cache_key;

    my $new_cache_key = _anon_cache_key(
        [ $meta->superclasses ],
        [ map { $_->name } @{ $meta->roles } ],
    );

    delete $ANON_CLASSES{$cache_key};
    $ANON_CLASSES{$new_cache_key} = $new_meta;
    weaken($ANON_CLASSES{$new_cache_key});

    return $new_meta;
}

sub add_role {
    my ($self, $role) = @_;
    (blessed($role) && $role->isa('Moose::Meta::Role'))
        || $self->throw_error("Roles must be instances of Moose::Meta::Role", data => $role);
    push @{$self->roles} => $role;
}

sub role_applications {
    my ($self) = @_;

    return @{$self->_get_role_applications};
}

sub add_role_application {
    my ($self, $application) = @_;
    (blessed($application) && $application->isa('Moose::Meta::Role::Application::ToClass'))
        || $self->throw_error("Role applications must be instances of Moose::Meta::Role::Application::ToClass", data => $application);
    push @{$self->_get_role_applications} => $application;
}

sub calculate_all_roles {
    my $self = shift;
    my %seen;
    grep { !$seen{$_->name}++ } map { $_->calculate_all_roles } @{ $self->roles };
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
        || $self->throw_error("You must supply a role name to look for");

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
        || $self->throw_error("You must supply a role name to look for");

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

    $object->BUILDALL($params) if $object->can('BUILDALL');

    return $object;
}

sub superclasses {
    my $self = shift;
    my $supers = Data::OptList::mkopt(\@_);
    foreach my $super (@{ $supers }) {
        my ($name, $opts) = @{ $super };
        Class::MOP::load_class($name, $opts);
        my $meta = Class::MOP::class_of($name);
        $self->throw_error("You cannot inherit from a Moose Role ($name)")
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

    (!$self->has_method($name))
        || $self->throw_error("Cannot add an override method if a local method is already present");

    $self->add_method($name => Moose::Meta::Method::Overridden->new(
        method  => $method,
        class   => $self,
        package => $_super_package, # need this for roles
        name    => $name,
    ));
}

sub add_augment_method_modifier {
    my ($self, $name, $method) = @_;
    (!$self->has_method($name))
        || $self->throw_error("Cannot add an augment method if a local method is already present");

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
        error_class => 'Moose::Error::Default',
    );
}

sub _fix_class_metaclass_incompatibility {
    my $self = shift;
    my ($super_meta) = @_;

    $self->SUPER::_fix_class_metaclass_incompatibility(@_);

    if ($self->_class_metaclass_can_be_made_compatible($super_meta)) {
        ($self->is_pristine)
            || confess "Can't fix metaclass incompatibility for "
                     . $self->name
                     . " because it is not pristine.";
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
            || confess "Can't fix metaclass incompatibility for "
                     . $self->name
                     . " because it is not pristine.";
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
        || $self->throw_error("Could not find an attribute by the name of '$attr_name' to inherit from in ${\$self->name}", data => $attr_name);
    if ($inherited_attr->isa('Moose::Meta::Attribute')) {
        return $inherited_attr->clone_and_inherit_options(%options);
    }
    else {
        # NOTE:
        # kind of a kludge to handle Class::MOP::Attributes
        return $inherited_attr->Moose::Meta::Attribute::clone_and_inherit_options(%options);
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

## -------------------------------------------------

our $error_level;

sub throw_error {
    my ( $self, @args ) = @_;
    local $error_level = ($error_level || 0) + 1;
    $self->raise_error($self->create_error(@args));
}

sub raise_error {
    my ( $self, @args ) = @_;
    die @args;
}

sub create_error {
    my ( $self, @args ) = @_;

    require Carp::Heavy;

    local $error_level = ($error_level || 0 ) + 1;

    if ( @args % 2 == 1 ) {
        unshift @args, "message";
    }

    my %args = ( metaclass => $self, last_error => $@, @args );

    $args{depth} += $error_level;

    my $class = ref $self ? $self->error_class : "Moose::Error::Default";

    Class::MOP::load_class($class);

    $class->new(
        Carp::caller_info($args{depth}),
        %args
    );
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Class - The Moose metaclass

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Class> that provides
additional Moose-specific functionality.

To really understand this class, you will need to start with the
L<Class::MOP::Class> documentation. This class can be understood as a
set of additional features on top of the basic feature provided by
that parent class.

=head1 INHERITANCE

C<Moose::Meta::Class> is a subclass of L<Class::MOP::Class>.

=head1 METHODS

=over 4

=item B<< Moose::Meta::Class->initialize($package_name, %options) >>

This overrides the parent's method in order to provide its own
defaults for the C<attribute_metaclass>, C<instance_metaclass>, and
C<method_metaclass> options.

These all default to the appropriate Moose class.

=item B<< Moose::Meta::Class->create($package_name, %options) >>

This overrides the parent's method in order to accept a C<roles>
option. This should be an array reference containing roles
that the class does, each optionally followed by a hashref of options
(C<-excludes> and C<-alias>).

  my $metaclass = Moose::Meta::Class->create( 'New::Class', roles => [...] );

=item B<< Moose::Meta::Class->create_anon_class >>

This overrides the parent's method to accept a C<roles> option, just
as C<create> does.

It also accepts a C<cache> option. If this is true, then the anonymous
class will be cached based on its superclasses and roles. If an
existing anonymous class in the cache has the same superclasses and
roles, it will be reused.

  my $metaclass = Moose::Meta::Class->create_anon_class(
      superclasses => ['Foo'],
      roles        => [qw/Some Roles Go Here/],
      cache        => 1,
  );

Each entry in both the C<superclasses> and the C<roles> option can be
followed by a hash reference with arguments. The C<superclasses>
option can be supplied with a L<-version|Class::MOP/Class Loading
Options> option that ensures the loaded superclass satisfies the
required version. The C<role> option also takes the C<-version> as an
argument, but the option hash reference can also contain any other
role relevant values like exclusions or parameterized role arguments.

=item B<< $metaclass->make_immutable(%options) >>

This overrides the parent's method to add a few options. Specifically,
it uses the Moose-specific constructor and destructor classes, and
enables inlining the destructor.

Since Moose always inlines attributes, it sets the C<inline_accessors> option
to false.

=item B<< $metaclass->new_object(%params) >>

This overrides the parent's method in order to add support for
attribute triggers.

=item B<< $metaclass->superclasses(@superclasses) >>

This is the accessor allowing you to read or change the parents of
the class.

Each superclass can be followed by a hash reference containing a
L<-version|Class::MOP/Class Loading Options> value. If the version
requirement is not satisfied an error will be thrown.

=item B<< $metaclass->add_override_method_modifier($name, $sub) >>

This adds an C<override> method modifier to the package.

=item B<< $metaclass->add_augment_method_modifier($name, $sub) >>

This adds an C<augment> method modifier to the package.

=item B<< $metaclass->calculate_all_roles >>

This will return a unique array of C<Moose::Meta::Role> instances
which are attached to this class.

=item B<< $metaclass->calculate_all_roles_with_inheritance >>

This will return a unique array of C<Moose::Meta::Role> instances
which are attached to this class, and each of this class's ancestors.

=item B<< $metaclass->add_role($role) >>

This takes a L<Moose::Meta::Role> object, and adds it to the class's
list of roles. This I<does not> actually apply the role to the class.

=item B<< $metaclass->role_applications >>

Returns a list of L<Moose::Meta::Role::Application::ToClass>
objects, which contain the arguments to role application.

=item B<< $metaclass->add_role_application($application) >>

This takes a L<Moose::Meta::Role::Application::ToClass> object, and
adds it to the class's list of role applications. This I<does not>
actually apply any role to the class; it is only for tracking role
applications.

=item B<< $metaclass->does_role($role) >>

This returns a boolean indicating whether or not the class does the specified
role. The role provided can be either a role name or a L<Moose::Meta::Role>
object. This tests both the class and its parents.

=item B<< $metaclass->excludes_role($role_name) >>

A class excludes a role if it has already composed a role which
excludes the named role. This tests both the class and its parents.

=item B<< $metaclass->add_attribute($attr_name, %params|$params) >>

This overrides the parent's method in order to allow the parameters to
be provided as a hash reference.

=item B<< $metaclass->constructor_class($class_name) >>

=item B<< $metaclass->destructor_class($class_name) >>

These are the names of classes used when making a class immutable. These
default to L<Moose::Meta::Method::Constructor> and
L<Moose::Meta::Method::Destructor> respectively. These accessors are
read-write, so you can use them to change the class name.

=item B<< $metaclass->error_class($class_name) >>

The name of the class used to throw errors. This defaults to
L<Moose::Error::Default>, which generates an error with a stacktrace
just like C<Carp::confess>.

=item B<< $metaclass->throw_error($message, %extra) >>

Throws the error created by C<create_error> using C<raise_error>

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

