package Class::MOP::Instance;
our $VERSION = '2.2006';

use strict;
use warnings;

use Scalar::Util 'isweak', 'weaken', 'blessed';

use parent 'Class::MOP::Object';

# make this not a valid method name, to avoid (most) attribute conflicts
my $RESERVED_MOP_SLOT = '<<MOP>>';

sub BUILDARGS {
    my ($class, @args) = @_;

    if ( @args == 1 ) {
        unshift @args, "associated_metaclass";
    } elsif ( @args >= 2 && blessed($args[0]) && $args[0]->isa("Class::MOP::Class") ) {
        # compat mode
        my ( $meta, @attrs ) = @args;
        @args = ( associated_metaclass => $meta, attributes => \@attrs );
    }

    my %options = @args;
    # FIXME lazy_build
    $options{slots} ||= [ map { $_->slots } @{ $options{attributes} || [] } ];
    $options{slot_hash} = { map { $_ => undef } @{ $options{slots} } }; # FIXME lazy_build

    return \%options;
}

sub new {
    my $class = shift;
    my $options = $class->BUILDARGS(@_);

    # FIXME replace with a proper constructor
    my $instance = $class->_new(%$options);

    # FIXME weak_ref => 1,
    weaken($instance->{'associated_metaclass'});

    return $instance;
}

sub _new {
    my $class = shift;
    return Class::MOP::Class->initialize($class)->new_object(@_)
      if $class ne __PACKAGE__;

    my $params = @_ == 1 ? $_[0] : {@_};
    return bless {
        # NOTE:
        # I am not sure that it makes
        # sense to pass in the meta
        # The ideal would be to just
        # pass in the class name, but
        # that is placing too much of
        # an assumption on bless(),
        # which is *probably* a safe
        # assumption,.. but you can
        # never tell <:)
        'associated_metaclass' => $params->{associated_metaclass},
        'attributes'           => $params->{attributes},
        'slots'                => $params->{slots},
        'slot_hash'            => $params->{slot_hash},
    } => $class;
}

sub _class_name { $_[0]->{_class_name} ||= $_[0]->associated_metaclass->name }

sub create_instance {
    my $self = shift;
    bless {}, $self->_class_name;
}

sub clone_instance {
    my ($self, $instance) = @_;

    my $clone = $self->create_instance;
    for my $attr ($self->get_all_attributes) {
        next unless $attr->has_value($instance);
        for my $slot ($attr->slots) {
            my $val = $self->get_slot_value($instance, $slot);
            $self->set_slot_value($clone, $slot, $val);
            $self->weaken_slot_value($clone, $slot)
                if $self->slot_value_is_weak($instance, $slot);
        }
    }

    $self->_set_mop_slot($clone, $self->_get_mop_slot($instance))
        if $self->_has_mop_slot($instance);

    return $clone;
}

# operations on meta instance

sub get_all_slots {
    my $self = shift;
    return @{$self->{'slots'}};
}

sub get_all_attributes {
    my $self = shift;
    return @{$self->{attributes}};
}

sub is_valid_slot {
    my ($self, $slot_name) = @_;
    exists $self->{'slot_hash'}->{$slot_name};
}

# operations on created instances

sub get_slot_value {
    my ($self, $instance, $slot_name) = @_;
    $instance->{$slot_name};
}

sub set_slot_value {
    my ($self, $instance, $slot_name, $value) = @_;
    $instance->{$slot_name} = $value;
}

sub initialize_slot {
    my ($self, $instance, $slot_name) = @_;
    return;
}

sub deinitialize_slot {
    my ( $self, $instance, $slot_name ) = @_;
    delete $instance->{$slot_name};
}

sub initialize_all_slots {
    my ($self, $instance) = @_;
    foreach my $slot_name ($self->get_all_slots) {
        $self->initialize_slot($instance, $slot_name);
    }
}

sub deinitialize_all_slots {
    my ($self, $instance) = @_;
    foreach my $slot_name ($self->get_all_slots) {
        $self->deinitialize_slot($instance, $slot_name);
    }
}

