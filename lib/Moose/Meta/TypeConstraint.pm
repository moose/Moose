
package Moose::Meta::TypeConstraint;

use strict;
use warnings;
use metaclass;

use overload '""'     => sub { shift->name },   # stringify to tc name
             fallback => 1;

use Scalar::Util qw(blessed refaddr);

use base qw(Class::MOP::Object);

our $VERSION   = '0.64';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

__PACKAGE__->meta->add_attribute('name'       => (reader => 'name'));
__PACKAGE__->meta->add_attribute('parent'     => (
    reader    => 'parent',
    predicate => 'has_parent',
));

my $null_constraint = sub { 1 };
__PACKAGE__->meta->add_attribute('constraint' => (
    reader  => 'constraint',
    writer  => '_set_constraint',
    default => sub { $null_constraint }
));
__PACKAGE__->meta->add_attribute('message'   => (
    accessor  => 'message',
    predicate => 'has_message'
));
__PACKAGE__->meta->add_attribute('coercion'   => (
    accessor  => 'coercion',
    predicate => 'has_coercion'
));
__PACKAGE__->meta->add_attribute('hand_optimized_type_constraint' => (
    init_arg  => 'optimized',
    accessor  => 'hand_optimized_type_constraint',
    predicate => 'has_hand_optimized_type_constraint',
));

sub parents {
    my $self;
    $self->parent;
}

# private accessors

__PACKAGE__->meta->add_attribute('compiled_type_constraint' => (
    accessor  => '_compiled_type_constraint',
    predicate => '_has_compiled_type_constraint'
));
__PACKAGE__->meta->add_attribute('package_defined_in' => (
    accessor => '_package_defined_in'
));

sub new {
    my $class = shift;
    my ($first, @rest) = @_;
    my %args = ref $first ? %$first : $first ? ($first, @rest) : ();
    $args{name} = $args{name} ? "$args{name}" : "__ANON__";
    
    my $self  = $class->_new(%args);
    $self->compile_type_constraint()
        unless $self->_has_compiled_type_constraint;
    return $self;
}



sub coerce   { ((shift)->coercion || Moose->throw_error("Cannot coerce without a type coercion"))->coerce(@_) }

sub check {
    my ($self, @args) = @_;
    my $constraint_subref = $self->_compiled_type_constraint;
    return $constraint_subref->(@args) ? 1 : undef;
}

sub validate {
    my ($self, $value) = @_;
    if ($self->_compiled_type_constraint->($value)) {
        return undef;
    }
    else {
        $self->get_message($value);
    }
}

sub get_message {
    my ($self, $value) = @_;
    if (my $msg = $self->message) {
        local $_ = $value;
        return $msg->($value);
    }
    else {
        $value = (defined $value ? overload::StrVal($value) : 'undef');        
        return "Validation failed for '" . $self->name . "' failed with value $value";
    }    
}

## type predicates ...

sub equals {
    my ( $self, $type_or_name ) = @_;

    my $other = Moose::Util::TypeConstraints::find_type_constraint($type_or_name) or return;

    return 1 if refaddr($self) == refaddr($other);

    if ( $self->has_hand_optimized_type_constraint and $other->has_hand_optimized_type_constraint ) {
        return 1 if $self->hand_optimized_type_constraint == $other->hand_optimized_type_constraint;
    }

    return unless $self->constraint == $other->constraint;

    if ( $self->has_parent ) {
        return unless $other->has_parent;
        return unless $self->parent->equals( $other->parent );
    } else {
        return if $other->has_parent;
    }

    return 1;
}

sub is_a_type_of {
    my ($self, $type_or_name) = @_;

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name) or return;

    ($self->equals($type) || $self->is_subtype_of($type));
}

sub is_subtype_of {
    my ($self, $type_or_name) = @_;

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name) or return;

    my $current = $self;

    while (my $parent = $current->parent) {
        return 1 if $parent->equals($type);
        $current = $parent;
    }

    return 0;
}

## compiling the type constraint

sub compile_type_constraint {
    my $self = shift;
    $self->_compiled_type_constraint($self->_actually_compile_type_constraint);
}

## type compilers ...

sub _actually_compile_type_constraint {
    my $self = shift;

    return $self->_compile_hand_optimized_type_constraint
        if $self->has_hand_optimized_type_constraint;

    my $check = $self->constraint;
    (defined $check)
        || Moose->throw_error("Could not compile type constraint '"
                . $self->name
                . "' because no constraint check");

    return $self->_compile_subtype($check)
        if $self->has_parent;

    return $self->_compile_type($check);
}

sub _compile_hand_optimized_type_constraint {
    my $self = shift;

    my $type_constraint = $self->hand_optimized_type_constraint;

    Moose->throw_error("Hand optimized type constraint is not a code reference") unless ref $type_constraint;

    return $type_constraint;
}

