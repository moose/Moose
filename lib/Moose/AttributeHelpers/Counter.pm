
package Moose::AttributeHelpers::Counter;
use Moose;

our $VERSION   = '0.19';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

extends 'Moose::Meta::Attribute';
with 'Moose::AttributeHelpers::Trait::Counter';

no Moose;

# register the alias ...
package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::Counter;
sub register_implementation { 'Moose::AttributeHelpers::Counter' }

1;

__END__

=pod

=head1 NAME

Moose::AttributeHelpers::Counter

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider>

=item B<has_method_provider>

=item B<helper_type>

=item B<process_options_for_handles>

Run before its superclass method.

=item B<check_handles_values>

Run after its superclass method.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

