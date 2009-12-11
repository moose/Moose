
package Moose::Meta::Role;

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';
use Carp         'confess';
use Devel::GlobalDestruction 'in_global_destruction';

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Class;
use Moose::Meta::Role::Method;
use Moose::Meta::Role::Method::Required;
use Moose::Meta::Role::Method::Conflicting;

use base 'Class::MOP::Module';

## ------------------------------------------------------------------
## NOTE:
## I normally don't do this, but I am doing
## a whole bunch of meta-programmin in this
## module, so it just makes sense. For a clearer
## picture of what is going on in the next
## several lines of code, look at the really
## big comment at the end of this file (right
## before the POD).
## - SL
## ------------------------------------------------------------------

my $META = __PACKAGE__->meta;

## ------------------------------------------------------------------
## attributes ...

# NOTE:
# since roles are lazy, we hold all the attributes
# of the individual role in 'statis' until which
# time when it is applied to a class. This means
# keeping a lot of things in hash maps, so we are
# using a little of that meta-programmin' magic
# here an saving lots of extra typin. And since
# many of these attributes above require similar
# functionality to support them, so we again use
# the wonders of meta-programmin' to deliver a
# very compact solution to this normally verbose
# problem.
# - SL

foreach my $action (
    {
        name        => 'excluded_roles_map',
        attr_reader => 'get_excluded_roles_map' ,
        methods     => {
            add       => 'add_excluded_roles',
            get_keys  => 'get_excluded_roles_list',
            existence => 'excludes_role',
        }
    },
    {
        name        => 'required_methods',
        attr_reader => 'get_required_methods_map',
        methods     => {
            remove     => 'remove_required_methods',
            get_values => 'get_required_method_list',
            existence  => 'requires_method',
        }
    },
    {
        name        => '_attribute_map',
        attr_reader => '_attribute_map',
        methods     => {
            get       => 'get_attribute',
            get_keys  => 'get_attribute_list',
            existence => 'has_attribute',
            remove    => 'remove_attribute',
        }
    }
) {

    my $attr_reader = $action->{attr_reader};
    my $methods     = $action->{methods};

    # create the attribute
    $META->add_attribute($action->{name} => (
        reader  => $attr_reader,
        default => sub { {} }
    ));

    # create some helper methods
    $META->add_method($methods->{add} => sub {
        my ($self, @values) = @_;
        $self->$attr_reader->{$_} = undef foreach @values;
    }) if exists $methods->{add};

    $META->add_method($methods->{get_keys} => sub {
        my ($self) = @_;
        keys %{$self->$attr_reader};
    }) if exists $methods->{get_keys};

    $META->add_method($methods->{get_values} => sub {
        my ($self) = @_;
        values %{$self->$attr_reader};
    }) if exists $methods->{get_values};

    $META->add_method($methods->{get} => sub {
        my ($self, $name) = @_;
        $self->$attr_reader->{$name}
    }) if exists $methods->{get};

    $META->add_method($methods->{existence} => sub {
        my ($self, $name) = @_;
        exists $self->$attr_reader->{$name} ? 1 : 0;
    }) if exists $methods->{existence};

    $META->add_method($methods->{remove} => sub {
        my ($self, @values) = @_;
        delete $self->$attr_reader->{$_} foreach @values;
    }) if exists $methods->{remove};
}

$META->add_attribute(
    'method_metaclass',
    reader  => 'method_metaclass',
    default => 'Moose::Meta::Role::Method',
);

$META->add_attribute(
    'required_method_metaclass',
    reader  => 'required_method_metaclass',
    default => 'Moose::Meta::Role::Method::Required',
);

$META->add_attribute(
    'conflicting_method_metaclass',
    reader  => 'conflicting_method_metaclass',
    default => 'Moose::Meta::Role::Method::Conflicting',
);

$META->add_attribute(
    'application_to_class_class',
    reader  => 'application_to_class_class',
    default => 'Moose::Meta::Role::Application::ToClass',
);

$META->add_attribute(
    'application_to_role_class',
    reader  => 'application_to_role_class',
    default => 'Moose::Meta::Role::Application::ToRole',
);

$META->add_attribute(
    'application_to_instance_class',
    reader  => 'application_to_instance_class',
    default => 'Moose::Meta::Role::Application::ToInstance',
);

$META->add_attribute(
    'composition_class_roles',
    reader    => 'composition_class_roles',
    predicate => 'has_composition_class_roles',
);

## some things don't always fit, so they go here ...

sub add_attribute {
    my $self = shift;
    my $name = shift;
    unless ( defined $name ) {
        require Moose;
        Moose->throw_error("You must provide a name for the attribute");
    }
    my $attr_desc;
    if (scalar @_ == 1 && ref($_[0]) eq 'HASH') {
        $attr_desc = $_[0];
    }
    else {
        $attr_desc = { @_ };
    }
    $self->_attribute_map->{$name} = $attr_desc;
}

sub add_required_methods {
    my $self = shift;

    for (@_) {
        my $method = $_;
        if (!blessed($method)) {
            $method = $self->required_method_metaclass->new(
                name => $method,
            );
        }
        $self->get_required_methods_map->{$method->name} = $method;
    }
}

sub add_conflicting_method {
    my $self = shift;

    my $method;
    if (@_ == 1 && blessed($_[0])) {
        $method = shift;
    }
    else {
        $method = $self->conflicting_method_metaclass->new(@_);
    }

    $self->add_required_methods($method);
}

## ------------------------------------------------------------------
## method modifiers

# NOTE:
# the before/around/after method modifiers are
# stored by name, but there can be many methods
# then associated with that name. So again we have
# lots of similar functionality, so we can do some
# meta-programmin' and save some time.
# - SL

foreach my $modifier_type (qw[ before around after ]) {

    my $attr_reader = "get_${modifier_type}_method_modifiers_map";

    # create the attribute ...
    $META->add_attribute("${modifier_type}_method_modifiers" => (
        reader  => $attr_reader,
        default => sub { {} }
    ));

    # and some helper methods ...
    $META->add_method("get_${modifier_type}_method_modifiers" => sub {
        my ($self, $method_name) = @_;
        #return () unless exists $self->$attr_reader->{$method_name};
        my $mm = $self->$attr_reader->{$method_name};
        $mm ? @$mm : ();
    });

    $META->add_method("has_${modifier_type}_method_modifiers" => sub {
        my ($self, $method_name) = @_;
        # NOTE:
        # for now we assume that if it exists,..
        # it has at least one modifier in it
        (exists $self->$attr_reader->{$method_name}) ? 1 : 0;
    });

    $META->add_method("add_${modifier_type}_method_modifier" => sub {
        my ($self, $method_name, $method) = @_;

        $self->$attr_reader->{$method_name} = []
            unless exists $self->$attr_reader->{$method_name};

        my $modifiers = $self->$attr_reader->{$method_name};

        # NOTE:
        # check to see that we aren't adding the
        # same code twice. We err in favor of the
        # first on here, this may not be as expected
        foreach my $modifier (@{$modifiers}) {
            return if $modifier == $method;
        }

        push @{$modifiers} => $method;
    });

}

## ------------------------------------------------------------------
## override method mofidiers

$META->add_attribute('override_method_modifiers' => (
    reader  => 'get_override_method_modifiers_map',
    default => sub { {} }
));

# NOTE:
# these are a little different because there
# can only be one per name, whereas the other
# method modifiers can have multiples.
# - SL

sub add_override_method_modifier {
    my ($self, $method_name, $method) = @_;
    (!$self->has_method($method_name))
        || Moose->throw_error("Cannot add an override of method '$method_name' " .
                   "because there is a local version of '$method_name'");
    $self->get_override_method_modifiers_map->{$method_name} = $method;
}

sub has_override_method_modifier {
    my ($self, $method_name) = @_;
    # NOTE:
    # for now we assume that if it exists,..
    # it has at least one modifier in it
    (exists $self->get_override_method_modifiers_map->{$method_name}) ? 1 : 0;
}

sub get_override_method_modifier {
    my ($self, $method_name) = @_;
    $self->get_override_method_modifiers_map->{$method_name};
}

## general list accessor ...

sub get_method_modifier_list {
    my ($self, $modifier_type) = @_;
    my $accessor = "get_${modifier_type}_method_modifiers_map";
    keys %{$self->$accessor};
}

sub reset_package_cache_flag  { (shift)->{'_package_cache_flag'} = undef }
sub update_package_cache_flag {
    my $self = shift;
    $self->{'_package_cache_flag'} = Class::MOP::check_package_cache_flag($self->name);
}



## ------------------------------------------------------------------
## subroles

$META->add_attribute('roles' => (
    reader  => 'get_roles',
    default => sub { [] }
));

sub add_role {
    my ($self, $role) = @_;
    (blessed($role) && $role->isa('Moose::Meta::Role'))
        || Moose->throw_error("Roles must be instances of Moose::Meta::Role");
    push @{$self->get_roles} => $role;
    $self->reset_package_cache_flag;
}

sub calculate_all_roles {
    my $self = shift;
    my %seen;
    grep {
        !$seen{$_->name}++
    } ($self, map {
                  $_->calculate_all_roles
              } @{ $self->get_roles });
}

sub does_role {
    my ($self, $role_name) = @_;
    (defined $role_name)
        || Moose->throw_error("You must supply a role name to look for");
    # if we are it,.. then return true
    return 1 if $role_name eq $self->name;
    # otherwise.. check our children
    foreach my $role (@{$self->get_roles}) {
        return 1 if $role->does_role($role_name);
    }
    return 0;
}

sub find_method_by_name { (shift)->get_method(@_) }

sub alias_method {
    Carp::cluck("The alias_method method is deprecated. Use add_method instead.\n");

    my $self = shift;

    $self->add_method(@_);
}

## ------------------------------------------------------------------
## role construction
## ------------------------------------------------------------------

sub apply {
    my ($self, $other, @args) = @_;

    (blessed($other))
        || Moose->throw_error("You must pass in an blessed instance");

    my $application_class;
    if ($other->isa('Moose::Meta::Role')) {
        $application_class = $self->application_to_role_class;
    }
    elsif ($other->isa('Moose::Meta::Class')) {
        $application_class = $self->application_to_class_class;
    }
    else {
        $application_class = $self->application_to_instance_class;
    }

    Class::MOP::load_class($application_class);
    return $application_class->new(@args)->apply($self, $other);
}

sub combine {
    my ($class, @role_specs) = @_;

    require Moose::Meta::Role::Composite;

    my (@roles, %role_params);
    while (@role_specs) {
        my ($role_name, $params) = @{ splice @role_specs, 0, 1 };
        my $requested_role = Class::MOP::class_of($role_name);

        my $actual_role = $requested_role->_role_for_combination($params);
        push @roles => $actual_role;

        next unless defined $params;
        $role_params{$actual_role->name} = $params;
    }

    my $c = Moose::Meta::Role::Composite->new(roles => \@roles);
    return $c->apply_params(\%role_params);
}

sub _role_for_combination {
    my ($self, $params) = @_;
    return $self;
}

sub create {
    my ( $role, $package_name, %options ) = @_;

    $options{package} = $package_name;

    (ref $options{attributes} eq 'HASH')
        || confess "You must pass a HASH ref of attributes"
            if exists $options{attributes};

    (ref $options{methods} eq 'HASH')
        || confess "You must pass a HASH ref of methods"
            if exists $options{methods};

    my (%initialize_options) = %options;
    delete @initialize_options{qw(
        package
        attributes
        methods
        version
        authority
    )};

    my $meta = $role->initialize( $package_name => %initialize_options );

    $meta->_instantiate_module( $options{version}, $options{authority} );

    # FIXME totally lame
    $meta->add_method('meta' => sub {
        $role->initialize(ref($_[0]) || $_[0]);
    });

    if (exists $options{attributes}) {
        foreach my $attribute_name (keys %{$options{attributes}}) {
            my $attr = $options{attributes}->{$attribute_name};
            $meta->add_attribute($attribute_name => $attr);
        }
    }

    if (exists $options{methods}) {
        foreach my $method_name (keys %{$options{methods}}) {
            $meta->add_method($method_name, $options{methods}->{$method_name});
        }
    }

    Class::MOP::weaken_metaclass($meta->name)
        if $meta->is_anon_role;

    return $meta;
}

