use strict;
use warnings;
package Moose::Meta::Attribute;
our $VERSION = '2.2006';

use B ();
use Scalar::Util 'blessed';
use List::Util 1.33 'any';
use Try::Tiny;
use overload     ();

use Moose::Deprecated;
use Moose::Meta::Method::Accessor;
use Moose::Meta::Method::Delegation;
use Moose::Util 'throw_exception';
use Moose::Util::TypeConstraints ();
use Class::MOP::MiniTrait;

use parent 'Class::MOP::Attribute', 'Moose::Meta::Mixin::AttributeCore';

use Carp 'confess';

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

__PACKAGE__->meta->add_attribute('traits' => (
    reader    => 'applied_traits',
    predicate => 'has_applied_traits',
    Class::MOP::_definition_context(),
));

__PACKAGE__->meta->add_attribute('role_attribute' => (
    reader    => 'role_attribute',
    predicate => 'has_role_attribute',
    Class::MOP::_definition_context(),
));

# we need to have a ->does method in here to
# more easily support traits, and the introspection
# of those traits. We extend the does check to look
# for metatrait aliases.
sub does {
    my ($self, $role_name) = @_;
    my $name = try {
        Moose::Util::resolve_metatrait_alias(Attribute => $role_name)
    };
    return 0 if !defined($name); # failed to load class
    return $self->Moose::Object::does($name);
}

sub _inline_throw_exception {
    my ( $self, $exception_type, $throw_args ) = @_;
    return 'die Module::Runtime::use_module("Moose::Exception::' . $exception_type . '")->new(' . ($throw_args || '') . ')';
}

sub new {
    my ($class, $name, %options) = @_;
    $class->_process_options($name, \%options) unless $options{__hack_no_process_options}; # used from clone()... YECHKKK FIXME ICKY YUCK GROSS

    delete $options{__hack_no_process_options};

    my %attrs =
        ( map { $_ => 1 }
          grep { defined }
          map { $_->init_arg() }
          $class->meta()->get_all_attributes()
        );

    my @bad = sort grep { ! $attrs{$_} }  keys %options;

    if (@bad)
    {
        my $s = @bad > 1 ? 's' : '';
        my $list = join "', '", @bad;

        my $package = $options{definition_context}{package};
        my $context = $options{definition_context}{context}
                   || 'attribute constructor';
        my $type = $options{definition_context}{type} || 'class';

        my $location = '';
        if (defined($package)) {
            $location = " in ";
            $location .= "$type " if $type;
            $location .= $package;
        }

        Carp::cluck "Found unknown argument$s '$list' in the $context for '$name'$location";
    }

    return $class->SUPER::new($name, %options);
}

sub interpolate_class_and_new {
    my $class = shift;
    my $name  = shift;

    throw_exception( MustPassEvenNumberOfAttributeOptions => attribute_name => $name,
                                                             options        => \@_
                   )
        if @_ % 2 == 1;

    my %args = @_;

    my ( $new_class, @traits ) = $class->interpolate_class(\%args);
    $new_class->new($name, %args, ( scalar(@traits) ? ( traits => \@traits ) : () ) );
}

sub interpolate_class {
    my ($class, $options) = @_;

    $class = ref($class) || $class;

    if ( my $metaclass_name = delete $options->{metaclass} ) {
        my $new_class = Moose::Util::resolve_metaclass_alias( Attribute => $metaclass_name );

        if ( $class ne $new_class ) {
            if ( $new_class->can("interpolate_class") ) {
                return $new_class->interpolate_class($options);
            } else {
                $class = $new_class;
            }
        }
    }

    my @traits;

    if (my $traits = $options->{traits}) {
        my $i = 0;
        my $has_foreign_options = 0;

        while ($i < @$traits) {
            my $trait = $traits->[$i++];
            next if ref($trait); # options to a trait we discarded

            $trait = Moose::Util::resolve_metatrait_alias(Attribute => $trait)
                  || $trait;

            next if $class->does($trait);

            push @traits, $trait;

            # are there options?
            if ($traits->[$i] && ref($traits->[$i])) {
                $has_foreign_options = 1
                    if any { $_ ne '-alias' && $_ ne '-excludes' } keys %{ $traits->[$i] };

                push @traits, $traits->[$i++];
            }
        }

        if (@traits) {
            my %options = (
                superclasses => [ $class ],
                roles        => [ @traits ],
            );

            if ($has_foreign_options) {
                $options{weaken} = 0;
            }
            else {
                $options{cache} = 1;
            }

            my $anon_class = Moose::Meta::Class->create_anon_class(%options);
            $class = $anon_class->name;
        }
    }

    return ( wantarray ? ( $class, @traits ) : $class );
}

# ...

# method-generating options shouldn't be overridden
sub illegal_options_for_inheritance {
    qw(reader writer accessor clearer predicate)
}

# NOTE/TODO
# This method *must* be able to handle
# Class::MOP::Attribute instances as
# well. Yes, I know that is wrong, but
# apparently we didn't realize it was
# doing that and now we have some code
# which is dependent on it. The real
# solution of course is to push this
# feature back up into Class::MOP::Attribute
# but I not right now, I am too lazy.
# However if you are reading this and
# looking for something to do,.. please
# be my guest.
# - stevan
sub clone_and_inherit_options {
    my ($self, %options) = @_;

    # NOTE:
    # we may want to extends a Class::MOP::Attribute
    # in which case we need to be able to use the
    # core set of legal options that have always
    # been here. But we allows Moose::Meta::Attribute
    # instances to changes them.
    # - SL
    my @illegal_options = $self->can('illegal_options_for_inheritance')
        ? $self->illegal_options_for_inheritance
        : ();

    my @found_illegal_options = grep { exists $options{$_} && exists $self->{$_} ? $_ : undef } @illegal_options;
    (scalar @found_illegal_options == 0)
        || throw_exception( IllegalInheritedOptions => illegal_options => \@found_illegal_options,
                                                       params          => \%options
                          );

    $self->_process_isa_option( $self->name, \%options );
    $self->_process_does_option( $self->name, \%options );

    # NOTE:
    # this doesn't apply to Class::MOP::Attributes,
    # so we can ignore it for them.
    # - SL
    if ($self->can('interpolate_class')) {
        ( $options{metaclass}, my @traits ) = $self->interpolate_class(\%options);

        my %seen;
        my @all_traits = grep { $seen{$_}++ } @{ $self->applied_traits || [] }, @traits;
        $options{traits} = \@all_traits if @all_traits;
    }

    # This method can be called on a CMOP::Attribute object, so we need to
    # make sure we can call this method.
    $self->_process_lazy_build_option( $self->name, \%options )
        if $self->can('_process_lazy_build_option');

    $self->clone(%options);
}

sub clone {
    my ( $self, %params ) = @_;

    my $class = delete $params{metaclass} || ref $self;

    my ( @init, @non_init );

    foreach my $attr ( grep { $_->has_value($self) } Class::MOP::class_of($self)->get_all_attributes ) {
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

sub _process_options {
    my ( $class, $name, $options ) = @_;

    $class->_process_is_option( $name, $options );
    $class->_process_isa_option( $name, $options );
    $class->_process_does_option( $name, $options );
    $class->_process_coerce_option( $name, $options );
    $class->_process_trigger_option( $name, $options );
    $class->_process_auto_deref_option( $name, $options );
    $class->_process_lazy_build_option( $name, $options );
    $class->_process_lazy_option( $name, $options );
    $class->_process_required_option( $name, $options );
}

sub _process_is_option {
    my ( $class, $name, $options ) = @_;

    return unless $options->{is};

    ### -------------------------
    ## is => ro, writer => _foo    # turns into (reader => foo, writer => _foo) as before
    ## is => rw, writer => _foo    # turns into (reader => foo, writer => _foo)
    ## is => rw, accessor => _foo  # turns into (accessor => _foo)
    ## is => ro, accessor => _foo  # error, accesor is rw
    ### -------------------------

    if ( $options->{is} eq 'ro' ) {
        throw_exception("AccessorMustReadWrite" => attribute_name => $name,
                                                   params         => $options,
                       )
            if exists $options->{accessor};
        $options->{reader} ||= $name;
    }
    elsif ( $options->{is} eq 'rw' ) {
        if ( ! $options->{accessor} ) {
            if ( $options->{writer}) {
                $options->{reader} ||= $name;
            }
            else {
                $options->{accessor} = $name;
            }
        }
    }
    elsif ( $options->{is} eq 'bare' ) {
        return;
        # do nothing, but don't complain (later) about missing methods
    }
    else {
        throw_exception( InvalidValueForIs => attribute_name => $name,
                                              params         => $options,
                       );
    }
}

sub _process_isa_option {
    my ( $class, $name, $options ) = @_;

    return unless exists $options->{isa};

    if ( exists $options->{does} ) {
        if ( try { $options->{isa}->can('does') } ) {
            ( $options->{isa}->does( $options->{does} ) )
                || throw_exception( IsaDoesNotDoTheRole => attribute_name => $name,
                                                           params         => $options,
                                  );
        }
        else {
            throw_exception( IsaLacksDoesMethod => attribute_name => $name,
                                                   params         => $options,
                           );
        }
    }

    # allow for anon-subtypes here ...
    #
    # There are a _lot_ of methods that we expect from TC objects, but
    # checking for a specific parent class via ->isa is gross, so we'll check
    # for at least one method.
    if ( blessed( $options->{isa} )
        && $options->{isa}->can('has_coercion') ) {

        $options->{type_constraint} = $options->{isa};
    }
    else {
        $options->{type_constraint}
            = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint(
            $options->{isa},
            { package_defined_in => $options->{definition_context}->{package} }
        );
    }
}

sub _process_does_option {
    my ( $class, $name, $options ) = @_;

    return unless exists $options->{does} && ! exists $options->{isa};

    # allow for anon-subtypes here ...
    if ( blessed( $options->{does} )
        && $options->{does}->can('has_coercion') ) {

        $options->{type_constraint} = $options->{does};
    }
    else {
        $options->{type_constraint}
            = Moose::Util::TypeConstraints::find_or_create_does_type_constraint(
            $options->{does},
            { package_defined_in => $options->{definition_context}->{package} }
        );
    }
}

sub _process_coerce_option {
    my ( $class, $name, $options ) = @_;

    return unless $options->{coerce};

    ( exists $options->{type_constraint} )
        || throw_exception( CoercionNeedsTypeConstraint => attribute_name => $name,
                                                           params         => $options,
                          );

    throw_exception( CannotCoerceAWeakRef => attribute_name => $name,
                                             params         => $options,
                   )
        if $options->{weak_ref};

    unless ( $options->{type_constraint}->has_coercion ) {
        my $type = $options->{type_constraint}->name;

        throw_exception( CannotCoerceAttributeWhichHasNoCoercion => attribute_name => $name,
                                                                    type_name      => $type,
                                                                    params         => $options
                       );
    }
}

sub _process_trigger_option {
    my ( $class, $name, $options ) = @_;

    return unless exists $options->{trigger};

    ( 'CODE' eq ref $options->{trigger} )
        || throw_exception( TriggerMustBeACodeRef => attribute_name => $name,
                                                     params         => $options,
                          );
}

sub _process_auto_deref_option {
    my ( $class, $name, $options ) = @_;

    return unless $options->{auto_deref};

    ( exists $options->{type_constraint} )
        || throw_exception( CannotAutoDerefWithoutIsa => attribute_name => $name,
                                                         params         => $options,
                          );

    ( $options->{type_constraint}->is_a_type_of('ArrayRef')
      || $options->{type_constraint}->is_a_type_of('HashRef') )
        || throw_exception( AutoDeRefNeedsArrayRefOrHashRef => attribute_name => $name,
                                                               params         => $options,
                          );
}

sub _process_lazy_build_option {
    my ( $class, $name, $options ) = @_;

    return unless $options->{lazy_build};

    throw_exception( CannotUseLazyBuildAndDefaultSimultaneously => attribute_name => $name,
                                                                   params         => $options,
                   )
        if exists $options->{default};

    $options->{lazy} = 1;
    $options->{builder} ||= "_build_${name}";

    if ( $name =~ /^_/ ) {
        $options->{clearer}   ||= "_clear${name}";
        $options->{predicate} ||= "_has${name}";
    }
    else {
        $options->{clearer}   ||= "clear_${name}";
        $options->{predicate} ||= "has_${name}";
    }
}

sub _process_lazy_option {
    my ( $class, $name, $options ) = @_;

    return unless $options->{lazy};

    ( exists $options->{default} || defined $options->{builder} )
        || throw_exception( LazyAttributeNeedsADefault => params         => $options,
                                                          attribute_name => $name,
                          );
}

sub _process_required_option {
    my ( $class, $name, $options ) = @_;

    if (
        $options->{required}
        && !(
            ( !exists $options->{init_arg} || defined $options->{init_arg} )
            || exists $options->{default}
            || defined $options->{builder}
        )
        ) {
        throw_exception( RequiredAttributeNeedsADefault => params         => $options,
                                                           attribute_name => $name,
                       );
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
        my $class_name = blessed( $instance );
        throw_exception(
            'AttributeIsRequired',
            attribute_name => $self->name,
            ( defined $init_arg ? ( attribute_init_arg => $init_arg ) : () ),
            class_name => $class_name,
            params     => $params,
            )
            if $self->is_required
            && !$self->has_default
            && !$self->has_builder;

        # if nothing was in the %params, we can use the
        # attribute's default value (if it has one)
        if ($self->has_default) {
            $val = $self->default($instance);
            $value_is_set = 1;
        }
        elsif ($self->has_builder) {
            $val = $self->_call_builder($instance);
            $value_is_set = 1;
        }
    }

    return unless $value_is_set;

    $val = $self->_coerce_and_verify( $val, $instance );

    $self->set_initial_value($instance, $val);

    if ( ref $val && $self->is_weak_ref ) {
        $self->_weaken_value($instance);
    }
}

sub _call_builder {
    my ( $self, $instance ) = @_;

    my $builder = $self->builder();

    return $instance->$builder()
        if $instance->can( $self->builder );

    throw_exception( BuilderDoesNotExist => instance  => $instance,
                                            attribute => $self,
                   );
}

## Slot management

sub _make_initializer_writer_callback {
    my $self = shift;
    my ($meta_instance, $instance, $slot_name) = @_;
    my $old_callback = $self->SUPER::_make_initializer_writer_callback(@_);
    return sub {
        $old_callback->($self->_coerce_and_verify($_[0], $instance));
    };
}

sub set_value {
    my ($self, $instance, @args) = @_;
    my $value = $args[0];

    my $attr_name = quotemeta($self->name);

    my $class_name = blessed( $instance );
    if ($self->is_required and not @args) {
        throw_exception(
            'AttributeIsRequired',
            attribute_name => $self->name,
            (
                defined $self->init_arg
                ? ( attribute_init_arg => $self->init_arg )
                : ()
            ),
            class_name => $class_name,
        );
    }

    $value = $self->_coerce_and_verify( $value, $instance );

    my @old;
    if ( $self->has_trigger && $self->has_value($instance) ) {
        @old = $self->get_value($instance, 'for trigger');
    }

    $self->SUPER::set_value($instance, $value);

    if ( ref $value && $self->is_weak_ref ) {
        $self->_weaken_value($instance);
    }

    if ($self->has_trigger) {
        $self->trigger->($instance, $value, @old);
    }
}

sub _inline_set_value {
    my $self = shift;
    my ($instance, $value, $tc, $coercion, $message, $for_constructor) = @_;

    my $old     = '@old';
    my $copy    = '$val';
    $tc       ||= '$type_constraint';
    $coercion ||= '$type_coercion';
    $message  ||= '$type_message';

    my @code;
    if ($self->_writer_value_needs_copy) {
        push @code, $self->_inline_copy_value($value, $copy);
        $value = $copy;
    }

    # constructors already handle required checks
    push @code, $self->_inline_check_required
        unless $for_constructor;

    push @code, $self->_inline_tc_code($value, $tc, $coercion, $message);

    # constructors do triggers all at once at the end
    push @code, $self->_inline_get_old_value_for_trigger($instance, $old)
        unless $for_constructor;

    push @code, (
        $self->SUPER::_inline_set_value($instance, $value),
        $self->_inline_weaken_value($instance, $value),
    );

    # constructors do triggers all at once at the end
    push @code, $self->_inline_trigger($instance, $value, $old)
        unless $for_constructor;

    return @code;
}

sub _writer_value_needs_copy {
    my $self = shift;
    return $self->should_coerce;
}

sub _inline_copy_value {
    my $self = shift;
    my ($value, $copy) = @_;

    return 'my ' . $copy . ' = ' . $value . ';'
}

sub _inline_check_required {
    my $self = shift;

    return unless $self->is_required;

    my $throw_params = sprintf( <<'EOF', quotemeta( $self->name ) );
attribute_name => "%s",
class_name     => $class_name,
EOF
    $throw_params .= sprintf(
        'attribute_init_arg => "%s",',
        quotemeta( $self->init_arg )
    ) if defined $self->init_arg;

    my $throw = $self->_inline_throw_exception(
        'AttributeIsRequired',
        $throw_params
    );

    return sprintf( <<'EOF', $throw );
if ( @_ < 2 ) {
    %s;
}
EOF
}

sub _inline_tc_code {
    my $self = shift;
    my ($value, $tc, $coercion, $message, $is_lazy) = @_;
    return (
        $self->_inline_check_coercion(
            $value, $tc, $coercion, $is_lazy,
        ),
        $self->_inline_check_constraint(
            $value, $tc, $message, $is_lazy,
        ),
    );
}

sub _inline_check_coercion {
    my $self = shift;
    my ($value, $tc, $coercion) = @_;

    return unless $self->should_coerce && $self->type_constraint->has_coercion;

    if ( $self->type_constraint->can_be_inlined ) {
        return (
            'if (! (' . $self->type_constraint->_inline_check($value) . ')) {',
                $value . ' = ' . $coercion . '->(' . $value . ');',
            '}',
        );
    }
    else {
        return (
            'if (!' . $tc . '->(' . $value . ')) {',
                $value . ' = ' . $coercion . '->(' . $value . ');',
            '}',
        );
    }
}

sub _inline_check_constraint {
    my $self = shift;
    my ($value, $tc, $message) = @_;

    return unless $self->has_type_constraint;

    my $attr_name = quotemeta($self->name);

    if ( $self->type_constraint->can_be_inlined ) {
        return (
            'if (! (' . $self->type_constraint->_inline_check($value) . ')) {',
                'my $msg = do { local $_ = ' . $value . '; '
                . $message . '->(' . $value . ');'
                . '};'.
                $self->_inline_throw_exception( ValidationFailedForInlineTypeConstraint =>
                                                'type_constraint_message => $msg , '.
                                                'class_name              => $class_name, '.
                                                'attribute_name          => "'.$attr_name.'",'.
                                                'value                   => '.$value
                ).';',
            '}',
        );
    }
    else {
        return (
            'if (!' . $tc . '->(' . $value . ')) {',
                'my $msg = do { local $_ = ' . $value . '; '
                . $message . '->(' . $value . ');'
                . '};'.
                $self->_inline_throw_exception( ValidationFailedForInlineTypeConstraint =>
                                                'type_constraint_message => $msg , '.
                                                'class_name              => $class_name, '.
                                                'attribute_name          => "'.$attr_name.'",'.
                                                'value                   => '.$value
                ).';',
            '}',
        );
    }
}

sub _inline_get_old_value_for_trigger {
    my $self = shift;
    my ($instance, $old) = @_;

    return unless $self->has_trigger;

    return (
        'my ' . $old . ' = ' . $self->_inline_instance_has($instance),
            '? ' . $self->_inline_instance_get($instance),
            ': ();',
    );
}

sub _inline_weaken_value {
    my $self = shift;
    my ($instance, $value) = @_;

    return unless $self->is_weak_ref;

    my $mi = $self->associated_class->get_meta_instance;
    return (
        $mi->inline_weaken_slot_value($instance, $self->name),
            'if ref ' . $value . ';',
    );
}

sub _inline_trigger {
    my $self = shift;
    my ($instance, $value, $old) = @_;

    return unless $self->has_trigger;

    return '$trigger->(' . $instance . ', ' . $value . ', ' . $old . ');';
}

sub _eval_environment {
    my $self = shift;

    my $env = { };

    $env->{'$trigger'} = \($self->trigger)
        if $self->has_trigger;
    $env->{'$attr_default'} = \($self->default)
        if $self->has_default;

    if ($self->has_type_constraint) {
        my $tc_obj = $self->type_constraint;

        $env->{'$type_constraint'} = \(
            $tc_obj->_compiled_type_constraint
        ) unless $tc_obj->can_be_inlined;
        # these two could probably get inlined versions too
        $env->{'$type_coercion'} = \(
            $tc_obj->coercion->_compiled_type_coercion
        ) if $tc_obj->has_coercion;
        $env->{'$type_message'} = \(
            $tc_obj->has_message ? $tc_obj->message : $tc_obj->_default_message
        );

        $env = { %$env, %{ $tc_obj->inline_environment } };
    }

    $env->{'$class_name'} = \($self->associated_class->name);

    # XXX ugh, fix these
    $env->{'$attr'} = \$self
        if $self->has_initializer && $self->is_lazy;
    # pretty sure this is only going to be closed over if you use a custom
    # error class at this point, but we should still get rid of this
    # at some point
    $env->{'$meta'} = \($self->associated_class);

    return $env;
}

sub _weaken_value {
    my ( $self, $instance ) = @_;

    my $meta_instance = Class::MOP::Class->initialize( blessed($instance) )
        ->get_meta_instance;

    $meta_instance->weaken_slot_value( $instance, $self->name );
}

sub get_value {
    my ($self, $instance, $for_trigger) = @_;

    if ($self->is_lazy) {
        unless ($self->has_value($instance)) {
            my $value;
            if ($self->has_default) {
                $value = $self->default($instance);
            } elsif ( $self->has_builder ) {
                $value = $self->_call_builder($instance);
            }

            $value = $self->_coerce_and_verify( $value, $instance );

            $self->set_initial_value($instance, $value);

            if ( ref $value && $self->is_weak_ref ) {
                $self->_weaken_value($instance);
            }
        }
    }

    if ( $self->should_auto_deref && ! $for_trigger ) {

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
            throw_exception( CannotAutoDereferenceTypeConstraint => type_name => $type_constraint->name,
                                                                    instance  => $instance,
                                                                    attribute => $self
                           );
        }

    }
    else {

        return $self->SUPER::get_value($instance);
    }
}

sub _inline_get_value {
    my $self = shift;
    my ($instance, $tc, $coercion, $message) = @_;

    my $slot_access = $self->_inline_instance_get($instance);
    $tc           ||= '$type_constraint';
    $coercion     ||= '$type_coercion';
    $message      ||= '$type_message';

    return (
        $self->_inline_check_lazy($instance, $tc, $coercion, $message),
        $self->_inline_return_auto_deref($slot_access),
    );
}

sub _inline_check_lazy {
    my $self = shift;
    my ($instance, $tc, $coercion, $message) = @_;

    return unless $self->is_lazy;

    my $slot_exists = $self->_inline_instance_has($instance);

    return (
        'if (!' . $slot_exists . ') {',
            $self->_inline_init_from_default($instance, '$default', $tc, $coercion, $message, 'lazy'),
        '}',
    );
}

sub _inline_init_from_default {
    my $self = shift;
    my ($instance, $default, $tc, $coercion, $message, $for_lazy) = @_;

    if (!($self->has_default || $self->has_builder)) {
        throw_exception( LazyAttributeNeedsADefault => attribute => $self );
    }

    return (
        $self->_inline_generate_default($instance, $default),
        # intentionally not using _inline_tc_code, since that can be overridden
        # to do things like possibly only do member tc checks, which isn't
        # appropriate for checking the result of a default
        $self->has_type_constraint
            ? ($self->_inline_check_coercion($default, $tc, $coercion, $for_lazy),
               $self->_inline_check_constraint($default, $tc, $message, $for_lazy))
            : (),
        $self->_inline_init_slot($instance, $default),
        $self->_inline_weaken_value($instance, $default),
    );
}

sub _inline_generate_default {
    my $self = shift;
    my ($instance, $default) = @_;

    if ($self->has_default) {
        my $source = 'my ' . $default . ' = $attr_default';
        $source .= '->(' . $instance . ')'
            if $self->is_default_a_coderef;
        return $source . ';';
    }
    elsif ($self->has_builder) {
        my $builder = B::perlstring($self->builder);
        my $builder_str = quotemeta($self->builder);
        my $attr_name_str = quotemeta($self->name);
        return (
            'my ' . $default . ';',
            'if (my $builder = ' . $instance . '->can(' . $builder . ')) {',
                $default . ' = ' . $instance . '->$builder;',
            '}',
            'else {',
                'my $class = ref(' . $instance . ') || ' . $instance . ';',
                $self->_inline_throw_exception(
                    BuilderMethodNotSupportedForInlineAttribute =>
                    'class_name     => $class,'.
                    'attribute_name => "'.$attr_name_str.'",'.
                    'instance       => '.$instance.','.
                    'builder        => "'.$builder_str.'"'
                ) . ';',
            '}',
        );
    }
    else {
        confess(
            "Can't generate a default for " . $self->name
          . " since no default or builder was specified"
        );
    }
}

sub _inline_init_slot {
    my $self = shift;
    my ($inv, $value) = @_;

    if ($self->has_initializer) {
        return '$attr->set_initial_value(' . $inv . ', ' . $value . ');';
    }
    else {
        return $self->_inline_instance_set($inv, $value) . ';';
    }
}

sub _inline_return_auto_deref {
    my $self = shift;

    return 'return ' . $self->_auto_deref(@_) . ';';
}

sub _auto_deref {
    my $self = shift;
    my ($ref_value) = @_;

    return $ref_value unless $self->should_auto_deref;

    my $type_constraint = $self->type_constraint;

    my $sigil;
    if ($type_constraint->is_a_type_of('ArrayRef')) {
        $sigil = '@';
    }
    elsif ($type_constraint->is_a_type_of('HashRef')) {
        $sigil = '%';
    }
    else {
        confess(
            'Can not auto de-reference the type constraint \''
          . $type_constraint->name
          . '\''
        );
    }

    return 'wantarray '
             . '? ' . $sigil . '{ (' . $ref_value . ') || return } '
             . ': (' . $ref_value . ')';
}

## installing accessors

sub accessor_metaclass { 'Moose::Meta::Method::Accessor' }

sub install_accessors {
    my $self = shift;
    $self->SUPER::install_accessors(@_);
    $self->install_delegation if $self->has_handles;
    return;
}

sub _check_associated_methods {
    my $self = shift;
    unless (
        @{ $self->associated_methods }
        || ($self->_is_metadata || '') eq 'bare'
    ) {
        Carp::cluck(
            'Attribute (' . $self->name . ') of class '
            . $self->associated_class->name
            . ' has no associated methods'
            . ' (did you mean to provide an "is" argument?)'
            . "\n"
        )
    }
}

sub _process_accessors {
    my $self = shift;
    my ($type, $accessor, $generate_as_inline_methods) = @_;

    $accessor = ( keys %$accessor )[0] if ( ref($accessor) || '' ) eq 'HASH';
    my $method = $self->associated_class->get_method($accessor);

    if (   $method
        && $method->isa('Class::MOP::Method::Accessor') ) {

        # This is a special case that is very unlikely to occur outside of the
        # Moose bootstrapping process. We do not want to warn if the method
        # we're about to replace is for this same attribute, _and_ we're
        # replacing a non-inline method with an inlined version.
        #
        # This would never occur in normal user code because Moose inlines all
        # accessors. However, Moose metaclasses are instances of
        # Class::MOP::Class, which _does not_ inline accessors by
        # default. However, in Class::MOP & Moose.pm, we iterate over all of
        # our internal metaclasses and make them immutable after they're fully
        # defined. This ends up replacing the attribute accessors.
        unless ( $method->associated_attribute->name eq $self->name
            && ( $generate_as_inline_methods && !$method->is_inline ) ) {

            my $other_attr = $method->associated_attribute;

            my $msg = sprintf(
                'You are overwriting a %s (%s) for the %s attribute',
                $method->accessor_type,
                $accessor,
                $other_attr->name,
            );

            if ( my $method_context = $method->definition_context ) {
                $msg .= sprintf(
                    ' (defined at %s line %s)',
                    $method_context->{file},
                    $method_context->{line},
                    )
                    if defined $method_context->{file}
                    && $method_context->{line};
            }

            $msg .= sprintf(
                ' with a new %s method for the %s attribute',
                $type,
                $self->name,
            );

            if ( my $self_context = $self->definition_context ) {
                $msg .= sprintf(
                    ' (defined at %s line %s)',
                    $self_context->{file},
                    $self_context->{line},
                    )
                    if defined $self_context->{file}
                    && $self_context->{line};
            }

            Carp::cluck($msg);
        }
    }

    if (
           $method
        && !$method->is_stub
        && !$method->isa('Class::MOP::Method::Accessor')
        && (  !$self->definition_context
            || $method->package_name eq $self->definition_context->{package} )
        ) {

        Carp::cluck(
            "You are overwriting a locally defined method ($accessor) with "
                . "an accessor" );
    }

    if (  !$self->associated_class->has_method($accessor)
        && $self->associated_class->has_package_symbol( '&' . $accessor ) ) {

        Carp::cluck(
            "You are overwriting a locally defined function ($accessor) with "
                . "an accessor" );
    }

    $self->SUPER::_process_accessors(@_);
}

sub remove_accessors {
    my $self = shift;
    $self->SUPER::remove_accessors(@_);
    $self->remove_delegation if $self->has_handles;
    return;
}

sub install_delegation {
    my $self = shift;

    # NOTE:
    # Here we canonicalize the 'handles' option
    # this will sort out any details and always
    # return an hash of methods which we want
    # to delegate to, see that method for details
    my %handles = $self->_canonicalize_handles;

    # install the delegation ...
    my $associated_class = $self->associated_class;
    my $class_name = $associated_class->name;

    foreach my $handle ( sort keys %handles ) {
        my $method_to_call = $handles{$handle};
        my $name           = "${class_name}::${handle}";

        if ( my $method = $associated_class->get_method($handle) ) {
            throw_exception(
                CannotDelegateLocalMethodIsPresent => attribute => $self,
                method                             => $method,
            ) unless $method->is_stub;
        }

        # NOTE:
        # handles is not allowed to delegate
        # any of these methods, as they will
        # override the ones in your class, which
        # is almost certainly not what you want.

        # FIXME warn when $handle was explicitly specified, but not if the source is a regex or something
        #cluck("Not delegating method '$handle' because it is a core method") and
        next
            if $class_name->isa("Moose::Object")
            and $handle =~ /^BUILD|DEMOLISH$/ || Moose::Object->can($handle);

        my $method = $self->_make_delegation_method($handle, $method_to_call);

        $self->associated_class->add_method($method->name, $method);
        $self->associate_method($method);
    }
}

sub remove_delegation {
    my $self = shift;
    my %handles = $self->_canonicalize_handles;
    my $associated_class = $self->associated_class;
    foreach my $handle (keys %handles) {
        next unless any { $handle eq $_ }
                    map { $_->name }
                    @{ $self->associated_methods };
        $self->associated_class->remove_method($handle);
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
                || throw_exception( CannotDelegateWithoutIsa => attribute => $self );
            return map  { ($_ => $_) }
                   grep { /$handles/ } $self->_get_delegate_method_list;
        }
        elsif ($handle_type eq 'CODE') {
            return $handles->($self, $self->_find_delegate_metaclass);
        }
        elsif (blessed($handles) && $handles->isa('Moose::Meta::TypeConstraint::DuckType')) {
            return map { $_ => $_ } @{ $handles->methods };
        }
        elsif (blessed($handles) && $handles->isa('Moose::Meta::TypeConstraint::Role')) {
            $handles = $handles->role;
        }
        else {
            throw_exception( UnableToCanonicalizeHandles => attribute => $self,
                                                            handles   => $handles
                           );
        }
    }

    Moose::Util::_load_user_class($handles);
    my $role_meta = Class::MOP::class_of($handles);

    (blessed $role_meta && $role_meta->isa('Moose::Meta::Role'))
        || throw_exception( UnableToCanonicalizeNonRolePackage => attribute => $self,
                                                                  handles   => $handles
                          );

    return map { $_ => $_ }
        map { $_->name }
        grep { !$_->isa('Class::MOP::Method::Meta') } (
        $role_meta->_get_local_methods,
        $role_meta->get_required_method_list,
        );
}

sub _get_delegate_method_list {
    my $self = shift;
    my $meta = $self->_find_delegate_metaclass;
    if ($meta->isa('Class::MOP::Class')) {
        return map  { $_->name }  # NOTE: !never! delegate &meta
               grep { $_->package_name ne 'Moose::Object' && !$_->isa('Class::MOP::Method::Meta') }
                    $meta->get_all_methods;
    }
    elsif ($meta->isa('Moose::Meta::Role')) {
        return $meta->get_method_list;
    }
    else {
        throw_exception( UnableToRecognizeDelegateMetaclass => attribute          => $self,
                                                               delegate_metaclass => $meta
                       );
    }
}

sub _find_delegate_metaclass {
    my $self = shift;
    my $class = $self->_isa_metadata;
    my $role = $self->_does_metadata;

    if ( $class ) {
        # make sure isa is actually a class
        unless ( $self->type_constraint->isa("Moose::Meta::TypeConstraint::Class") ) {
            throw_exception( DelegationToATypeWhichIsNotAClass => attribute => $self );
        }

        # make sure the class is loaded
        unless ( Moose::Util::_is_package_loaded($class) ) {
            throw_exception( DelegationToAClassWhichIsNotLoaded => attribute  => $self,
                                                                   class_name => $class
                           );
        }
        # we might be dealing with a non-Moose class,
        # and need to make our own metaclass. if there's
        # already a metaclass, it will be returned
        return Class::MOP::Class->initialize($class);
    }
    elsif ( $role ) {
        unless ( Moose::Util::_is_package_loaded($role) ) {
            throw_exception( DelegationToARoleWhichIsNotLoaded => attribute => $self,
                                                                  role_name => $role
                           );
        }

        return Class::MOP::class_of($role);
    }
    else {
        throw_exception( CannotFindDelegateMetaclass => attribute => $self );
    }
}

sub delegation_metaclass { 'Moose::Meta::Method::Delegation' }

sub _make_delegation_method {
    my ( $self, $handle_name, $method_to_call ) = @_;

    my @curried_arguments;

    ($method_to_call, @curried_arguments) = @$method_to_call
        if 'ARRAY' eq ref($method_to_call);

    return $self->delegation_metaclass->new(
        name               => $handle_name,
        package_name       => $self->associated_class->name,
        attribute          => $self,
        delegate_to_method => $method_to_call,
        curried_arguments  => \@curried_arguments,
    );
}

sub _coerce_and_verify {
    my $self     = shift;
    my $val      = shift;
    my $instance = shift;

    return $val unless $self->has_type_constraint;

    $val = $self->type_constraint->coerce($val)
        if $self->should_coerce && $self->type_constraint->has_coercion;

    $self->verify_against_type_constraint($val, instance => $instance);

    return $val;
}

sub verify_against_type_constraint {
    my $self = shift;
    my $val  = shift;

    return 1 if !$self->has_type_constraint;

    my $type_constraint = $self->type_constraint;

    $type_constraint->check($val)
        || throw_exception( ValidationFailedForTypeConstraint => type      => $type_constraint,
                                                                 value     => $val,
                                                                 attribute => $self,
                          );
}

package Moose::Meta::Attribute::Custom::Moose;
our $VERSION = '2.1403';

sub register_implementation { 'Moose::Meta::Attribute' }
1;

# ABSTRACT: The Moose attribute metaclass

__END__

=pod

=head1 SYNOPSIS

  $meta->add_attribute(
      Moose::Meta::Attribute->new(
          size => (
              is      => 'ro',
              default => 42,
          )
      )
  );

  $meta->add_attribute(
      Moose::Meta::Attribute->new(
          color => (
              is        => 'r2',
              predicate => '_has_color',
              clearer   => '_clear_color',
          )
      )
  );

=head1 DESCRIPTION

The Attribute Protocol is almost entirely an invention of C<Class::MOP>. Perl
5 does not have a consistent notion of attributes. There are so many ways in
which this is done, and very few (if any) are easily discoverable by this
module.

With that said, this module attempts to inject some order into this chaos, by
introducing a consistent API which can be used to create object attributes.

=head1 INHERITANCE

C<Moose::Meta::Attribute> is a subclass of L<Class::MOP::Attribute>. However,
all of the methods for both classes are documented here.

=head1 METHODS

This class provides the following methods

=head2 Creation

These methods can be used to create new attribute objects.

=head3 Moose::Meta::Attribute->new($name, ?%options)

An attribute must, at the very least, have a C<$name>. All other C<%options>
are added as key-value pairs.

=over 4

=item * is => 'ro', 'rw', 'bare'

This provides a shorthand for specifying the C<reader>, C<writer>, or
C<accessor> names. If the attribute is read-only ('ro') then it will
have a C<reader> method with the same attribute as the name.

If it is read-write ('rw') then it will have an C<accessor> method
with the same name. If you provide an explicit C<writer> for a
read-write attribute, then you will have a C<reader> with the same
name as the attribute, and a C<writer> with the name you provided.

Use 'bare' when you are deliberately not asking for any accessor, reader, or
write methods to be created with this attribute; otherwise, Moose will issue a
warning when this attribute is added to a metaclass. One common case for using
'bare' is when all of the methods associated with an attribute are being
created through the use of L<Moose::Meta::Attribute::Native> traits.

=item * required => $bool

An attribute which is required must be provided to the constructor.

Note that specifying both C<required> and a C<default> or C<builder> is
pointless, since the C<default> or C<builder> will guarantee that the
attribute is populated, regardless of whether it is specified as
C<required>. However, you can specify both without error.

=item * lazy => $bool

A lazy attribute must have a C<default> or C<builder>. When an
attribute is lazy, the default value will not be calculated until the
attribute is read.

=item * isa => $type

This option accepts a type. The type can be a string, which should be
a type name. If the type name is unknown, it is assumed to be a class
name.

This option can also accept a L<Moose::Meta::TypeConstraint> object.

If you I<also> provide a C<does> option, then your C<isa> option must
be a class name, and that class must do the role specified with
C<does>.

=item * does => $role

This is short-hand for saying that the attribute's type must be an
object which does the named role.

=item * coerce => $bool

This option is only valid for objects with a type constraint
(C<isa>) that defined a coercion. If this is true, then coercions will be applied whenever
this attribute is set.

You cannot make both this and the C<weak_ref> option true.

=item * init_arg

This is a string value representing the expected key in an
initialization hash. For instance, if we have an C<init_arg> value of
C<-foo>, then the following code will Just Work.

  MyClass->meta->new_object( -foo => 'Hello There' );

If an init_arg is not assigned, it will automatically use the
attribute's name. If C<init_arg> is explicitly set to C<undef>, the
attribute cannot be specified during initialization.

=item * builder

This provides the name of a method that will be called to initialize
the attribute. This method will be called on the object after it is
constructed. It is expected to return a valid value for the attribute.

=item * default

This can be used to provide an explicit default for initializing the
attribute. If the default you provide is a subroutine reference, then
this reference will be called I<as a method> on the object.

If the value is a simple scalar (string or number), then it can be
just passed as is. However, if you wish to initialize it with a HASH
or ARRAY ref, then you need to wrap that inside a subroutine
reference:

  Moose::Meta::Attribute->new(
      'foo' => (
          default => sub { [] },
      )
  );

  # or ...

  Moose::Meta::Attribute->new(
      'foo' => (
          default => sub { {} },
      )
  );

If you wish to initialize an attribute with a subroutine reference
itself, then you need to wrap that in a subroutine as well:

  Moose::Meta::Attribute->new(
      'foo' => (
          default => sub {
              sub { print "Hello World" }
          },
      )
  );

And lastly, if the value of your attribute is dependent upon some
other aspect of the instance structure, then you can take advantage of
the fact that when the C<default> value is called as a method:

  Moose::Meta::Attribute->new(
      'object_identity' => (
          default => sub { Scalar::Util::refaddr( $_[0] ) },
      )
  );

Note that there is no guarantee that attributes are initialized in any
particular order, so you cannot rely on the value of some other
attribute when generating the default.

=back

The C<accessor>, C<reader>, C<writer>, C<predicate> and C<clearer>
options all accept the same parameters. You can provide the name of
the method, in which case an appropriate default method will be
generated for you. Or instead you can also provide hash reference
containing exactly one key (the method name) and one value. The value
should be a subroutine reference, which will be installed as the
method itself.

=over 4

=item * accessor

An C<accessor> is a standard Perl-style read/write accessor. It will
return the value of the attribute, and if a value is passed as an
argument, it will assign that value to the attribute.

Note that C<undef> is a legitimate value, so this will work:

  $object->set_something(undef);

=item * reader

This is a basic read-only accessor. It returns the value of the
attribute.

=item * writer

This is a basic write accessor, it accepts a single argument, and
assigns that value to the attribute.

Note that C<undef> is a legitimate value, so this will work:

  $object->set_something(undef);

=item * predicate

The predicate method returns a boolean indicating whether or not the
attribute has been explicitly set.

Note that the predicate returns true even if the attribute was set to
a false value (C<0> or C<undef>).

=item * clearer

This method will uninitialize the attribute. After an attribute is
cleared, its C<predicate> will return false.

=item * definition_context

