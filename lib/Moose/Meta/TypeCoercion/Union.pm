
package Moose::Meta::TypeCoercion::Union;

use strict;
use warnings;
use metaclass;

use Carp         'confess';
use Scalar::Util 'blessed';

our $VERSION   = '0.52';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::TypeCoercion';

sub compile_type_coercion {
    my $self            = shift;
    my $type_constraint = $self->type_constraint;
    
    (blessed $type_constraint && $type_constraint->isa('Moose::Meta::TypeConstraint::Union'))
     || confess "You can only a Moose::Meta::TypeCoercion::Union for a " .
                "Moose::Meta::TypeConstraint::Union, not a $type_constraint";
    
    $self->_compiled_type_coercion(sub {
        my $value = shift;
        # go through all the type constraints 
        # in the union, and check em ...
        foreach my $type (@{$type_constraint->type_constraints}) {
            # if they have a coercion first
            if ($type->has_coercion) {    
                # then try to coerce them ...
                my $temp = $type->coerce($value);
                # and if they get something 
                # make sure it still fits within
                # the union type ...
                return $temp if $type_constraint->check($temp);
            }
        }
        return undef;    
    });
}

sub has_coercion_for_type { 0 }

sub add_type_coercions {
    confess "Cannot add additional type coercions to Union types";
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeCoercion::Union - The Moose Type Coercion metaclass for Unions

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

=item B<compile_type_coercion>

=item B<has_coercion_for_type>

=item B<add_type_coercions>

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
