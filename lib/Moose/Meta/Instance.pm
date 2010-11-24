
package Moose::Meta::Instance;

use strict;
use warnings;

our $VERSION   = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Class::MOP::MiniTrait;

use base "Class::MOP::Instance";

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

1;

__END__

=pod

=head1 NAME

Moose::Meta::Instance - The Moose Instance metaclass

=head1 SYNOPSIS

    # nothing to see here

=head1 DESCRIPTION

This class provides the low level data storage abstractions for
attributes.

Using this API directly in your own code violates encapsulation, and
we recommend that you use the appropriate APIs in
L<Moose::Meta::Class> and L<Moose::Meta::Attribute> instead. Those
APIs in turn call the methods in this class as appropriate.

At present, this is an empty subclass of L<Class::MOP::Instance>, so
you should see that class for all API details.

=head1 INHERITANCE

C<Moose::Meta::Instance> is a subclass of L<Class::MOP::Instance>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