sub is_slot_initialized {
    my ($self, $instance, $slot_name, $value) = @_;
    exists $instance->{$slot_name};
}

sub weaken_slot_value {
    my ($self, $instance, $slot_name) = @_;
    weaken $instance->{$slot_name};
}

sub slot_value_is_weak {
    my ($self, $instance, $slot_name) = @_;
    isweak $instance->{$slot_name};
}

sub strengthen_slot_value {
    my ($self, $instance, $slot_name) = @_;
    $self->set_slot_value($instance, $slot_name, $self->get_slot_value($instance, $slot_name));
}

sub rebless_instance_structure {
    my ($self, $instance, $metaclass) = @_;

    # we use $_[1] here because of t/cmop/rebless_overload.t regressions
    # on 5.8.8
    bless $_[1], $metaclass->name;
}

sub is_dependent_on_superclasses {
    return; # for meta instances that require updates on inherited slot changes
}

sub _get_mop_slot {
    my ($self, $instance) = @_;
    $self->get_slot_value($instance, $RESERVED_MOP_SLOT);
}

sub _has_mop_slot {
    my ($self, $instance) = @_;
    $self->is_slot_initialized($instance, $RESERVED_MOP_SLOT);
}

sub _set_mop_slot {
    my ($self, $instance, $value) = @_;
    $self->set_slot_value($instance, $RESERVED_MOP_SLOT, $value);
}

sub _clear_mop_slot {
    my ($self, $instance) = @_;
    $self->deinitialize_slot($instance, $RESERVED_MOP_SLOT);
}

# inlinable operation snippets

sub is_inlinable { 1 }

sub inline_create_instance {
    my ($self, $class_variable) = @_;
    'bless {} => ' . $class_variable;
}

sub inline_slot_access {
    my ($self, $instance, $slot_name) = @_;
    sprintf q[%s->{"%s"}], $instance, quotemeta($slot_name);
}

sub inline_get_is_lvalue { 1 }

sub inline_get_slot_value {
    my ($self, $instance, $slot_name) = @_;
    $self->inline_slot_access($instance, $slot_name);
}

sub inline_set_slot_value {
    my ($self, $instance, $slot_name, $value) = @_;
    $self->inline_slot_access($instance, $slot_name) . " = $value",
}

sub inline_initialize_slot {
    my ($self, $instance, $slot_name) = @_;
    return '';
}

sub inline_deinitialize_slot {
    my ($self, $instance, $slot_name) = @_;
    "delete " . $self->inline_slot_access($instance, $slot_name);
}
sub inline_is_slot_initialized {
    my ($self, $instance, $slot_name) = @_;
    "exists " . $self->inline_slot_access($instance, $slot_name);
}

sub inline_weaken_slot_value {
    my ($self, $instance, $slot_name) = @_;
    sprintf "Scalar::Util::weaken( %s )", $self->inline_slot_access($instance, $slot_name);
}

sub inline_strengthen_slot_value {
    my ($self, $instance, $slot_name) = @_;
    $self->inline_set_slot_value($instance, $slot_name, $self->inline_slot_access($instance, $slot_name));
}

sub inline_rebless_instance_structure {
    my ($self, $instance, $class_variable) = @_;
    "bless $instance => $class_variable";
}

sub _inline_get_mop_slot {
    my ($self, $instance) = @_;
    $self->inline_get_slot_value($instance, $RESERVED_MOP_SLOT);
}

sub _inline_set_mop_slot {
    my ($self, $instance, $value) = @_;
    $self->inline_set_slot_value($instance, $RESERVED_MOP_SLOT, $value);
}

sub _inline_clear_mop_slot {
    my ($self, $instance) = @_;
    $self->inline_deinitialize_slot($instance, $RESERVED_MOP_SLOT);
}

1;

# ABSTRACT: Instance Meta Object

__END__

=pod

=head1 DESCRIPTION

See the L<Moose::Meta::Instance> documentation for API details.

=cut
