
package Moose::Meta::TypeConstraint;

use strict;
use warnings;
use metaclass;

use overload '""'     => sub { shift->name },   # stringify to tc name
             fallback => 1;

use Sub::Name    'subname';
use Carp         'confess';
use Scalar::Util 'blessed';

our $VERSION   = '0.11';
our $AUTHORITY = 'cpan:STEVAN';

__PACKAGE__->meta->add_attribute('name'       => (reader => 'name'));
__PACKAGE__->meta->add_attribute('parent'     => (
    reader    => 'parent',
    predicate => 'has_parent',
));
__PACKAGE__->meta->add_attribute('constraint' => (
    reader  => 'constraint',
    writer  => '_set_constraint',
    default => sub { sub { 1 } }
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
    my $self  = $class->meta->new_object(@_);
    $self->compile_type_constraint()
        unless $self->_has_compiled_type_constraint;
    return $self;
}

sub coerce   { ((shift)->coercion || confess "Cannot coerce without a type coercion")->coerce(@_) }
sub check    { $_[0]->_compiled_type_constraint->($_[1]) ? 1 : undef }
sub validate {
    my ($self, $value) = @_;
    if ($self->_compiled_type_constraint->($value)) {
        return undef;
    }
    else {
        if ($self->has_message) {
            local $_ = $value;
            return $self->message->($value);
        }
        else {
            return "Validation failed for '" . $self->name . "' failed";
        }
    }
}

## type predicates ...

sub is_a_type_of {
    my ($self, $type_name) = @_;
    ($self->name eq $type_name || $self->is_subtype_of($type_name));
}

sub is_subtype_of {
    my ($self, $type_name) = @_;
    my $current = $self;
    while (my $parent = $current->parent) {
        return 1 if $parent->name eq $type_name;
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
        || confess "Could not compile type constraint '"
                . $self->name
                . "' because no constraint check";

    return $self->_compile_subtype($check)
        if $self->has_parent;

    return $self->_compile_type($check);
}

sub _compile_hand_optimized_type_constraint {
    my $self = shift;

    my $type_constraint = $self->hand_optimized_type_constraint;

    confess unless ref $type_constraint;

    return $type_constraint;
}

sub _compile_subtype {
    my ($self, $check) = @_;

    # so we gather all the parents in order
    # and grab their constraints ...
    my @parents;
    foreach my $parent ($self->_collect_all_parents) {
        if ($parent->has_hand_optimized_type_constraint) {
            unshift @parents => $parent->hand_optimized_type_constraint;
            last;
        }
        else {
            unshift @parents => $parent->constraint;
        }
    }

    # then we compile them to run without
    # having to recurse as we did before
    return subname $self->name => sub {
        local $_ = $_[0];
        foreach my $parent (@parents) {
            return undef unless $parent->($_[0]);
        }
        return undef unless $check->($_[0]);
        1;
    };
}

sub _compile_type {
    my ($self, $check) = @_;
    return subname $self->name => sub {
        local $_ = $_[0];
        return undef unless $check->($_[0]);
        1;
    };
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

## this should get deprecated actually ...

sub union { die "DEPRECATED" }

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

=item B<is_a_type_of ($type_name)>

This checks the current type name, and if it does not match,
checks if it is a subtype of it.

=item B<is_subtype_of ($type_name)>

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

=item B<parent>

=item B<has_parent>

=item B<constraint>

=item B<has_message>

=item B<message>

=item B<has_coercion>

=item B<coercion>

=item B<hand_optimized_type_constraint>

=item B<has_hand_optimized_type_constraint>

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
