package Moose::Meta::TypeConstraint::Enum;

use strict;
use warnings;
use metaclass;

use Moose::Util::TypeConstraints ();

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute('values' => (
    accessor => 'values',
));

sub new {
    my ( $class, %args ) = @_;

    $args{parent} = Moose::Util::TypeConstraints::find_type_constraint('Str');

    if ( scalar @{ $args{values} } < 2 ) {
        require Moose;
        Moose->throw_error("You must have at least two values to enumerate through");
    }

    for (@{ $args{values} }) {
        if (!defined($_)) {
            require Moose;
            Moose->throw_error("Enum values must be strings, not undef");
        }
        elsif (ref($_)) {
            require Moose;
            Moose->throw_error("Enum values must be strings, not '$_'");
        }
    }

    my $self = $class->_new(\%args);

    $self->compile_type_constraint()
        unless $self->_has_compiled_type_constraint;

    return $self;
}

sub equals {
    my ( $self, $type_or_name ) = @_;

    my $other = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    return unless $other->isa(__PACKAGE__);

    my @self_values  = sort @{ $self->values };
    my @other_values = sort @{ $other->values };

    return unless @self_values == @other_values;

    while ( @self_values ) {
        my $value = shift @self_values;
        my $other_value = shift @other_values;

        return unless $value eq $other_value;
    }

    return 1;
}

sub constraint {
    my $self = shift;

    my %values = map { $_ => undef } @{ $self->values };

    return sub { exists $values{$_[0]} };
}

sub _compile_hand_optimized_type_constraint {
    my $self  = shift;

    my %values = map { $_ => undef } @{ $self->values };

    sub { defined($_[0]) && !ref($_[0]) && exists $values{$_[0]} };
}

sub create_child_type {
    my ($self, @args) = @_;
    return Moose::Meta::TypeConstraint->new(@args, parent => $self);
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint::Enum - Type constraint for enumerated values.

=head1 DESCRIPTION

This class represents type constraints based on an enumerated list of
acceptable values.

=head1 INHERITANCE

C<Moose::Meta::TypeConstraint::Enum> is a subclass of
L<Moose::Meta::TypeConstraint>.

=head1 METHODS

=over 4

=item B<< Moose::Meta::TypeConstraint::Enum->new(%options) >>

This creates a new enum type constraint based on the given
C<%options>.

It takes the same options as its parent, with several
exceptions. First, it requires an additional option, C<values>. This
should be an array reference containing a list of valid string
values. Second, it automatically sets the parent to the C<Str> type.

Finally, it ignores any provided C<constraint> option. The constraint
is generated automatically based on the provided C<values>.

=item B<< $constraint->values >>

Returns the array reference of acceptable values provided to the
constructor.

=item B<< $constraint->create_child_type >>

This returns a new L<Moose::Meta::TypeConstraint> object with the type
as its parent.

Note that it does I<not> return a C<Moose::Meta::TypeConstraint::Enum>
object!

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


