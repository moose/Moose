package Moose::Meta::Role::Application::ToInstance;

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';
use List::MoreUtils 'all';

use base 'Moose::Meta::Role::Application';

__PACKAGE__->meta->add_attribute('rebless_params' => (
    reader  => 'rebless_params',
    default => sub { {} },
    Class::MOP::_definition_context(),
));

sub apply {
    my ( $self, $role, $object, $args ) = @_;

    my $obj_meta = Class::MOP::class_of($object) || 'Moose::Meta::Class';

    # This is a special case to handle the case where the object's metaclass
    # is a Class::MOP::Class, but _not_ a Moose::Meta::Class (for example,
    # when applying a role to a Moose::Meta::Attribute object).
    $obj_meta = 'Moose::Meta::Class'
        unless $obj_meta->isa('Moose::Meta::Class');

    my $class = $obj_meta->create_anon_class(
        superclasses => [ blessed($object) ],
        roles => [ $role, keys(%$args) ? ($args) : () ],
        cache => (all { $_ eq '-alias' || $_ eq '-excludes' } keys %$args),
    );

    $class->rebless_instance( $object, %{ $self->rebless_params } );
}

1;

# ABSTRACT: Compose a role into an instance

__END__

=pod

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<new>

=item B<meta>

=item B<apply>

=item B<rebless_params>

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut

