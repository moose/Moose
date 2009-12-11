
package Moose::Meta::Class;

use strict;
use warnings;

use Class::MOP;

use Carp ();
use List::Util qw( first );
use List::MoreUtils qw( any all uniq first_index );
use Scalar::Util 'weaken', 'blessed';

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Method::Overridden;
use Moose::Meta::Method::Augmented;
use Moose::Error::Default;
use Moose::Meta::Class::Immutable::Trait;
use Moose::Meta::Method::Constructor;
use Moose::Meta::Method::Destructor;

use base 'Class::MOP::Class';

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

sub _immutable_options {
    my ( $self, @args ) = @_;

    $self->SUPER::_immutable_options(
        inline_destructor => 1,

        # Moose always does this when an attribute is created
        inline_accessors => 0,

        @args,
    );
}

sub create {
    my ($self, $package_name, %options) = @_;

    (ref $options{roles} eq 'ARRAY')
        || $self->throw_error("You must pass an ARRAY ref of roles", data => $options{roles})
            if exists $options{roles};
    my $roles = delete $options{roles};

    my $class = $self->SUPER::create($package_name, %options);

    if ($roles) {
        Moose::Util::apply_all_roles( $class, @$roles );
    }

    return $class;
}

sub _check_metaclass_compatibility {
    my $self = shift;

    if ( my @supers = $self->superclasses ) {
        $self->_fix_metaclass_incompatibility(@supers);
    }

    $self->SUPER::_check_metaclass_compatibility(@_);
}

my %ANON_CLASSES;

sub create_anon_class {
    my ($self, %options) = @_;

    my $cache_ok = delete $options{cache};

    # something like Super::Class|Super::Class::2=Role|Role::1
    my $cache_key = join '=' => (
        join('|', @{$options{superclasses} || []}),
        join('|', sort @{$options{roles}   || []}),
    );

    if ($cache_ok && defined $ANON_CLASSES{$cache_key}) {
        return $ANON_CLASSES{$cache_key};
    }

    my $new_class = $self->SUPER::create_anon_class(%options);

    $ANON_CLASSES{$cache_key} = $new_class
        if $cache_ok;

    return $new_class;
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
    my $class  = shift;
    my $params = @_ == 1 ? $_[0] : {@_};
    my $self   = $class->SUPER::new_object($params);

    foreach my $attr ( $class->get_all_attributes() ) {

        next unless $attr->can('has_trigger') && $attr->has_trigger;

        my $init_arg = $attr->init_arg;

        next unless defined $init_arg;

        next unless exists $params->{$init_arg};

        $attr->trigger->(
            $self,
            (
                  $attr->should_coerce
                ? $attr->get_read_method_ref->($self)
                : $params->{$init_arg}
            ),
        );
    }

    return $self;
}