This option should be a hash reference containing several keys which
will be used when inlining the attribute's accessors. The keys should
include C<line>, the line number where the attribute was created, and
either C<file> or C<description>.

This information will ultimately be used when eval'ing inlined
accessor code so that error messages report a useful line and file
name.

=item * trigger => $sub

This option accepts a subroutine reference, which will be called after
the attribute is set.

=item * weak_ref => $bool

If this is true, the attribute's value will be stored as a weak
reference.

=item * documentation

An arbitrary string that can be retrieved later by calling C<<
$attr->documentation >>.

=item * auto_deref => $bool

B<Note that in cases where you want this feature you are often better served
by using a L<Moose::Meta::Attribute::Native> trait instead>.

If this is true, then the reader will dereference the value when it is
called. The attribute must have a type constraint which defines the
attribute as an array or hash reference.

=item * lazy_build => $bool

B<Note that use of this feature is strongly discouraged.> Some documentation
used to encourage use of this feature as a best practice, but we have changed
our minds.

Setting this to true makes the attribute lazy and provides a number of
default methods.

  has 'size' => (
      is         => 'ro',
      lazy_build => 1,
  );

is equivalent to this:

  has 'size' => (
      is        => 'ro',
      lazy      => 1,
      builder   => '_build_size',
      clearer   => 'clear_size',
      predicate => 'has_size',
  );


If your attribute name starts with an underscore (C<_>), then the clearer
and predicate will as well:

  has '_size' => (
      is         => 'ro',
      lazy_build => 1,
  );

becomes:

  has '_size' => (
      is        => 'ro',
      lazy      => 1,
      builder   => '_build__size',
      clearer   => '_clear_size',
      predicate => '_has_size',
  );

Note the doubled underscore in the builder name. Internally, Moose
simply prepends the attribute name with "_build_" to come up with the
builder name.

=item * role_attribute => $role_attribute

If provided, this should be a L<Moose::Meta::Role::Attribute> object.

=item * initializer

B<Note that this option comes from C<Class::MOP::Attribute>, which does not
allow for types and coercion. With Moose, you are probably better off using
those features instead.>

This option can be either a method name or a subroutine
reference. This method will be called when setting the attribute's
value in the constructor. Unlike C<default> and C<builder>, the
initializer is only called when a value is provided to the
constructor. The initializer allows you to munge this value during
object construction.

The initializer is called as a method with three arguments. The first
is the value that was passed to the constructor. The second is a
subroutine reference that can be called to actually set the
attribute's value, and the last is the associated
C<Moose::Meta::Attribute> object.

This contrived example shows an initializer that sets the attribute to
twice the given value.

  Moose::Meta::Attribute->new(
      'doubled' => (
          initializer => sub {
              my ( $self, $value, $set, $attr ) = @_;
              $set->( $value * 2 );
          },
      )
  );

Since an initializer can be a method name, you can easily make
attribute initialization use the writer:

  Moose::Meta::Attribute->new(
      'some_attr' => (
          writer      => 'some_attr',
          initializer => 'some_attr',
      )
  );

Your writer (actually, a wrapper around the writer, using
L<method modifications|Moose::Manual::MethodModifiers>) will need to examine
C<@_> and determine under which
context it is being called:

  around 'some_attr' => sub {
      my $orig = shift;
      my $self = shift;
      # $value is not defined if being called as a reader
      # $setter and $attr are only defined if being called as an initializer
      my ($value, $setter, $attr) = @_;

      # the reader behaves normally
      return $self->$orig if not @_;

      # mutate $value as desired
      # $value = <something($value);

      # if called as an initializer, set the value and we're done
      return $setter->($row) if $setter;

      # otherwise, call the real writer with the new value
      $self->$orig($row);
  };

=back

=head3 Moose::Meta::Class->interpolate_class_and_new($name, %options)

This is an alternate constructor that handles the C<metaclass> and
C<traits> options.

Effectively, this method is a factory that finds or creates the appropriate
class based on the given C<metaclass> and/or C<traits>.

Once it has found or created the appropriate class, it will call C<<
$class->new($name, %options) >> on that class.

=head3 $attr->clone(%options)

This creates a new attribute based on attribute being cloned. You must
supply a C<name> option to provide a new name for the attribute.

The C<%options> can only specify options handled by
L<Moose::Meta::Attribute>.

=head3 $attr->clone_and_inherit_options(%options)

This method supports the C<has '+foo'> feature. It does various bits
of processing on the supplied C<%options> before ultimately calling
the C<clone> method.

One of its main tasks is to make sure that the C<%options> provided
does not include the options returned by the
C<illegal_options_for_inheritance> method.

=head3 $attr->illegal_options_for_inheritance

This returns a blacklist of options that can not be overridden in a
subclass's attribute definition.

This exists to allow a custom metaclass to change or add to the list
of options which can not be changed.

=head2 Informational

These are all basic read-only accessors for the values passed into
the constructor.

=head3 $attr->name

Returns the attribute's name.

=head3 $attr->accessor, $attr->reader, $attr->writer, $attr->predicate, $attr->clearer

The C<accessor>, C<reader>, C<writer>, C<predicate>, and C<clearer> methods
all return exactly what was passed to the constructor, either a string
containing a method name or a hash reference.

=head3 $attr->has_accessor, $attr->has_reader, $attr->has_writer, $attr->has_predicate, $attr->has_clearer,

These return true or false.

=head3 $attr->init_arg

Returns the init_arg for this attribute. If none was specified when the
attribute was constructed, this will be the same as the attribute's name.

=head3 $attr->has_init_arg

This will be I<false> if the C<init_arg> was set to C<undef>.

=head3 $attr->builder

Returns the name of the builder sub

=head3 $attr->has_builder

This returns true or false.

=head3 $attr->default($instance)

The C<$instance> argument is optional. If you don't pass it, the
return value for this method is exactly what was passed to the
constructor, either a simple scalar or a subroutine reference.

If you I<do> pass an C<$instance> and the default is a subroutine
reference, then the reference is called as a method on the
C<$instance> and the generated value is returned.

=head3 $attr->has_default

This will be I<false> if the C<default> was set to C<undef>, since
C<undef> is the default C<default> anyway.

=head3 $attr->is_default_a_coderef

Returns true if the default is a subroutine reference.

=head3 $attr->type_constraint

Returns the L<Moose::Meta::TypeConstraint> object for this attribute,
if it has one.

=head3 $attr->has_type_constraint

Returns true or false.

=head3 $attr->handles

This returns the value of the C<handles> option passed to the
constructor.

=head3 $attr->has_handles

Returns true if this attribute performs delegation.

=head3 $attr->is_weak_ref

Returns true if this attribute stores its value as a weak reference.
=
head3 $attr->is_required

Returns true if this attribute is required to have a value.

=head3 $attr->is_lazy

Returns true if this attribute is lazy.

=head3 $attr->is_lazy_build

Returns true if the C<lazy_build> option was true when passed to the
constructor.

=head3 $attr->should_coerce

Returns true if the C<coerce> option passed to the constructor was
true.

=head3 $attr->should_auto_deref

Returns true if the C<auto_deref> option passed to the constructor was
true.

=head3 $attr->documentation

