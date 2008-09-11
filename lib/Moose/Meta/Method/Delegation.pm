
package Moose::Meta::Method::Delegation;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed', 'weaken';

our $VERSION   = '0.57';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method';


sub new {
    my $class   = shift;
    my %options = @_;

    (exists $options{attribute})
        || confess "You must supply an attribute to construct with";

    (blessed($options{attribute}) && $options{attribute}->isa('Moose::Meta::Attribute'))
        || confess "You must supply an attribute which is a 'Moose::Meta::Attribute' instance";

    ($options{package_name} && $options{name})
        || confess "You must supply the package_name and name parameters $Class::MOP::Method::UPGRADE_ERROR_TEXT";

    my $self = $class->_new(\%options);

    weaken($self->{'attribute'});

    return $self;
}

sub _new {
    my $class = shift;
    my $options = @_ == 1 ? $_[0] : {@_};

    return bless $options, $class;
}

sub associated_attribute { (shift)->{'attribute'} }

1;

__END__

=pod

=head1 NAME

Moose::Meta::Method::Delegation - A Moose Method metaclass for delegation methods

=head1 DESCRIPTION

This is a subclass of L<Moose::Meta::Method> for delegation
methods.

=head1 METHODS

=over 4

=item B<new (%options)>

This creates the method based on the criteria in C<%options>,
these options are:

=over 4

=item I<attribute>

This must be an instance of C<Moose::Meta::Attribute> which this
accessor is being generated for. This paramter is B<required>.

=back

=item B<associated_attribute>

Returns the attribute associated with this method.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Dave Rolsky E<lt>autarch@urth.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
