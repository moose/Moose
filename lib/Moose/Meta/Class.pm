
package Moose::Meta::Class;

use strict;
use warnings;

use Class::MOP;

use Carp         'confess';
use Scalar::Util 'weaken', 'blessed', 'reftype';

our $VERSION   = '0.17';
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Method::Overriden;

use base 'Class::MOP::Class';

__PACKAGE__->meta->add_attribute('roles' => (
    reader  => 'roles',
    default => sub { [] }
));

sub initialize {
    my $class = shift;
    my $pkg   = shift;
    $class->SUPER::initialize($pkg,
        'attribute_metaclass' => 'Moose::Meta::Attribute',
        'method_metaclass'    => 'Moose::Meta::Method',
        'instance_metaclass'  => 'Moose::Meta::Instance',
        @_);
}

sub add_role {
    my ($self, $role) = @_;
    (blessed($role) && $role->isa('Moose::Meta::Role'))
        || confess "Roles must be instances of Moose::Meta::Role";
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
        || confess "You must supply a role name to look for";
    foreach my $class ($self->class_precedence_list) {
        next unless $class->can('meta');
        foreach my $role (@{$class->meta->roles}) {
            return 1 if $role->does_role($role_name);
        }
    }
    return 0;
}

sub excludes_role {
    my ($self, $role_name) = @_;
    (defined $role_name)
        || confess "You must supply a role name to look for";
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
        # FIXME:
        # this does not accept undefined
        # values, nor does it accept false
        # values to be passed into the init-arg
        next unless $params{$attr->init_arg} && $attr->can('has_trigger') && $attr->has_trigger;
        $attr->trigger->($self, $params{$attr->init_arg}, $attr);
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
        $attr->initialize_instance_slot($meta_instance, $instance, \%params)
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

    foreach my $symbol ($self->list_all_package_symbols('CODE')) {

        my $code = $self->get_package_symbol('&' . $symbol);

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
            next if ($pkg  || '') ne $class_name &&
                    ($name || '') ne '__ANON__';

        }

        $map->{$symbol} = $method_metaclass->wrap($code);
    }

    return $map;
}

### ---------------------------------------------

sub add_attribute {
    my $self = shift;
    $self->SUPER::add_attribute($self->_process_attribute(@_));
}

sub add_override_method_modifier {
    my ($self, $name, $method, $_super_package) = @_;
    (!$self->has_method($name))
        || confess "Cannot add an override method if a local method is already present";
    # need this for roles ...
    $_super_package ||= $self->name;
    my $super = $self->find_next_method_by_name($name);
    (defined $super)
        || confess "You cannot override '$name' because it has no super method";
    $self->add_method($name => Moose::Meta::Method::Overriden->wrap(sub {
        my @args = @_;
        no warnings 'redefine';
        if ($Moose::SUPER_SLOT{$_super_package}) {
            local *{$Moose::SUPER_SLOT{$_super_package}} = sub { $super->body->(@args) };
            return $method->(@args);
        } else {
            confess "Trying to call override modifier'd method without super()";
        }
    }));
}

sub add_augment_method_modifier {
    my ($self, $name, $method) = @_;
    (!$self->has_method($name))
        || confess "Cannot add an augment method if a local method is already present";
    my $super = $self->find_next_method_by_name($name);
    (defined $super)
        || confess "You cannot augment '$name' because it has no super method";
    my $_super_package = $super->package_name;
    # BUT!,... if this is an overriden method ....
    if ($super->isa('Moose::Meta::Method::Overriden')) {
        # we need to be sure that we actually
        # find the next method, which is not
        # an 'override' method, the reason is
        # that an 'override' method will not
        # be the one calling inner()
        my $real_super = $self->_find_next_method_by_name_which_is_not_overridden($name);
        $_super_package = $real_super->package_name;
    }
    $self->add_method($name => sub {
        my @args = @_;
        no warnings 'redefine';
        if ($Moose::INNER_SLOT{$_super_package}) {
            local *{$Moose::INNER_SLOT{$_super_package}} = sub {
                local *{$Moose::INNER_SLOT{$_super_package}} = sub {};
                $method->(@args);
            };
            return $super->body->(@args);
        }
        else {
            return $super->body->(@args);
        }
    });
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
sub _apply_all_roles { die "DEPRECATED" }

my %ANON_CLASSES;

sub _process_attribute {
    my $self    = shift;
    my $name    = shift;
    my %options = ((scalar @_ == 1 && ref($_[0]) eq 'HASH') ? %{$_[0]} : @_);

    if ($name =~ /^\+(.*)/) {
        return $self->_process_inherited_attribute($1, %options);
    }
    else {
        my $attr_metaclass_name;
        if ($options{metaclass}) {
            my $metaclass_name = $options{metaclass};
            eval {
                my $possible_full_name = 'Moose::Meta::Attribute::Custom::' . $metaclass_name;
                Class::MOP::load_class($possible_full_name);
                $metaclass_name = $possible_full_name->can('register_implementation')
                    ? $possible_full_name->register_implementation
                    : $possible_full_name;
            };
            if ($@) {
                Class::MOP::load_class($metaclass_name);
            }
            $attr_metaclass_name = $metaclass_name;
        }
        else {
            $attr_metaclass_name = $self->attribute_metaclass;
        }

        if ($options{traits}) {

            my $anon_role_key = join "|" => @{$options{traits}};

            my $class;
            if (exists $ANON_CLASSES{$anon_role_key} && defined $ANON_CLASSES{$anon_role_key}) {
                $class = $ANON_CLASSES{$anon_role_key};
            }
            else {
                $class = Moose::Meta::Class->create_anon_class(
                    superclasses => [ $attr_metaclass_name ]
                );
                $ANON_CLASSES{$anon_role_key} = $class;
                
                my @traits;
                foreach my $trait (@{$options{traits}}) {
                    eval {
                        my $possible_full_name = 'Moose::Meta::Attribute::Custom::Trait::' . $trait;
                        Class::MOP::load_class($possible_full_name);
                        push @traits => $possible_full_name->can('register_implementation')
                            ? $possible_full_name->register_implementation
                            : $possible_full_name;
                    };
                    if ($@) {
                        push @traits => $trait;
                    }
                }
                
                Moose::Util::apply_all_roles($class, @traits);
            }
            
            $attr_metaclass_name = $class->name;
        }

        return $attr_metaclass_name->new($name, %options);
    }
}

sub _process_inherited_attribute {
    my ($self, $attr_name, %options) = @_;
    my $inherited_attr = $self->find_attribute_by_name($attr_name);
    (defined $inherited_attr)
        || confess "Could not find an attribute by the name of '$attr_name' to inherit from";
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
       read_only   => [qw/superclasses/],
       cannot_call => [qw/
           add_method
           alias_method
           remove_method
           add_attribute
           remove_attribute
           add_package_symbol
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
       }
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

