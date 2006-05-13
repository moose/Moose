
package Moose::Object;

use strict;
use warnings;

use Moose::Meta::Class;
use metaclass 'Moose::Meta::Class';

use Carp 'confess';

our $VERSION = '0.06';

sub new {
    my $class = shift;
    my %params;
    if (scalar @_ == 1) {
        (ref($_[0]) eq 'HASH')
            || confess "Single parameters to new() must be a HASH ref";
        %params = %{$_[0]};
    }
    else {
        %params = @_;
    }
	my $self = $class->meta->new_object(%params);
	$self->BUILDALL(\%params);
	return $self;
}

sub BUILDALL {
	my ($self, $params) = @_;
	foreach my $method (reverse $self->meta->find_all_methods_by_name('BUILD')) {
		$method->{code}->($self, $params);
	}
}

sub DEMOLISHALL {
	my $self = shift;
	foreach my $method ($self->meta->find_all_methods_by_name('DEMOLISH')) {
		$method->{code}->($self);
	}	
}

sub DESTROY { goto &DEMOLISHALL }

# new does() methods will be created 
# as approiate see Moose::Meta::Role
sub does {
    my ($self, $role_name) = @_;
    (defined $role_name)
        || confess "You much supply a role name to does()";
    my $meta = $self->meta;
    foreach my $class ($meta->class_precedence_list) {
        return 1 
            if $meta->initialize($class)->does_role($role_name);            
    }
    return 0;   
}

1;

__END__

=pod

=head1 NAME

Moose::Object - The base object for Moose

=head1 DESCRIPTION

This serves as the base object for all Moose classes. Every 
effort will be made to ensure that all classes which C<use Moose> 
will inherit from this class. It provides a default constructor 
and destructor, which run all the BUILD and DEMOLISH methods in 
the class tree.

You don't actually I<need> to inherit from this in order to 
use Moose though. It is just here to make life easier.

=head1 METHODS

=over 4

=item B<meta>

This will return the metaclass associated with the given class.

=item B<new>

This will create a new instance and call C<BUILDALL>.

=item B<BUILDALL>

This will call every C<BUILD> method in the inheritance hierarchy, 
and pass it a hash-ref of the the C<%params> passed to C<new>.

=item B<DEMOLISHALL>

This will call every C<DEMOLISH> method in the inheritance hierarchy.

=item B<does ($role_name)>

This will check if the invocant's class C<does> a given C<$role_name>. 
This is similar to C<isa> for object, but it checks the roles instead.

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