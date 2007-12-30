package Moose::Meta::Role::Application::ToInstance;

use strict;
use warnings;
use metaclass;

use Carp            'confess';
use Scalar::Util    'blessed';

use Data::Dumper;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Role::Application::ToClass';

my $anon_counter = 0;

sub apply {
    my ($self, $role, $object) = @_;

    # FIXME:
    # We really should do this better, and
    # cache the results of our efforts so
    # that we don't need to repeat them.

    my $pkg_name = __PACKAGE__ . "::__RUNTIME_ROLE_ANON_CLASS__::" . $anon_counter++;
    eval "package " . $pkg_name . "; our \$VERSION = '0.00';";
    die $@ if $@;

    my $class = Moose::Meta::Class->initialize($pkg_name);
    $class->superclasses(blessed($object));

    bless $object => $class->name;   
    
    $self->SUPER::apply($role, $class); 
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Role::Application::ToInstance

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<new>

=item B<meta>

=item B<apply>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006, 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