sub _compile_subtype {
    my ($self, $check) = @_;

    # gather all the parent constraintss in order
    my @parents;
    my $optimized_parent;
    foreach my $parent ($self->_collect_all_parents) {
        # if a parent is optimized, the optimized constraint already includes
        # all of its parents tcs, so we can break the loop
        if ($parent->has_hand_optimized_type_constraint) {
            push @parents => $optimized_parent = $parent->hand_optimized_type_constraint;
            last;
        }
        else {
            push @parents => $parent->constraint;
        }
    }

    @parents = grep { $_ != $null_constraint } reverse @parents;

    unless ( @parents ) {
        return $self->_compile_type($check);
    } elsif( $optimized_parent and @parents == 1 ) {
        # the case of just one optimized parent is optimized to prevent
        # looping and the unnecessary localization
        if ( $check == $null_constraint ) {
            return $optimized_parent;
        } else {
            return Class::MOP::subname($self->name, sub {
                return undef unless $optimized_parent->($_[0]);
                my (@args) = @_;
                local $_ = $args[0];
                $check->(@args);
            });
        }
    } else {
        # general case, check all the constraints, from the first parent to ourselves
        my @checks = @parents;
        push @checks, $check if $check != $null_constraint;
        return Class::MOP::subname($self->name => sub {
            my (@args) = @_;
            local $_ = $args[0];
            foreach my $check (@checks) {
                return undef unless $check->(@args);
            }
            return 1;
        });
    }
}

sub _compile_type {
    my ($self, $check) = @_;

    return $check if $check == $null_constraint; # Item, Any

    return Class::MOP::subname($self->name => sub {
        my (@args) = @_;
        local $_ = $args[0];
        $check->(@args);
    });
}

## other utils ...

sub _collect_all_parents {
    my $self = shift;
    my @parents;
    my $current = $self->parent;
    while (defined $current) {
        push @parents => $current;
        $current = $current->parent;
    }
    return @parents;
}

sub create_child_type {
    my ($self, %opts) = @_;
    my $class = ref $self;
    return $class->new(%opts, parent => $self);
}

## this should get deprecated actually ...

sub union { Carp::croak "DEPRECATED" }

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint - The Moose Type Constraint metaclass

=head1 DESCRIPTION

For the most part, the only time you will ever encounter an
instance of this class is if you are doing some serious deep
introspection. This API should not be considered final, but
it is B<highly unlikely> that this will matter to a regular
Moose user.

If you wish to use features at this depth, please come to the
#moose IRC channel on irc.perl.org and we can talk :)

=head1 METHODS

=over 4

=item B<meta>

=item B<new>

=item B<equals ($type_name_or_object)>

This checks the current type against the supplied type (only).
Returns false if the two types are not equal. It also returns false if
you provide the type as a name, and the type name isn't found in the
type registry.

=item B<is_a_type_of ($type_name_or_object)>

This checks the current type against the supplied type, or if the
current type is a sub-type of the type name or object supplied. It
also returns false if you provide the type as a name, and the type
name isn't found in the type registry.

=item B<is_subtype_of ($type_name_or_object)>

This checks the current type is a sub-type of the type name or object
supplied. It also returns false if you provide the type as a name, and
the type name isn't found in the type registry.

=item B<compile_type_constraint>

=item B<coerce ($value)>

This will apply the type-coercion if applicable.

=item B<check ($value)>

This method will return a true (C<1>) if the C<$value> passes the
constraint, and false (C<0>) otherwise.

=item B<validate ($value)>

This method is similar to C<check>, but it deals with the error
message. If the C<$value> passes the constraint, C<undef> will be
returned. If the C<$value> does B<not> pass the constraint, then
the C<message> will be used to construct a custom error message.

=item B<name>

The name of the type in the global type registry.

=item B<parent>

This type's parent type.

=item B<has_parent>

Returns true if this type has a parent type.

=item B<parents>

Synonym for C<parent>.

=item B<constraint>

Returns this type's constraint.  This is the value of C<where> provided
when defining a type.

=item B<has_message>

Returns true if this type has a message.

=item B<message>

Returns this type's message.

=item B<get_message ($value)>

Generate message for $value.

=item B<has_coercion>

Returns true if this type has a coercion.

=item B<coercion>

Returns this type's L<Moose::Meta::TypeCoercion> if one exists.

=item B<hand_optimized_type_constraint>

=item B<has_hand_optimized_type_constraint>

=item B<create_child_type>

=back

=head2 DEPRECATED METHOD

=over 4

=item B<union>

This was just bad idea on my part,.. use the L<Moose::Meta::TypeConstraint::Union>
itself instead.

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
