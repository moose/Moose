
package Moose::Meta::Class;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'weaken';

our $VERSION = '0.02';

use base 'Class::MOP::Class';

sub construct_instance {
    my ($class, %params) = @_;
    my $instance = $params{'__INSTANCE__'} || {};
    foreach my $attr ($class->compute_all_applicable_attributes()) {
        my $init_arg = $attr->init_arg();
        # try to fetch the init arg from the %params ...
        my $val;        
        $val = $params{$init_arg} if exists $params{$init_arg};
        # if nothing was in the %params, we can use the 
        # attribute's default value (if it has one)
        $val ||= $attr->default($instance) if $attr->has_default; 
		if (defined $val) {
		    if ($attr->has_type_constraint) {
    		    if ($attr->should_coerce && $attr->type_constraint->has_coercion) {
    		        $val = $attr->type_constraint->coercion->coerce($val);
    		    }	
                (defined($attr->type_constraint->check($val))) 
                    || confess "Attribute (" . $attr->name . ") does not pass the type contraint with '$val'";			
            }
		}
        $instance->{$attr->name} = $val;
        if (defined $val && $attr->is_weak_ref) {
            weaken($instance->{$attr->name});
        }
    }
    return $instance;
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Class - The Moose metaclass

=head1 DESCRIPTION

This is a subclass of L<Class::MOP::Class> with Moose specific 
extensions.

For the most part, the only time you will ever encounter an 
instance of this class is if you are doing some serious deep 
introspection. To really understand this class, you need to refer 
to the L<Class::MOP::Class> documentation.

=head1 METHODS

=over 4

=item B<construct_instance>

This provides some Moose specific extensions to this method, you 
almost never call this method directly unless you really know what 
you are doing. 

This method makes sure to handle the moose weak-ref, type-constraint
and type coercion features. 

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