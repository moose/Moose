package Moose::Meta::Role::Composite;

use strict;
use warnings;
use metaclass;

use Carp         'confess';
use Scalar::Util 'blessed';

our $VERSION   = '0.55_01';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Role';

# NOTE:
# we need to override the ->name 
# method from Class::MOP::Package
# since we don't have an actual 
# package for this.
# - SL
__PACKAGE__->meta->add_attribute('name' => (reader => 'name'));

# NOTE:
# Again, since we don't have a real 
# package to store our methods in, 
# we use a HASH ref instead. 
# - SL
__PACKAGE__->meta->add_attribute('methods' => (
    reader  => 'get_method_map',
    default => sub { {} }
));

sub new {
    my ($class, %params) = @_;
    # the roles param is required ...
    ($_->isa('Moose::Meta::Role'))
        || confess "The list of roles must be instances of Moose::Meta::Role, not $_"
            foreach @{$params{roles}};
    # and the name is created from the
    # roles if one has not been provided
    $params{name} ||= (join "|" => map { $_->name } @{$params{roles}});
    $class->_new(\%params);
}

# NOTE:
# we need to override this cause 
# we dont have that package I was
# talking about above.
# - SL
sub alias_method {
    my ($self, $method_name, $method) = @_;
    (defined $method_name && $method_name)
        || confess "You must define a method name";

    # make sure to bless the 
    # method if nessecary 
    $method = $self->method_metaclass->wrap(
        $method,
        package_name => $self->name,
        name         => $method_name
    ) if !blessed($method);

    $self->get_method_map->{$method_name} = $method;
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role::Composite - An object to represent the set of roles

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<new>

=item B<meta>

=item B<name>

=item B<get_method_map>

=item B<alias_method>

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
