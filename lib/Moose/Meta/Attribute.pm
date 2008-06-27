
package Moose::Meta::Attribute;

use strict;
use warnings;

use Scalar::Util 'blessed', 'weaken';
use Carp         'confess';
use overload     ();

our $VERSION   = '0.52';
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Meta::Method::Accessor;
use Moose::Util ();
use Moose::Util::TypeConstraints ();

use base 'Class::MOP::Attribute';

# options which are not directly used
# but we store them for metadata purposes
__PACKAGE__->meta->add_attribute('isa'  => (reader    => '_isa_metadata'));
__PACKAGE__->meta->add_attribute('does' => (reader    => '_does_metadata'));
__PACKAGE__->meta->add_attribute('is'   => (reader    => '_is_metadata'));

# these are actual options for the attrs
__PACKAGE__->meta->add_attribute('required'   => (reader => 'is_required'      ));
__PACKAGE__->meta->add_attribute('lazy'       => (reader => 'is_lazy'          ));
__PACKAGE__->meta->add_attribute('lazy_build' => (reader => 'is_lazy_build'    ));
__PACKAGE__->meta->add_attribute('coerce'     => (reader => 'should_coerce'    ));
__PACKAGE__->meta->add_attribute('weak_ref'   => (reader => 'is_weak_ref'      ));
__PACKAGE__->meta->add_attribute('auto_deref' => (reader => 'should_auto_deref'));
__PACKAGE__->meta->add_attribute('type_constraint' => (
    reader    => 'type_constraint',
    predicate => 'has_type_constraint',
));
__PACKAGE__->meta->add_attribute('trigger' => (
    reader    => 'trigger',
    predicate => 'has_trigger',
));
__PACKAGE__->meta->add_attribute('handles' => (
    reader    => 'handles',
    predicate => 'has_handles',
));
__PACKAGE__->meta->add_attribute('documentation' => (
    reader    => 'documentation',
    predicate => 'has_documentation',
));
__PACKAGE__->meta->add_attribute('traits' => (
    reader    => 'applied_traits',
    predicate => 'has_applied_traits',
));

# we need to have a ->does method in here to 
# more easily support traits, and the introspection 
# of those traits. We extend the does check to look
# for metatrait aliases.
sub does {
    my ($self, $role_name) = @_;
    my $name = eval {
        Moose::Util::resolve_metatrait_alias(Attribute => $role_name)
    };
    return 0 if !defined($name); # failed to load class
    return Moose::Object::does($self, $name);
}

sub new {
    my ($class, $name, %options) = @_;
    $class->_process_options($name, \%options) unless $options{__hack_no_process_options}; # used from clone()... YECHKKK FIXME ICKY YUCK GROSS
    return $class->SUPER::new($name, %options);
}

sub interpolate_class_and_new {
    my ($class, $name, @args) = @_;

    my ( $new_class, @traits ) = $class->interpolate_class(@args);
    
    $new_class->new($name, @args, ( scalar(@traits) ? ( traits => \@traits ) : () ) );
}

sub interpolate_class {
    my ($class, %options) = @_;

    $class = ref($class) || $class;

    if ( my $metaclass_name = delete $options{metaclass} ) {
        my $new_class = Moose::Util::resolve_metaclass_alias( Attribute => $metaclass_name );
        
        if ( $class ne $new_class ) {
            if ( $new_class->can("interpolate_class") ) {
                return $new_class->interpolate_class(%options);
            } else {
                $class = $new_class;
            }
        }
    }

    my @traits;

    if (my $traits = $options{traits}) {
        if ( @traits = grep { not $class->does($_) } map {
            Moose::Util::resolve_metatrait_alias( Attribute => $_ )
                or
            $_
        } @$traits ) {
            my $anon_class = Moose::Meta::Class->create_anon_class(
                superclasses => [ $class ],
                roles        => [ @traits ],
                cache        => 1,
            );

            $class = $anon_class->name;
        }
    }

    return ( wantarray ? ( $class, @traits ) : $class );
}

