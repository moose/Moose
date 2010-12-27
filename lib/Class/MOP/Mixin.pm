package Class::MOP::Mixin;

use strict;
use warnings;

our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util 'blessed';

sub meta {
    require Class::MOP::Class;
    Class::MOP::Class->initialize( blessed( $_[0] ) || $_[0] );
}

1;

# ABSTRACT: Base class for mixin classes

__END__

=pod

=head1 DESCRIPTION

This class provides a single method shared by all mixins

=head1 METHODS

This class provides a few methods which are useful in all metaclasses.

=over 4

=item B<< Class::MOP::Mixin->meta >>

This returns a L<Class::MOP::Class> object for the mixin class.

=back

=cut