# anonymous roles. most of it is copied straight out of Class::MOP::Class.
# an intrepid hacker might find great riches if he unifies this code with that
# code in Class::MOP::Module or Class::MOP::Package
{
    # NOTE:
    # this should be sufficient, if you have a
    # use case where it is not, write a test and
    # I will change it.
    my $ANON_ROLE_SERIAL = 0;

    # NOTE:
    # we need a sufficiently annoying prefix
    # this should suffice for now, this is
    # used in a couple of places below, so
    # need to put it up here for now.
    my $ANON_ROLE_PREFIX = 'Moose::Meta::Role::__ANON__::SERIAL::';

    sub is_anon_role {
        my $self = shift;
        no warnings 'uninitialized';
        $self->name =~ /^$ANON_ROLE_PREFIX/;
    }

    sub create_anon_role {
        my ($role, %options) = @_;
        my $package_name = $ANON_ROLE_PREFIX . ++$ANON_ROLE_SERIAL;
        return $role->create($package_name, %options);
    }

    # NOTE:
    # this will only get called for
    # anon-roles, all other calls
    # are assumed to occur during
    # global destruction and so don't
    # really need to be handled explicitly
    sub DESTROY {
        my $self = shift;

        return if in_global_destruction(); # it'll happen soon anyway and this just makes things more complicated

        no warnings 'uninitialized';
        return unless $self->name =~ /^$ANON_ROLE_PREFIX/;

        # XXX: is this necessary for us? I don't understand what it's doing
        # -sartak

        # Moose does a weird thing where it replaces the metaclass for
        # class when fixing metaclass incompatibility. In that case,
        # we don't want to clean out the namespace now. We can detect
        # that because Moose will explicitly update the singleton
        # cache in Class::MOP.
        #my $current_meta = Class::MOP::get_metaclass_by_name($self->name);
        #return if $current_meta ne $self;

        my ($serial_id) = ($self->name =~ /^$ANON_ROLE_PREFIX(\d+)/);
        no strict 'refs';
        foreach my $key (keys %{$ANON_ROLE_PREFIX . $serial_id}) {
            delete ${$ANON_ROLE_PREFIX . $serial_id}{$key};
        }
        delete ${'main::' . $ANON_ROLE_PREFIX}{$serial_id . '::'};
    }
}