sub superclasses {
    my $self = shift;
    my @supers = @_;
    foreach my $super (@supers) {
        Class::MOP::load_class($super);
        my $meta = Class::MOP::class_of($super);
        $self->throw_error("You cannot inherit from a Moose Role ($super)")
            if $meta && $meta->isa('Moose::Meta::Role')
    }
    return $self->SUPER::superclasses(@supers);
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

sub _fix_metaclass_incompatibility {
    my ($self, @superclasses) = @_;

    $self->_fix_one_incompatible_metaclass($_)
        for map { Moose::Meta::Class->initialize($_) } @superclasses;
}

sub _fix_one_incompatible_metaclass {
    my ($self, $meta) = @_;

    return if $self->_superclass_meta_is_compatible($meta);

    unless ( $self->is_pristine ) {
        $self->throw_error(
              "Cannot attempt to reinitialize metaclass for "
            . $self->name
            . ", it isn't pristine" );
    }

    $self->_reconcile_with_superclass_meta($meta);
}

sub _superclass_meta_is_compatible {
    my ($self, $super_meta) = @_;

    next unless $super_meta->isa("Class::MOP::Class");

    my $super_meta_name
        = $super_meta->is_immutable
        ? $super_meta->_get_mutable_metaclass_name
        : ref($super_meta);

    return 1
        if $self->isa($super_meta_name)
            and
           $self->instance_metaclass->isa( $super_meta->instance_metaclass );
}

# I don't want to have to type this >1 time
my @MetaClassTypes =
    qw( attribute_metaclass
        method_metaclass
        wrapped_method_metaclass
        instance_metaclass
        constructor_class
        destructor_class
        error_class );

sub _reconcile_with_superclass_meta {
    my ($self, $super_meta) = @_;

    my $super_meta_name
        = $super_meta->is_immutable
        ? $super_meta->_get_mutable_metaclass_name
        : ref($super_meta);

    my $self_metaclass = ref $self;

    # If neither of these is true we have a more serious
    # incompatibility that we just cannot fix (yet?).
    if ( $super_meta_name->isa( ref $self )
        && all { $super_meta->$_->isa( $self->$_ ) } @MetaClassTypes ) {
        $self->_reinitialize_with($super_meta);
    }
    elsif ( $self->_all_metaclasses_differ_by_roles_only($super_meta) ) {
        $self->_reconcile_role_differences($super_meta);
    }
}

sub _reinitialize_with {
    my ( $self, $new_meta ) = @_;

    my $new_self = $new_meta->reinitialize(
        $self->name,
        attribute_metaclass => $new_meta->attribute_metaclass,
        method_metaclass    => $new_meta->method_metaclass,
        instance_metaclass  => $new_meta->instance_metaclass,
    );

    $new_self->$_( $new_meta->$_ )
        for qw( constructor_class destructor_class error_class );

    %$self = %$new_self;

    bless $self, ref $new_self;

    # We need to replace the cached metaclass instance or else when it
    # goes out of scope Class::MOP::Class destroy's the namespace for
    # the metaclass's class, causing much havoc.
    Class::MOP::store_metaclass_by_name( $self->name, $self );
    Class::MOP::weaken_metaclass( $self->name ) if $self->is_anon_class;
}

# In the more complex case, we share a common ancestor with our
# superclass's metaclass, but each metaclass (ours and the parent's)
# has a different set of roles applied. We reconcile this by first
# reinitializing into the parent class, and _then_ applying our own
# roles.
sub _all_metaclasses_differ_by_roles_only {
    my ($self, $super_meta) = @_;

    for my $pair (
        [ ref $self, ref $super_meta ],
        map { [ $self->$_, $super_meta->$_ ] } @MetaClassTypes
        ) {

        next if $pair->[0] eq $pair->[1];

        my $self_meta_meta  = Class::MOP::Class->initialize( $pair->[0] );
        my $super_meta_meta = Class::MOP::Class->initialize( $pair->[1] );

        my $common_ancestor
            = _find_common_ancestor( $self_meta_meta, $super_meta_meta );

        return unless $common_ancestor;

        return
            unless _is_role_only_subclass_of(
            $self_meta_meta,
            $common_ancestor,
            )
            && _is_role_only_subclass_of(
            $super_meta_meta,
            $common_ancestor,
            );
    }

    return 1;
}

# This, and some other functions, could be called as methods, but
# they're not for two reasons. One, we just end up ignoring the first
# argument, because we can't call these directly on one of the real
# arguments, because one of them could be a Class::MOP::Class object
# and not a Moose::Meta::Class. Second, only a completely insane
# person would attempt to subclass this stuff!
sub _find_common_ancestor {
    my ($meta1, $meta2) = @_;

    # FIXME? This doesn't account for multiple inheritance (not sure
    # if it needs to though). For example, is somewhere in $meta1's
    # history it inherits from both ClassA and ClassB, and $meta2
    # inherits from ClassB & ClassA, does it matter? And what crazy
    # fool would do that anyway?

    my %meta1_parents = map { $_ => 1 } $meta1->linearized_isa;

    return first { $meta1_parents{$_} } $meta2->linearized_isa;
}

sub _is_role_only_subclass_of {
    my ($meta, $ancestor) = @_;

    return 1 if $meta->name eq $ancestor;

    my @roles = _all_roles_until( $meta, $ancestor );

    my %role_packages = map { $_->name => 1 } @roles;

    my $ancestor_meta = Class::MOP::Class->initialize($ancestor);

    my %shared_ancestors = map { $_ => 1 } $ancestor_meta->linearized_isa;

    for my $method ( $meta->get_all_methods() ) {
        next if $method->name eq 'meta';
        next if $method->can('associated_attribute');

        next
            if $role_packages{ $method->original_package_name }
                || $shared_ancestors{ $method->original_package_name };

        return 0;
    }

    # FIXME - this really isn't right. Just because an attribute is
    # defined in a role doesn't mean it isn't _also_ defined in the
    # subclass.
    for my $attr ( $meta->get_all_attributes ) {
        next if $shared_ancestors{ $attr->associated_class->name };

        next if any { $_->has_attribute( $attr->name ) } @roles;

        return 0;
    }

    return 1;
}

sub _all_roles {
    my $meta = shift;

    return _all_roles_until($meta);
}

sub _all_roles_until {
    my ($meta, $stop_at_class) = @_;

    return unless $meta->can('calculate_all_roles');

    my @roles = $meta->calculate_all_roles;

    for my $class ( $meta->linearized_isa ) {
        last if $stop_at_class && $stop_at_class eq $class;

        my $meta = Class::MOP::Class->initialize($class);
        last unless $meta->can('calculate_all_roles');

        push @roles, $meta->calculate_all_roles;
    }

    return uniq @roles;
}

sub _reconcile_role_differences {
    my ($self, $super_meta) = @_;

    my $self_meta = Class::MOP::class_of($self);

    my %roles;

    if ( my @roles = map { $_->name } _all_roles($self_meta) ) {
        $roles{metaclass_roles} = \@roles;
    }

    for my $thing (@MetaClassTypes) {
        my $name = $self->$thing();

        my $thing_meta = Class::MOP::Class->initialize($name);

        my @roles = map { $_->name } _all_roles($thing_meta)
            or next;

        $roles{ $thing . '_roles' } = \@roles;
    }

    $self->_reinitialize_with($super_meta);

    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class => $self->name,
        %roles,
    );

    return $self;
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

=item B<< $metaclass->make_immutable(%options) >>

This overrides the parent's method to add a few options. Specifically,
it uses the Moose-specific constructor and destructor classes, and
enables inlining the destructor.

Also, since Moose always inlines attributes, it sets the
C<inline_accessors> option to false.

=item B<< $metaclass->new_object(%params) >>

This overrides the parent's method in order to add support for
attribute triggers.

=item B<< $metaclass->add_override_method_modifier($name, $sub) >>

This adds an C<override> method modifier to the package.

=item B<< $metaclass->add_augment_method_modifier($name, $sub) >>

This adds an C<augment> method modifier to the package.

=item B<< $metaclass->calculate_all_roles >>

This will return a unique array of C<Moose::Meta::Role> instances
which are attached to this class.

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

=item B<< $metaclass->does_role($role_name) >>

This returns a boolean indicating whether or not the class does the
specified role. This tests both the class and its parents.

=item B<< $metaclass->excludes_role($role_name) >>

A class excludes a role if it has already composed a role which
excludes the named role. This tests both the class and its parents.

=item B<< $metaclass->add_attribute($attr_name, %params|$params) >>

This overrides the parent's method in order to allow the parameters to
be provided as a hash reference.

=item B<< $metaclass->constructor_class ($class_name) >>

=item B<< $metaclass->destructor_class ($class_name) >>

These are the names of classes used when making a class
immutable. These default to L<Moose::Meta::Method::Constructor> and
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

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

