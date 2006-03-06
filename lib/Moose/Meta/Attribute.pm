
package Moose::Meta::Attribute;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Class::MOP::Attribute';

Moose::Meta::Attribute->meta->add_around_method_modifier('new' => sub {
	my $cont = shift;
    my ($class, $attribute_name, %options) = @_;
    
    # extract the init_arg
    my ($init_arg) = ($attribute_name =~ /^[\$\@\%][\.\:](.*)$/);     
    
    $cont->($class, $attribute_name, (init_arg => $init_arg, %options));
});


1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of my tests, below is the 
L<Devel::Cover> report on this module's test suite.

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut