
package Moose::Meta::Class;

use strict;
use warnings;

use Class::MOP;

use Carp ();
use Scalar::Util 'weaken', 'blessed';

our $VERSION   = '0.50';
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Method::Overriden;
use Moose::Meta::Method::Augmented;

use base 'Class::MOP::Class';

__PACKAGE__->meta->add_attribute('roles' => (
    reader  => 'roles',
    default => sub { [] }
));

__PACKAGE__->meta->add_attribute('error_builder' => (
    reader  => 'error_builder',
    default => 'confess',
));

__PACKAGE__->meta->add_attribute('error_class' => (
    reader  => 'error_class',
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
    my ($self, $package_name, %options) = @_;
    
    (ref $options{roles} eq 'ARRAY')
        || $self->throw_error("You must pass an ARRAY ref of roles", data => $options{roles})
            if exists $options{roles};
    
    my $class = $self->SUPER::create($package_name, %options);
    
    if (exists $options{roles}) {
        Moose::Util::apply_all_roles($class, @{$options{roles}});
    }
    
    return $class;
}

my %ANON_CLASSES;

sub create_anon_class {
    my ($self, %options) = @_;

    my $cache_ok = delete $options{cache};
    
    # something like Super::Class|Super::Class::2=Role|Role::1
    my $cache_key = join '=' => (
        join('|', sort @{$options{superclasses} || []}),
        join('|', sort @{$options{roles}        || []}),
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
        next unless $class->can('meta') && $class->meta->can('roles');
        foreach my $role (@{$class->meta->roles}) {
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
        next unless $class->can('meta');
        # NOTE:
        # in the pretty rare instance when a Moose metaclass
        # is itself extended with a role, this check needs to
        # be done since some items in the class_precedence_list
        # might in fact be Class::MOP based still.
        next unless $class->meta->can('roles');
        foreach my $role (@{$class->meta->roles}) {
            return 1 if $role->excludes_role($role_name);
        }
    }
    return 0;
}

sub new_object {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new_object(%params);
    foreach my $attr ($class->compute_all_applicable_attributes()) {
        # if we have a trigger, then ...
        if ($attr->can('has_trigger') && $attr->has_trigger) {
            # make sure we have an init-arg ...
            if (defined(my $init_arg = $attr->init_arg)) {
                # now make sure an init-arg was passes ...
                if (exists $params{$init_arg}) {
                    # and if get here, fire the trigger
                    $attr->trigger->(
                        $self, 
                        # check if there is a coercion
                        ($attr->should_coerce
                            # and if so, we need to grab the 
                            # value that is actually been stored
                            ? $attr->get_read_method_ref->($self)
                            # otherwise, just get the value from
                            # the constructor params
                            : $params{$init_arg}), 
                        $attr
                    );
                }
            }       
        }
    }
    return $self;
}

sub construct_instance {
    my ($class, %params) = @_;
    my $meta_instance = $class->get_meta_instance;
    # FIXME:
    # the code below is almost certainly incorrect
    # but this is foreign inheritence, so we might
    # have to kludge it in the end.
    my $instance = $params{'__INSTANCE__'} || $meta_instance->create_instance();
    foreach my $attr ($class->compute_all_applicable_attributes()) {
        $attr->initialize_instance_slot($meta_instance, $instance, \%params);
    }
    return $instance;
}

# FIXME:
# This is ugly
sub get_method_map {
    my $self = shift;

    if (defined $self->{'$!_package_cache_flag'} &&
                $self->{'$!_package_cache_flag'} == Class::MOP::check_package_cache_flag($self->meta->name)) {
        return $self->{'%!methods'};
    }

    my $map  = $self->{'%!methods'};

    my $class_name       = $self->name;
    my $method_metaclass = $self->method_metaclass;

    my %all_code = $self->get_all_package_symbols('CODE');

    foreach my $symbol (keys %all_code) {
        my $code = $all_code{$symbol};

        next if exists  $map->{$symbol} &&
                defined $map->{$symbol} &&
                        $map->{$symbol}->body == $code;

        my ($pkg, $name) = Class::MOP::get_code_info($code);

        if ($pkg->can('meta')
            # NOTE:
            # we don't know what ->meta we are calling
            # here, so we need to be careful cause it
            # just might blow up at us, or just complain
            # loudly (in the case of Curses.pm) so we
            # just be a little overly cautious here.
            # - SL
            && eval { no warnings; blessed($pkg->meta) }
            && $pkg->meta->isa('Moose::Meta::Role')) {
            #my $role = $pkg->meta->name;
            #next unless $self->does_role($role);
        }
        else {
            
            # NOTE:
            # in 5.10 constant.pm the constants show up 
            # as being in the right package, but in pre-5.10
            # they show up as constant::__ANON__ so we 
            # make an exception here to be sure that things
            # work as expected in both.
            # - SL
            unless ($pkg eq 'constant' && $name eq '__ANON__') {
                next if ($pkg  || '') ne $class_name ||
                        (($name || '') ne '__ANON__' && ($pkg  || '') ne $class_name);
            }

        }

        $map->{$symbol} = $method_metaclass->wrap(
            $code,
            package_name => $class_name,
            name         => $symbol
        );
    }

    return $map;
}

### ---------------------------------------------

sub add_attribute {
    my $self = shift;
    $self->SUPER::add_attribute(
        (blessed $_[0] && $_[0]->isa('Class::MOP::Attribute')
            ? $_[0] 
            : $self->_process_attribute(@_))    
    );
}

sub add_override_method_modifier {
    my ($self, $name, $method, $_super_package) = @_;

    (!$self->has_method($name))
        || $self->throw_error("Cannot add an override method if a local method is already present");

    $self->add_method($name => Moose::Meta::Method::Overriden->new(
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
            if blessed($method->{code}) && !$method->{code}->isa('Moose::Meta::Method::Overriden');
    }
    return undef;
}

sub _fix_metaclass_incompatability {
    my ($self, @superclasses) = @_;
    foreach my $super (@superclasses) {
        # don't bother if it does not have a meta.
        next unless $super->can('meta');
        # get the name, make sure we take
        # immutable classes into account
        my $super_meta_name = ($super->meta->is_immutable
                                ? $super->meta->get_mutable_metaclass_name
                                : blessed($super->meta));
        # if it's meta is a vanilla Moose,
        # then we can safely ignore it.
        next if $super_meta_name eq 'Moose::Meta::Class';
        # but if we have anything else,
        # we need to check it out ...
        unless (# see if of our metaclass is incompatible
                ($self->isa($super_meta_name) &&
                 # and see if our instance metaclass is incompatible
                 $self->instance_metaclass->isa($super->meta->instance_metaclass)) &&
                # ... and if we are just a vanilla Moose
                $self->isa('Moose::Meta::Class')) {
            # re-initialize the meta ...
            my $super_meta = $super->meta;
            # NOTE:
            # We might want to consider actually
            # transfering any attributes from the
            # original meta into this one, but in
            # general you should not have any there
            # at this point anyway, so it's very
            # much an obscure edge case anyway
            $self = $super_meta->reinitialize($self->name => (
                'attribute_metaclass' => $super_meta->attribute_metaclass,
                'method_metaclass'    => $super_meta->method_metaclass,
                'instance_metaclass'  => $super_meta->instance_metaclass,
            ));
        }
    }
    return $self;
}

# NOTE:
# this was crap anyway, see
# Moose::Util::apply_all_roles
# instead
sub _apply_all_roles { 
    Carp::croak 'DEPRECATED: use Moose::Util::apply_all_roles($meta, @roles) instead' 
}

sub _process_attribute {
    my ( $self, $name, @args ) = @_;

    @args = %{$args[0]} if scalar @args == 1 && ref($args[0]) eq 'HASH';

    if ($name =~ /^\+(.*)/) {
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
        || $self->throw_error("Could not find an attribute by the name of '$attr_name' to inherit from", data => $attr_name);
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

use Moose::Meta::Method::Constructor;
use Moose::Meta::Method::Destructor;

# This could be done by using SUPER and altering ->options
# I am keeping it this way to make it more explicit.
sub create_immutable_transformer {
    my $self = shift;
    my $class = Class::MOP::Immutable->new($self, {
        read_only   => [qw/
            superclasses
            roles
            error_class
            error_builder
        /],
        cannot_call => [qw/
            add_method
            alias_method
            remove_method
            add_attribute
            remove_attribute
            remove_package_symbol
            add_role
        /],
        memoize     => {
            class_precedence_list             => 'ARRAY',
            compute_all_applicable_attributes => 'ARRAY',
            get_meta_instance                 => 'SCALAR',
            get_method_map                    => 'SCALAR',
            # maybe ....
            calculate_all_roles               => 'ARRAY',
        },
        # NOTE:
        # this is ugly, but so are typeglobs, 
        # so whattayahgonnadoboutit
        # - SL
        wrapped => { 
            add_package_symbol => sub {
                my $original = shift;
                $self->throw_error("Cannot add package symbols to an immutable metaclass") 
                    unless (caller(2))[3] eq 'Class::MOP::Package::get_package_symbol'; 
                goto $original->body;
            },
        },       
    });
    return $class;
}

sub make_immutable {
    my $self = shift;
    $self->SUPER::make_immutable
      (
       constructor_class => 'Moose::Meta::Method::Constructor',
       destructor_class  => 'Moose::Meta::Method::Destructor',
       inline_destructor => 1,
       # NOTE:
       # no need to do this,
       # Moose always does it
       inline_accessors  => 0,
       @_,
      );
}

#{ package Moose::Meta::Class::ErrorRoutines; %Carp::Internal?

our $level;

sub throw_error {
    my ( $self, @args ) = @_;
    local $level = 1;
    $self->raise_error($self->create_error(@args));
}

sub raise_error {
    my ( $self, @args ) = @_;
    die @args;
}

sub create_error {
    my ( $self, @args ) = @_;

    if ( @args % 2 == 1 ) {
        unshift @args, "message";
    }

    my %args = @args;

    local $level = $level + 1;

    if ( my $class = $args{class} || ( ref $self && $self->error_class ) ) {
        return $self->create_error_object( %args, class => $class );
    } else {
        my $builder = $args{builder} || ( ref($self) ? $self->error_builder : "confess" );

        my $builder_method = ( ( ref($builder) && ref($builder) eq 'CODE' ) 
            ? $builder
            : ( $self->can("create_error_$builder") || "create_error_confess" ));

        return $self->$builder_method(%args);
    }
}

sub create_error_object {
    my ( $self, %args ) = @_;

    my $class = delete $args{class};

    $class->new(
        metaclass => $self,
        %args,
        depth => ( ($args{depth} || 1) + ( $level + 1 ) ),
    );
}

sub create_error_croak {
    my ( $self, @args ) = @_;
    $self->_create_error_carpmess( @args );
}

sub create_error_confess {
    my ( $self, @args ) = @_;
    $self->_create_error_carpmess( @args, longmess => 1 );
}

sub _create_error_carpmess {
    my ( $self, %args ) = @_;

    my $carp_level = $level + 1 + ( $args{depth} || 1 );

    local $Carp::CarpLevel = $carp_level; # $Carp::CarpLevel + $carp_level ?
    local $Carp::MaxArgNums = 20;         # default is 8, usually we use named args which gets messier though

    my @args = exists $args{message} ? $args{message} : ();

    if ( $args{longmess} ) {
        return Carp::longmess(@args);
    } else {
        return Carp::shortmess(@args);
    }
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Class - The Moose metaclass

=head1 DESCRIPTION

This is a subclass of L<Class::MOP::Class> with Moose specific
extensions.

For the most part, the only time you will ever encounter an
instance of this class is if you are doing some serious deep
introspection. To really understand this class, you need to refer
to the L<Class::MOP::Class> documentation.

=head1 METHODS

=over 4

=item B<initialize>

=item B<create>

Overrides original to accept a list of roles to apply to
the created class.

   my $metaclass = Moose::Meta::Class->create( 'New::Class', roles => [...] );

=item B<create_anon_class>

Overrides original to support roles and caching.

   my $metaclass = Moose::Meta::Class->create_anon_class(
       superclasses => ['Foo'],
       roles        => [qw/Some Roles Go Here/],
       cache        => 1,
   );

=item B<make_immutable>

Override original to add default options for inlining destructor
and altering the Constructor metaclass.

=item B<create_immutable_transformer>

Override original to lock C<add_role> and memoize C<calculate_all_roles>

=item B<new_object>

We override this method to support the C<trigger> attribute option.

=item B<construct_instance>

This provides some Moose specific extensions to this method, you
almost never call this method directly unless you really know what
you are doing.

This method makes sure to handle the moose weak-ref, type-constraint
and type coercion features.

=item B<get_method_map>

This accommodates Moose::Meta::Role::Method instances, which are
aliased, instead of added, but still need to be counted as valid
methods.

=item B<add_override_method_modifier ($name, $method)>

This will create an C<override> method modifier for you, and install
it in the package.

=item B<add_augment_method_modifier ($name, $method)>

This will create an C<augment> method modifier for you, and install
it in the package.

=item B<calculate_all_roles>

=item B<roles>

This will return an array of C<Moose::Meta::Role> instances which are
attached to this class.

=item B<add_role ($role)>

This takes an instance of C<Moose::Meta::Role> in C<$role>, and adds it
to the list of associated roles.

=item B<does_role ($role_name)>

This will test if this class C<does> a given C<$role_name>. It will
not only check it's local roles, but ask them as well in order to
cascade down the role hierarchy.

=item B<excludes_role ($role_name)>

This will test if this class C<excludes> a given C<$role_name>. It will
not only check it's local roles, but ask them as well in order to
cascade down the role hierarchy.

=item B<add_attribute ($attr_name, %params|$params)>

This method does the same thing as L<Class::MOP::Class::add_attribute>, but adds
support for taking the C<$params> as a HASH ref.

=item B<throw_error $message, %extra>

Throws the error created by C<create_error> using C<raise_error>

=item B<create_error $message, %extra>

Creates an error message or object.

The default behavior is C<create_error_confess>.

If C<error_class> is set uses C<create_error_object>. Otherwise uses
C<error_builder> (a code reference or variant name), and calls the appropriate
C<create_error_$builder> method.

=item B<error_builder $builder_name>

Get or set the error builder. Defaults to C<confess>.

=item B<error_class $class_name>

Get or set the error class. Has no default.

=item B<create_error_confess %args>

Creates an error using L<Carp/longmess>

=item B<create_error_croak %args>

Creates an error using L<Carp/shortmess>

=item B<create_error_object %args>

Calls C<new> on the C<class> parameter in C<%args>. Usable with C<error_class>
to support custom error objects for your meta class.

=item B<raise_error $error>

Dies with an error object or string.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

