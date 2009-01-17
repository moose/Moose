
package Moose::Meta::Method::Delegation;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed', 'weaken';

our $VERSION   = '0.64';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Generated';


sub new {
    my $class   = shift;
    my %options = @_;

    ( exists $options{attribute} )
        || confess "You must supply an attribute to construct with";

    ( blessed( $options{attribute} )
            && $options{attribute}->isa('Moose::Meta::Attribute') )
        || confess
        "You must supply an attribute which is a 'Moose::Meta::Attribute' instance";

    ( $options{package_name} && $options{name} )
        || confess
        "You must supply the package_name and name parameters $Class::MOP::Method::UPGRADE_ERROR_TEXT";

    ( $options{delegate_to_method} && ( !ref $options{delegate_to_method} )
            || ( 'CODE' eq ref $options{delegate_to_method} ) )
        || confess
        'You must supply a delegate_to_method which is a method name or a CODE reference';

    my $self = $class->_new( \%options );

    weaken( $self->{'attribute'} );

    $self->_initialize_body;

    return $self;
}

sub _new {
    my $class = shift;
    my $options = @_ == 1 ? $_[0] : {@_};

    return bless $options, $class;
}

sub associated_attribute { (shift)->{'attribute'} }

sub delegate_to_method { (shift)->{'delegate_to_method'} }

sub _initialize_body {
    my $self = shift;

    my $method_to_call = $self->delegate_to_method;
    return $self->{body} = $method_to_call
        if ref $method_to_call;

    my $accessor = $self->_get_delegate_accessor;

    my $handle_name = $self->name;

    # NOTE: we used to do a goto here, but the goto didn't handle
    # failure correctly (it just returned nothing), so I took that
    # out. However, the more I thought about it, the less I liked it
    # doing the goto, and I prefered the act of delegation being
    # actually represented in the stack trace.  - SL
    $self->{body} = sub {
        my $instance = shift;
        my $proxy    = $instance->$accessor();
        ( defined $proxy )
            || $self->throw_error(
            "Cannot delegate $handle_name to $method_to_call because "
                . "the value of "
                . $self->name
                . " is not defined",
            method_name => $method_to_call,
            object      => $instance
            );
        $proxy->$method_to_call(@_);
    };
}

sub _get_delegate_accessor {
    my $self = shift;

    my $accessor = $self->associated_attribute->get_read_method_ref;

    $accessor = $accessor->body if blessed $accessor;

    return $accessor;
}

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

=item I<delegate_to_method>

The method in the associated attribute's value to which we
delegate. This can be either a method name or a code reference.

=back

=item B<associated_attribute>

Returns the attribute associated with this method.

=item B<delegate_to_method>

Returns the method to which this method delegates.

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
