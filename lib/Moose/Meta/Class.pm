
package Moose::Meta::Class;

use strict;
use warnings;

use Carp 'confess';

our $VERSION = '0.01';

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
		if (defined $val && $attr->has_type_constraint) {
			(defined $attr->type_constraint->($val))
				|| confess "Attribute (" . $attr->name . ") does not pass the type contraint";			
		}
        $instance->{$attr->name} = $val;
    }
    return $instance;
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Class - The Moose metaclass

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a subclass of L<Class::MOP::Class> with Moose specific 
extensions.

=head1 METHODS

=over 4

=item B<construct_instance>

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