sub clone_and_inherit_options {
    my ($self, %options) = @_;
    my %copy = %options;
    # you can change default, required, coerce, documentation, lazy, handles, builder, type_constraint (explicitly or using isa/does), metaclass and traits
    my %actual_options;
    foreach my $legal_option (qw(default coerce required documentation lazy handles builder type_constraint)) {
        if (exists $options{$legal_option}) {
            $actual_options{$legal_option} = $options{$legal_option};
            delete $options{$legal_option};
        }
    }

    if ($options{isa}) {
        my $type_constraint;
        if (blessed($options{isa}) && $options{isa}->isa('Moose::Meta::TypeConstraint')) {
            $type_constraint = $options{isa};
        }
        else {
            $type_constraint = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint($options{isa});
            (defined $type_constraint)
                || confess "Could not find the type constraint '" . $options{isa} . "'";
        }

        $actual_options{type_constraint} = $type_constraint;
        delete $options{isa};
    }
    
    if ($options{does}) {
        my $type_constraint;
        if (blessed($options{does}) && $options{does}->isa('Moose::Meta::TypeConstraint')) {
            $type_constraint = $options{does};
        }
        else {
            $type_constraint = Moose::Util::TypeConstraints::find_or_create_does_type_constraint($options{does});
            (defined $type_constraint)
                || confess "Could not find the type constraint '" . $options{does} . "'";
        }

        $actual_options{type_constraint} = $type_constraint;
        delete $options{does};
    }    

    # NOTE:
    # this doesn't apply to Class::MOP::Attributes, 
    # so we can ignore it for them.
    # - SL
    if ($self->can('interpolate_class')) {
        ( $actual_options{metaclass}, my @traits ) = $self->interpolate_class(%options);

        my %seen;
        my @all_traits = grep { $seen{$_}++ } @{ $self->applied_traits || [] }, @traits;
        $actual_options{traits} = \@all_traits if @all_traits;

        delete @options{qw(metaclass traits)};
    }

    (scalar keys %options == 0)
        || confess "Illegal inherited options => (" . (join ', ' => keys %options) . ")";


    $self->clone(%actual_options);
}

sub clone {
    my ( $self, %params ) = @_;

    my $class = $params{metaclass} || ref $self;

    if ( 0 and $class eq ref $self ) {
        return $self->SUPER::clone(%params);
    } else {
        my ( @init, @non_init );

        foreach my $attr ( grep { $_->has_value($self) } $self->meta->compute_all_applicable_attributes ) {
            push @{ $attr->has_init_arg ? \@init : \@non_init }, $attr;
        }

        my %new_params = ( ( map { $_->init_arg => $_->get_value($self) } @init ), %params );

        my $name = delete $new_params{name};

        my $clone = $class->new($name, %new_params, __hack_no_process_options => 1 );

        foreach my $attr ( @non_init ) {
            $attr->set_value($clone, $attr->get_value($self));
        }


        return $clone;
    }
}

sub _process_options {
    my ($class, $name, $options) = @_;

    if (exists $options->{is}) {

        ### -------------------------
        ## is => ro, writer => _foo    # turns into (reader => foo, writer => _foo) as before
        ## is => rw, writer => _foo    # turns into (reader => foo, writer => _foo)
        ## is => rw, accessor => _foo  # turns into (accessor => _foo)
        ## is => ro, accessor => _foo  # error, accesor is rw
        ### -------------------------
        
        if ($options->{is} eq 'ro') {
            confess "Cannot define an accessor name on a read-only attribute, accessors are read/write"
                if exists $options->{accessor};
            $options->{reader} ||= $name;
        }
        elsif ($options->{is} eq 'rw') {
            if ($options->{writer}) {
                $options->{reader} ||= $name;
            }
            else {
                $options->{accessor} ||= $name;
            }
        }
        else {
            confess "I do not understand this option (is => " . $options->{is} . ") on attribute ($name)"
        }
    }

    if (exists $options->{isa}) {
        if (exists $options->{does}) {
            if (eval { $options->{isa}->can('does') }) {
                ($options->{isa}->does($options->{does}))
                    || confess "Cannot have an isa option and a does option if the isa does not do the does on attribute ($name)";
            }
            else {
                confess "Cannot have an isa option which cannot ->does() on attribute ($name)";
            }
        }

        # allow for anon-subtypes here ...
        if (blessed($options->{isa}) && $options->{isa}->isa('Moose::Meta::TypeConstraint')) {
            $options->{type_constraint} = $options->{isa};
        }
        else {
            $options->{type_constraint} = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint($options->{isa});
        }
    }
    elsif (exists $options->{does}) {
        # allow for anon-subtypes here ...
        if (blessed($options->{does}) && $options->{does}->isa('Moose::Meta::TypeConstraint')) {
                $options->{type_constraint} = $options->{does};
        }
        else {
            $options->{type_constraint} = Moose::Util::TypeConstraints::find_or_create_does_type_constraint($options->{does});
        }
    }

    if (exists $options->{coerce} && $options->{coerce}) {
        (exists $options->{type_constraint})
            || confess "You cannot have coercion without specifying a type constraint on attribute ($name)";
        confess "You cannot have a weak reference to a coerced value on attribute ($name)"
            if $options->{weak_ref};
    }

    if (exists $options->{trigger}) {
        ('CODE' eq ref $options->{trigger})
            || confess "Trigger must be a CODE ref on attribute ($name)";
    }

    if (exists $options->{auto_deref} && $options->{auto_deref}) {
        (exists $options->{type_constraint})
            || confess "You cannot auto-dereference without specifying a type constraint on attribute ($name)";
        ($options->{type_constraint}->is_a_type_of('ArrayRef') ||
         $options->{type_constraint}->is_a_type_of('HashRef'))
            || confess "You cannot auto-dereference anything other than a ArrayRef or HashRef on attribute ($name)";
    }

    if (exists $options->{lazy_build} && $options->{lazy_build} == 1) {
        confess("You can not use lazy_build and default for the same attribute ($name)")
            if exists $options->{default};
        $options->{lazy}      = 1;
        $options->{required}  = 1;
        $options->{builder} ||= "_build_${name}";
        if ($name =~ /^_/) {
            $options->{clearer}   ||= "_clear${name}";
            $options->{predicate} ||= "_has${name}";
        } 
        else {
            $options->{clearer}   ||= "clear_${name}";
            $options->{predicate} ||= "has_${name}";
        }
    }

    if (exists $options->{lazy} && $options->{lazy}) {
        (exists $options->{default} || defined $options->{builder} )
            || confess "You cannot have lazy attribute ($name) without specifying a default value for it";
    }

    if ( $options->{required} && !( ( !exists $options->{init_arg} || defined $options->{init_arg} ) || exists $options->{default} || defined $options->{builder} ) ) {
        confess "You cannot have a required attribute ($name) without a default, builder, or an init_arg";
    }

}

sub initialize_instance_slot {
    my ($self, $meta_instance, $instance, $params) = @_;
    my $init_arg = $self->init_arg();
    # try to fetch the init arg from the %params ...

    my $val;
    my $value_is_set;
    if ( defined($init_arg) and exists $params->{$init_arg}) {
        $val = $params->{$init_arg};
        $value_is_set = 1;    
    }
    else {
        # skip it if it's lazy
        return if $self->is_lazy;
        # and die if it's required and doesn't have a default value
        confess "Attribute (" . $self->name . ") is required"
            if $self->is_required && !$self->has_default && !$self->has_builder;

        # if nothing was in the %params, we can use the
        # attribute's default value (if it has one)
        if ($self->has_default) {
            $val = $self->default($instance);
            $value_is_set = 1;
        } 
        elsif ($self->has_builder) {
            if (my $builder = $instance->can($self->builder)){
                $val = $instance->$builder;
                $value_is_set = 1;
            } 
            else {
                confess(blessed($instance)." does not support builder method '".$self->builder."' for attribute '" . $self->name . "'");
            }
        }
    }

    return unless $value_is_set;

    if ($self->has_type_constraint) {
        my $type_constraint = $self->type_constraint;
        if ($self->should_coerce && $type_constraint->has_coercion) {
            $val = $type_constraint->coerce($val);
        }
        $type_constraint->check($val)
            || confess "Attribute (" 
                     . $self->name 
                     . ") does not pass the type constraint because: " 
                     . $type_constraint->get_message($val);
    }

    $self->set_initial_value($instance, $val);
    $meta_instance->weaken_slot_value($instance, $self->name)
        if ref $val && $self->is_weak_ref;
}

## Slot management

# FIXME:
# this duplicates too much code from 
# Class::MOP::Attribute, we need to 
# refactor these bits eventually.
# - SL
sub _set_initial_slot_value {
    my ($self, $meta_instance, $instance, $value) = @_;

    my $slot_name = $self->name;

    return $meta_instance->set_slot_value($instance, $slot_name, $value)
        unless $self->has_initializer;

    my ($type_constraint, $can_coerce);
    if ($self->has_type_constraint) {
        $type_constraint = $self->type_constraint;
        $can_coerce      = ($self->should_coerce && $type_constraint->has_coercion);
    }

    my $callback = sub {
        my $val = shift;
        if ($type_constraint) {
            $val = $type_constraint->coerce($val)
                if $can_coerce;
            $type_constraint->check($val)
                || confess "Attribute (" 
                         . $slot_name 
                         . ") does not pass the type constraint because: " 
                         . $type_constraint->get_message($val);            
        }
        $meta_instance->set_slot_value($instance, $slot_name, $val);
    };
    
    my $initializer = $self->initializer;

    # most things will just want to set a value, so make it first arg
    $instance->$initializer($value, $callback, $self);
}

sub set_value {
    my ($self, $instance, @args) = @_;
    my $value = $args[0];

    my $attr_name = $self->name;

    if ($self->is_required and not @args) {
        confess "Attribute ($attr_name) is required";
    }

    if ($self->has_type_constraint) {

        my $type_constraint = $self->type_constraint;

        if ($self->should_coerce) {
            $value = $type_constraint->coerce($value);
        }        
        $type_constraint->_compiled_type_constraint->($value)
            || confess "Attribute (" 
                     . $self->name 
                     . ") does not pass the type constraint because " 
                     . $type_constraint->get_message($value);
    }

    my $meta_instance = Class::MOP::Class->initialize(blessed($instance))
                                         ->get_meta_instance;

    $meta_instance->set_slot_value($instance, $attr_name, $value);

    if (ref $value && $self->is_weak_ref) {
        $meta_instance->weaken_slot_value($instance, $attr_name);
    }

    if ($self->has_trigger) {
        $self->trigger->($instance, $value, $self);
    }
}

sub get_value {
    my ($self, $instance) = @_;

    if ($self->is_lazy) {
        unless ($self->has_value($instance)) {
            if ($self->has_default) {
                my $default = $self->default($instance);
                $self->set_initial_value($instance, $default);
            } elsif ( $self->has_builder ) {
                if (my $builder = $instance->can($self->builder)){
                    $self->set_initial_value($instance, $instance->$builder);
                }
                else {
                    confess(blessed($instance) 
                          . " does not support builder method '"
                          . $self->builder 
                          . "' for attribute '" 
                          . $self->name 
                          . "'");
                }
            } 
            else {
                $self->set_initial_value($instance, undef);
            }
        }
    }

    if ($self->should_auto_deref) {

        my $type_constraint = $self->type_constraint;

        if ($type_constraint->is_a_type_of('ArrayRef')) {
            my $rv = $self->SUPER::get_value($instance);
            return unless defined $rv;
            return wantarray ? @{ $rv } : $rv;
        }
        elsif ($type_constraint->is_a_type_of('HashRef')) {
            my $rv = $self->SUPER::get_value($instance);
            return unless defined $rv;
            return wantarray ? %{ $rv } : $rv;
        }
        else {
            confess "Can not auto de-reference the type constraint '" . $type_constraint->name . "'";
        }

    }
    else {

        return $self->SUPER::get_value($instance);
    }
}

## installing accessors

sub accessor_metaclass { 'Moose::Meta::Method::Accessor' }

sub install_accessors {
    my $self = shift;
    $self->SUPER::install_accessors(@_);
    $self->install_delegation if $self->has_handles;
    return;
}

sub install_delegation {
    my $self = shift;

    # NOTE:
    # Here we canonicalize the 'handles' option
    # this will sort out any details and always
    # return an hash of methods which we want
    # to delagate to, see that method for details
    my %handles = $self->_canonicalize_handles();

    # find the accessor method for this attribute
    my $accessor = $self->get_read_method_ref;
    # then unpack it if we need too ...
    $accessor = $accessor->body if blessed $accessor;

    # install the delegation ...
    my $associated_class = $self->associated_class;
    foreach my $handle (keys %handles) {
        my $method_to_call = $handles{$handle};
        my $class_name = $associated_class->name;
        my $name = "${class_name}::${handle}";

        (!$associated_class->has_method($handle))
            || confess "You cannot overwrite a locally defined method ($handle) with a delegation";

        # NOTE:
        # handles is not allowed to delegate
        # any of these methods, as they will
        # override the ones in your class, which
        # is almost certainly not what you want.

        # FIXME warn when $handle was explicitly specified, but not if the source is a regex or something
        #cluck("Not delegating method '$handle' because it is a core method") and
        next if $class_name->isa("Moose::Object") and $handle =~ /^BUILD|DEMOLISH$/ || Moose::Object->can($handle);

        if ('CODE' eq ref($method_to_call)) {
            $associated_class->add_method($handle => Class::MOP::subname($name, $method_to_call));
        }
        else {
            # NOTE:
            # we used to do a goto here, but the
            # goto didn't handle failure correctly
            # (it just returned nothing), so I took 
            # that out. However, the more I thought
            # about it, the less I liked it doing 
            # the goto, and I prefered the act of 
            # delegation being actually represented
            # in the stack trace. 
            # - SL
            $associated_class->add_method($handle => Class::MOP::subname($name, sub {
                my $proxy = (shift)->$accessor();
                (defined $proxy) 
                    || confess "Cannot delegate $handle to $method_to_call because " . 
                               "the value of " . $self->name . " is not defined";
                $proxy->$method_to_call(@_);
            }));
        }
    }    
}

# private methods to help delegation ...

sub _canonicalize_handles {
    my $self    = shift;
    my $handles = $self->handles;
    if (my $handle_type = ref($handles)) {
        if ($handle_type eq 'HASH') {
            return %{$handles};
        }
        elsif ($handle_type eq 'ARRAY') {
            return map { $_ => $_ } @{$handles};
        }
        elsif ($handle_type eq 'Regexp') {
            ($self->has_type_constraint)
                || confess "Cannot delegate methods based on a RegExpr without a type constraint (isa)";
            return map  { ($_ => $_) }
                   grep { /$handles/ } $self->_get_delegate_method_list;
        }
        elsif ($handle_type eq 'CODE') {
            return $handles->($self, $self->_find_delegate_metaclass);
        }
        else {
            confess "Unable to canonicalize the 'handles' option with $handles";
        }
    }
    else {
        my $role_meta = eval { $handles->meta };
        if ($@) {
            confess "Unable to canonicalize the 'handles' option with $handles because : $@";
        }

        (blessed $role_meta && $role_meta->isa('Moose::Meta::Role'))
            || confess "Unable to canonicalize the 'handles' option with $handles because ->meta is not a Moose::Meta::Role";

        return map { $_ => $_ } (
            $role_meta->get_method_list,
            $role_meta->get_required_method_list
        );
    }
}

sub _find_delegate_metaclass {
    my $self = shift;
    if (my $class = $self->_isa_metadata) {
        # if the class does have
        # a meta method, use it
        return $class->meta if $class->can('meta');
        # otherwise we might be
        # dealing with a non-Moose
        # class, and need to make
        # our own metaclass
        return Moose::Meta::Class->initialize($class);
    }
    elsif (my $role = $self->_does_metadata) {
        # our role will always have
        # a meta method
        return $role->meta;
    }
    else {
        confess "Cannot find delegate metaclass for attribute " . $self->name;
    }
}

sub _get_delegate_method_list {
    my $self = shift;
    my $meta = $self->_find_delegate_metaclass;
    if ($meta->isa('Class::MOP::Class')) {
        return map  { $_->{name}                     }  # NOTE: !never! delegate &meta
               grep { $_->{class} ne 'Moose::Object' && $_->{name} ne 'meta' }
                    $meta->compute_all_applicable_methods;
    }
    elsif ($meta->isa('Moose::Meta::Role')) {
        return $meta->get_method_list;
    }
    else {
        confess "Unable to recognize the delegate metaclass '$meta'";
    }
}

package Moose::Meta::Attribute::Custom::Moose;
sub register_implementation { 'Moose::Meta::Attribute' }

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute - The Moose attribute metaclass

=head1 DESCRIPTION

This is a subclass of L<Class::MOP::Attribute> with Moose specific
extensions.

For the most part, the only time you will ever encounter an
instance of this class is if you are doing some serious deep
introspection. To really understand this class, you need to refer
to the L<Class::MOP::Attribute> documentation.

=head1 METHODS

=head2 Overridden methods

These methods override methods in L<Class::MOP::Attribute> and add
Moose specific features. You can safely assume though that they
will behave just as L<Class::MOP::Attribute> does.

=over 4

=item B<new>

=item B<clone>

=item B<does>

=item B<initialize_instance_slot>

=item B<install_accessors>

=item B<install_delegation>

=item B<accessor_metaclass>

=item B<get_value>

=item B<set_value>

  eval { $point->meta->get_attribute('x')->set_value($point, 'fourty-two') };
  if($@) {
    print "Oops: $@\n";
  }

I<Attribute (x) does not pass the type constraint (Int) with 'fourty-two'>

Before setting the value, a check is made on the type constraint of
the attribute, if it has one, to see if the value passes it. If the
value fails to pass, the set operation dies with a L<Carp/confess>.

Any coercion to convert values is done before checking the type constraint.

To check a value against a type constraint before setting it, fetch the
attribute instance using L<Class::MOP::Class/find_attribute_by_name>,
fetch the type_constraint from the attribute using L<Moose::Meta::Attribute/type_constraint>
and call L<Moose::Meta::TypeConstraint/check>. See L<Moose::Cookbook::RecipeX>
for an example.

=back

=head2 Additional Moose features

Moose attributes support type-constraint checking, weak reference
creation and type coercion.

=over 4

=item B<interpolate_class_and_new>

=item B<interpolate_class>

When called as a class method causes interpretation of the C<metaclass> and
C<traits> options.

=item B<clone_and_inherit_options>

This is to support the C<has '+foo'> feature, it clones an attribute
from a superclass and allows a very specific set of changes to be made
to the attribute.

=item B<has_type_constraint>

Returns true if this meta-attribute has a type constraint.

=item B<type_constraint>

A read-only accessor for this meta-attribute's type constraint. For
more information on what you can do with this, see the documentation
for L<Moose::Meta::TypeConstraint>.

=item B<has_handles>

Returns true if this meta-attribute performs delegation.

=item B<handles>

This returns the value which was passed into the handles option.

=item B<is_weak_ref>

Returns true if this meta-attribute produces a weak reference.

=item B<is_required>

Returns true if this meta-attribute is required to have a value.

=item B<is_lazy>

Returns true if this meta-attribute should be initialized lazily.

NOTE: lazy attributes, B<must> have a C<default> or C<builder> field set.

=item B<is_lazy_build>

Returns true if this meta-attribute should be initialized lazily through
the builder generated by lazy_build. Using C<lazy_build =E<gt> 1> will
make your attribute required and lazy. In addition it will set the builder, clearer
and predicate options for you using the following convention.

   #If your attribute name starts with an underscore:
   has '_foo' => (lazy_build => 1);
   #is the same as
   has '_foo' => (lazy => 1, required => 1, predicate => '_has_foo', clearer => '_clear_foo', builder => '_build__foo);
   # or
   has '_foo' => (lazy => 1, required => 1, predicate => '_has_foo', clearer => '_clear_foo', default => sub{shift->_build__foo});

   #If your attribute name does not start with an underscore:
   has 'foo' => (lazy_build => 1);
   #is the same as
   has 'foo' => (lazy => 1, required => 1, predicate => 'has_foo', clearer => 'clear_foo', builder => '_build_foo);
   # or
   has 'foo' => (lazy => 1, required => 1, predicate => 'has_foo', clearer => 'clear_foo', default => sub{shift->_build_foo});

The reason for the different naming of the C<builder> is that the C<builder>
method is a private method while the C<clearer> and C<predicate> methods
are public methods.

NOTE: This means your class should provide a method whose name matches the value
of the builder part, in this case _build__foo or _build_foo.

=item B<should_coerce>

Returns true if this meta-attribute should perform type coercion.

=item B<should_auto_deref>

Returns true if this meta-attribute should perform automatic
auto-dereferencing.

NOTE: This can only be done for attributes whose type constraint is
either I<ArrayRef> or I<HashRef>.

=item B<has_trigger>

Returns true if this meta-attribute has a trigger set.

=item B<trigger>

This is a CODE reference which will be executed every time the
value of an attribute is assigned. The CODE ref will get two values,
the invocant and the new value. This can be used to handle I<basic>
bi-directional relations.

=item B<documentation>

This is a string which contains the documentation for this attribute.
It serves no direct purpose right now, but it might in the future
in some kind of automated documentation system perhaps.

=item B<has_documentation>

Returns true if this meta-attribute has any documentation.

=item B<applied_traits>

This will return the ARRAY ref of all the traits applied to this 
attribute, or if no traits have been applied, it returns C<undef>.

=item B<has_applied_traits>

Returns true if this meta-attribute has any traits applied.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