#####################################################################
## NOTE:
## This is Moose::Meta::Role as defined by Moose (plus the use of
## MooseX::AttributeHelpers module). It is here as a reference to
## make it easier to see what is happening above with all the meta
## programming. - SL
#####################################################################
#
# has 'roles' => (
#     metaclass => 'Array',
#     reader    => 'get_roles',
#     isa       => 'ArrayRef[Moose::Meta::Role]',
#     default   => sub { [] },
#     provides  => {
#         'push' => 'add_role',
#     }
# );
#
# has 'excluded_roles_map' => (
#     metaclass => 'Hash',
#     reader    => 'get_excluded_roles_map',
#     isa       => 'HashRef[Str]',
#     provides  => {
#         # Not exactly set, cause it sets multiple
#         'set'    => 'add_excluded_roles',
#         'keys'   => 'get_excluded_roles_list',
#         'exists' => 'excludes_role',
#     }
# );
#
# has 'attribute_map' => (
#     metaclass => 'Hash',
#     reader    => '_attribute_map',
#     isa       => 'HashRef[Str]',
#     provides => {
#         # 'set'  => 'add_attribute' # has some special crap in it
#         'get'    => 'get_attribute',
#         'keys'   => 'get_attribute_list',
#         'exists' => 'has_attribute',
#         # Not exactly delete, cause it sets multiple
#         'delete' => 'remove_attribute',
#     }
# );
#
# has 'required_methods' => (
#     metaclass => 'Hash',
#     reader    => 'get_required_methods_map',
#     isa       => 'HashRef[Moose::Meta::Role::Method::Required]',
#     provides  => {
#         # not exactly set, or delete since it works for multiple
#         'set'    => 'add_required_methods',
#         'delete' => 'remove_required_methods',
#         'keys'   => 'get_required_method_list',
#         'exists' => 'requires_method',
#     }
# );
#
# # the before, around and after modifiers are
# # HASH keyed by method-name, with ARRAY of
# # CODE refs to apply in that order
#
# has 'before_method_modifiers' => (
#     metaclass => 'Hash',
#     reader    => 'get_before_method_modifiers_map',
#     isa       => 'HashRef[ArrayRef[CodeRef]]',
#     provides  => {
#         'keys'   => 'get_before_method_modifiers',
#         'exists' => 'has_before_method_modifiers',
#         # This actually makes sure there is an
#         # ARRAY at the given key, and pushed onto
#         # it. It also checks for duplicates as well
#         # 'add'  => 'add_before_method_modifier'
#     }
# );
#
# has 'after_method_modifiers' => (
#     metaclass => 'Hash',
#     reader    =>'get_after_method_modifiers_map',
#     isa       => 'HashRef[ArrayRef[CodeRef]]',
#     provides  => {
#         'keys'   => 'get_after_method_modifiers',
#         'exists' => 'has_after_method_modifiers',
#         # This actually makes sure there is an
#         # ARRAY at the given key, and pushed onto
#         # it. It also checks for duplicates as well
#         # 'add'  => 'add_after_method_modifier'
#     }
# );
#
# has 'around_method_modifiers' => (
#     metaclass => 'Hash',
#     reader    =>'get_around_method_modifiers_map',
#     isa       => 'HashRef[ArrayRef[CodeRef]]',
#     provides  => {
#         'keys'   => 'get_around_method_modifiers',
#         'exists' => 'has_around_method_modifiers',
#         # This actually makes sure there is an
#         # ARRAY at the given key, and pushed onto
#         # it. It also checks for duplicates as well
#         # 'add'  => 'add_around_method_modifier'
#     }
# );
#
# # override is similar to the other modifiers
# # except that it is not an ARRAY of code refs
# # but instead just a single name->code mapping
#
# has 'override_method_modifiers' => (
#     metaclass => 'Hash',
#     reader    =>'get_override_method_modifiers_map',
#     isa       => 'HashRef[CodeRef]',
#     provides  => {
#         'keys'   => 'get_override_method_modifier',
#         'exists' => 'has_override_method_modifier',
#         'add'    => 'add_override_method_modifier', # checks for local method ..
#     }
# );
#
#####################################################################


1;

__END__

=pod

=head1 NAME

Moose::Meta::Role - The Moose Role metaclass

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Module> that provides
additional Moose-specific functionality.

It's API looks a lot like L<Moose::Meta::Class>, but internally it
implements many things differently. This may change in the future.

=head1 INHERITANCE

C<Moose::Meta::Role> is a subclass of L<Class::MOP::Module>.

=head1 METHODS

=head2 Construction

=over 4

=item B<< Moose::Meta::Role->initialize($role_name) >>

This method creates a new role object with the provided name.

=item B<< Moose::Meta::Role->combine( [ $role => { ... } ], [ $role ], ... ) >>

This method accepts a list of array references. Each array reference
should contain a role name as its first element. The second element is
an optional hash reference. The hash reference can contain C<-excludes>
and C<-alias> keys to control how methods are composed from the role.

The return value is a new L<Moose::Meta::Role::Composite> that
represents the combined roles.

=item B<< Moose::Meta::Role->create($name, %options) >>

This method is identical to the L<Moose::Meta::Class> C<create>
method.

=item B<< Moose::Meta::Role->create_anon_role >>

This method is identical to the L<Moose::Meta::Class>
C<create_anon_class> method.

=item B<< $metarole->is_anon_role >>

Returns true if the role is an anonymous role.

=back

=head2 Role application

=over 4

=item B<< $metarole->apply( $thing, @options ) >>

This method applies a role to the given C<$thing>. That can be another
L<Moose::Meta::Role>, object, a L<Moose::Meta::Class> object, or a
(non-meta) object instance.

The options are passed directly to the constructor for the appropriate
L<Moose::Meta::Role::Application> subclass.

Note that this will apply the role even if the C<$thing> in question already
C<does> this role.  L<Moose::Util/does_role> is a convenient wrapper for
finding out if role application is necessary.

=back

=head2 Roles and other roles

=over 4

=item B<< $metarole->get_roles >>

