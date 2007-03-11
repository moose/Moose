package Moose::Meta::Method::Overriden;

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method';

1;

__END__

=pod

=head1 NAME

Moose::Meta::Method::Overriden - A Moose Method metaclass for overriden methods

=head1 DESCRIPTION

This is primarily used to tag methods created with the C<override> keyword. It 
is currently just a subclass of L<Moose::Meta::Method>. 

Later releases will likely encapsulate the C<super> behavior of overriden methods, 
rather than that being the responsibility of the class. But this is low priority
for now.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006, 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut