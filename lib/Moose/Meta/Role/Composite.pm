package Moose::Meta::Role::Composite;

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';

our $VERSION   = '0.64';
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
        || Moose->throw_error("The list of roles must be instances of Moose::Meta::Role, not $_")
            foreach @{$params{roles}};
    # and the name is created from the
    # roles if one has not been provided
    $params{name} ||= (join "|" => map { $_->name } @{$params{roles}});
    $class->_new(\%params);
}

# This is largely a cope of what's in Moose::Meta::Role (itself
# largely a copy of Class::MOP::Class). However, we can't actually
# call add_package_symbol, because there's no package to which which
# add the symbol.
sub add_method {
    my ($self, $method_name, $method) = @_;
    (defined $method_name && $method_name)
    || Moose->throw_error("You must define a method name");

    my $body;
    if (blessed($method)) {
        $body = $method->body;
        if ($method->package_name ne $self->name) {
            $method = $method->clone(
                package_name => $self->name,
                name         => $method_name            
            ) if $method->can('clone');
        }
    }
    else {
        $body = $method;
        $method = $self->wrap_method_body( body => $body, name => $method_name );
    }

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

=item B<add_method>

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
