package Moose::Meta::TypeConstraint::Enum;

use strict;
use warnings;
use metaclass;

use Moose::Util::TypeConstraints ();

our $VERSION   = '0.55_01';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute('values' => (
    accessor => 'values',
));

sub new {
    my ( $class, %args ) = @_;

    $args{parent} = Moose::Util::TypeConstraints::find_type_constraint('Str');

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

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint::Enum - Type constraint for enumerated values.

=head1 METHODS

=over 4

=item B<new>

=item B<equals>

=item B<constraint>

=item B<values>

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