This returns an array reference of roles which this role does. This
list may include duplicates.

=item B<< $metarole->calculate_all_roles >>

This returns a I<unique> list of all roles that this role does, and
all the roles that its roles do.

=item B<< $metarole->does_role($role_name) >>

Given a role I<name>, returns true if this role does the given
role.

=item B<< $metarole->add_role($role) >>

Given a L<Moose::Meta::Role> object, this adds the role to the list of
roles that the role does.

=item B<< $metarole->get_excluded_roles_list >>

Returns a list of role names which this role excludes.

=item B<< $metarole->excludes_role($role_name) >>

Given a role I<name>, returns true if this role excludes the named
role.

=item B<< $metarole->add_excluded_roles(@role_names) >>

Given one or more role names, adds those roles to the list of excluded
roles.

=back

=head2 Methods

The methods for dealing with a role's methods are all identical in API
and behavior to the same methods in L<Class::MOP::Class>.

=over 4

=item B<< $metarole->method_metaclass >>

Returns the method metaclass name for the role. This defaults to
L<Moose::Meta::Role::Method>.

=item B<< $metarole->get_method($name) >>

=item B<< $metarole->has_method($name) >>

=item B<< $metarole->add_method( $name, $body ) >>

=item B<< $metarole->get_method_list >>

=item B<< $metarole->find_method_by_name($name) >>

These methods are all identical to the methods of the same name in
L<Class::MOP::Package>

=back

=head2 Attributes

As with methods, the methods for dealing with a role's attribute are
all identical in API and behavior to the same methods in
L<Class::MOP::Class>.

However, attributes stored in this class are I<not> stored as
objects. Rather, the attribute definition is stored as a hash
reference. When a role is composed into a class, this hash reference
is passed directly to the metaclass's C<add_attribute> method.

This is quite likely to change in the future.

=over 4

=item B<< $metarole->get_attribute($attribute_name) >>

=item B<< $metarole->has_attribute($attribute_name) >>

=item B<< $metarole->get_attribute_list >>

=item B<< $metarole->add_attribute($name, %options) >>

=item B<< $metarole->remove_attribute($attribute_name) >>

=back

=head2 Required methods

=over 4

=item B<< $metarole->get_required_method_list >>

Returns the list of methods required by the role.

=item B<< $metarole->requires_method($name) >>

Returns true if the role requires the named method.

=item B<< $metarole->add_required_methods(@names) >>

Adds the named methods to the role's list of required methods.

=item B<< $metarole->remove_required_methods(@names) >>

Removes the named methods from the role's list of required methods.

=item B<< $metarole->add_conflicting_method(%params) >>

Instantiate the parameters as a L<Moose::Meta::Role::Method::Conflicting>
object, then add it to the required method list.

=back

=head2 Method modifiers

These methods act like their counterparts in L<Class::Mop::Class> and
L<Moose::Meta::Class>.

However, method modifiers are simply stored internally, and are not
applied until the role itself is applied to a class.

=over 4

=item B<< $metarole->add_after_method_modifier($method_name, $method) >>

=item B<< $metarole->add_around_method_modifier($method_name, $method) >>

=item B<< $metarole->add_before_method_modifier($method_name, $method) >>

=item B<< $metarole->add_override_method_modifier($method_name, $method) >>

These methods all add an appropriate modifier to the internal list of
modifiers.

=item B<< $metarole->has_after_method_modifiers >>

=item B<< $metarole->has_around_method_modifiers >>

=item B<< $metarole->has_before_method_modifiers >>

=item B<< $metarole->has_override_method_modifier >>

Return true if the role has any modifiers of the given type.

=item B<< $metarole->get_after_method_modifiers($method_name) >>

=item B<< $metarole->get_around_method_modifiers($method_name) >>

=item B<< $metarole->get_before_method_modifiers($method_name) >>

Given a method name, returns a list of the appropriate modifiers for
that method.

=item B<< $metarole->get_override_method_modifier($method_name) >>

Given a method name, returns the override method modifier for that
method, if it has one.

=back

=head2 Introspection

=over 4

=item B<< Moose::Meta::Role->meta >>

This will return a L<Class::MOP::Class> instance for this class.

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