Returns the value that was in the C<documentation> option passed to
the constructor, if any.

=head3 $attr->has_documentation

Returns true if this attribute has any documentation.

=head3 $attr->trigger

This is the subroutine reference that was in the C<trigger> option
passed to the constructor, if any.

=head3 $attr->has_trigger

Returns true if this attribute has a trigger set.

=head3 $attr->does($role)

This indicates whether the I<attribute itself> does the given
role. The role can be given as a full class name, or as a resolvable
trait name.

Note that this checks the attribute itself, not its type constraint,
so it is checking the attribute's metaclass and any traits applied to
the attribute.

=head3 $attr->role_attribute

Returns the L<Moose::Meta::Role::Attribute> object from which this attribute
was created, if any. This may return C<undef>.

=head3 $attr->has_role_attribute

Returns true if this attribute has an associated role attribute.

=head3 $attr->applied_traits

This returns an array reference of all the traits which were applied
to this attribute. If none were applied, this returns C<undef>.

=head3 $attr->has_applied_traits

Returns true if this attribute has any traits applied.

=head3 $attr->slots

Return a list of slots required by the attribute. This is usually just
one, the name of the attribute.

A slot is the name of the hash key used to store the attribute in an
object instance.

=head3 $attr->get_read_method

=head3 $attr->get_write_method

Returns the name of a method suitable for reading or writing the value
of the attribute in the associated class.

If an attribute is read- or write-only, then these methods can return
C<undef> as appropriate.

=head3 $attr->has_read_method

=head3 $attr->has_write_method

This returns a boolean indicating whether the attribute has a I<named>
read or write method.

=head3 $attr->get_read_method_ref

=head3 $attr->get_write_method_ref

Returns the subroutine reference of a method suitable for reading or
writing the attribute's value in the associated class. These methods
always return a subroutine reference, regardless of whether or not the
attribute is read- or write-only.

=head3 $attr->insertion_order

If this attribute has been inserted into a class, this returns a zero
based index regarding the order of insertion.

=head3 $attr->has_insertion_order

This will be I<false> if this attribute has not be inserted into a class

=head3 $attr->initializer

Returns the initializer as passed to the constructor, so this may be
either a method name or a subroutine reference.

=head3 $attr->has_initializer

Returns true or false.

=head2 Value management

These methods are basically "back doors" to the instance, and can be
used to bypass the regular accessors but still stay within the MOP.

These methods are not for general use, and should only be used if you
really know what you are doing.

=head3 $attr->initialize_instance_slot($meta_instance, $instance, $params)

This method is used internally to initialize the attribute's slot in
the object C<$instance>.

The C<$params> is a hash reference of the values passed to the object
constructor.

It's unlikely that you'll need to call this method yourself.

=head3 $attr->set_value($instance, $value)

Sets the value without going through the accessor. Note that this
works even with read-only attributes.

Before setting the value, a check is made on the type constraint of the
attribute, if it has one, to see if the value passes it. If the value fails to
pass, the set operation dies.

Any coercion to convert values is done before checking the type constraint.

=head3 $attr->set_raw_value($instance, $value)

Sets the value with no side effects such as a trigger.

This doesn't actually apply to Class::MOP attributes, only to subclasses.

=head3 $attr->set_initial_value($instance, $value)

Sets the value without going through the accessor. This method is only
called when the instance is first being initialized.

=head3 $attr->get_value($instance)

Returns the value without going through the accessor. Note that this
works even with write-only accessors.

=head3 $attr->get_raw_value($instance)

Returns the value without any side effects such as lazy attributes.

Doesn't actually apply to Class::MOP attributes, only to subclasses.

=head3 $attr->has_value($instance)

Return a boolean indicating whether the attribute has been set in
C<$instance>. This how the default C<predicate> method works.

=head3 $attr->clear_value($instance)

This will clear the attribute's value in C<$instance>. This is what
the default C<clearer> calls.

Note that this works even if the attribute does not have any
associated read, write or clear methods.

=head3 $attr->verify_against_type_constraint($value)

Given a value, this method returns true if the value is valid for the
attribute's type constraint. If the value is not valid, it throws an
error.

=head2 Class association

These methods allow you to manage the attributes association with
the class that contains it. These methods should not be used
lightly, nor are they very magical, they are mostly used internally
and by metaclass instances.

=head3 $attr->associated_class

This returns the L<Class::MOP::Class> with which this attribute is
associated, if any.

=head3 $attr->attach_to_class($metaclass)

This method stores a weakened reference to the C<$metaclass> object
internally.

This method does not remove the attribute from its old class,
nor does it create any accessors in the new class.

It is probably best to use the L<Class::MOP::Class> C<add_attribute>
method instead.

=head3 $attr->detach_from_class

This method removes the associate metaclass object from the attribute
it has one.

This method does not remove the attribute itself from the class, or
remove its accessors.

It is probably best to use the L<Class::MOP::Class>
C<remove_attribute> method instead.

=head2 Attribute Accessor generation

These methods are used when generating accessors for an attribute. Typically,
this is done when the attribute is added to a class.

=head3 $attr->accessor_metaclass

Accessor methods are generated using an accessor metaclass. By default, this
is L<Moose::Meta::Method::Accessor>. This method returns the name of the
accessor metaclass that this attribute uses.

=head3 $attr->delegation_metaclass

Returns the delegation metaclass name, which defaults to
L<Moose::Meta::Method::Delegation>.

=head3 $attr->associate_method($method)

This associates a L<Class::MOP::Method> object with the
attribute. Typically, this is called internally when an attribute
generates its accessors.

=head3 $attr->associated_methods

This returns the list of methods which have been associated with the
attribute.

=head3 $attr->install_accessors

This method generates and installs code the attributes various accessors. It
is typically called from the L<Moose::Meta::Class> C<add_attribute> method.

If, after installing all methods, the attribute object has no associated
methods, it throws an error unless C<< is => 'bare' >> was passed to the
attribute constructor. (Trying to add an attribute that has no associated
methods is almost always an error.)

=head3 $attr->remove_accessors

This method removes all of the accessors associated with the
attribute.

This does not currently remove methods from the list returned by
C<associated_methods>.

=head3 $attr->inline_get($instance_var)

=head3 $attr->inline_has($instance_var)

=head3 $attr->inline_clear($instance_var)

These methods return a code snippet suitable for inlining the relevant
operation. They expect strings containing variable names to be used in the
inlining, like C<'$self'> or C<'$_[1]'>.

=head3 $attr->inline_set($instance_var, $value_var)

This method return a code snippet suitable for inlining the relevant
operation. It expect strings containing variable names to be used in the
inlining, like C<'$self'> or C<'$_[1]'>.

=head3 $attr->install_delegation

This method adds its delegation methods to the attribute's associated
class, if it has any to add.

=head3 $attr->remove_delegation

This method remove its delegation methods from the attribute's
associated class.

=head2 Moose::Meta::Attribute->meta

This will return a L<Class::MOP::Class> instance for this class.

It should also be noted that L<Class::MOP> will actually bootstrap
this module by installing a number of attribute meta-objects into its
metaclass.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
