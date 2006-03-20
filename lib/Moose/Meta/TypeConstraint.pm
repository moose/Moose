
package Moose::Meta::TypeConstraint;

use strict;
use warnings;
use metaclass;

Moose::Meta::TypeConstraint->meta->add_attribute(
    Class::MOP::Attribute->new('name' => (
        reader => 'name'
    ))	
);

Moose::Meta::TypeConstraint->meta->add_attribute(
    Class::MOP::Attribute->new('constraint_code' => (
        reader => 'constraint_code'
    ))	
);

Moose::Meta::TypeConstraint->meta->add_attribute(
    Class::MOP::Attribute->new('coercion_code' => (
        reader    => 'coercion_code',
        writer    => 'set_coercion_code',        
        predicate => 'has_coercion'
    ))	
);

sub new { return (shift)->meta->new_object(@_)  }

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint - The Moose Type Constraint metaobject

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<meta>

=item B<new>

=item B<name>

=item B<check>

=item B<coerce>

=item B<coercion_code>

=item B<set_coercion_code>

=item B<constraint_code>

=item B<has_coercion>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut