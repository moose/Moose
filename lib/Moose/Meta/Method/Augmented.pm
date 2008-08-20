package Moose::Meta::Method::Augmented;

use strict;
use warnings;

use Carp 'confess';

our $VERSION   = '0.55_01';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method';

sub new {
    my ( $class, %args ) = @_;

    # the package can be overridden by roles
    # it is really more like body's compilation stash
    # this is where we need to override the definition of super() so that the
    # body of the code can call the right overridden version
    my $name = $args{name};
    my $meta = $args{class};

    my $super = $meta->find_next_method_by_name($name);

    (defined $super)
        || confess "You cannot augment '$name' because it has no super method";

    my $_super_package = $super->package_name;
    # BUT!,... if this is an overriden method ....
    if ($super->isa('Moose::Meta::Method::Overriden')) {
        # we need to be sure that we actually
        # find the next method, which is not
        # an 'override' method, the reason is
        # that an 'override' method will not
        # be the one calling inner()
        my $real_super = $meta->_find_next_method_by_name_which_is_not_overridden($name);
        $_super_package = $real_super->package_name;
    }

    my $super_body = $super->body;

    my $method = $args{method};

    my $body = sub {
        local $Moose::INNER_ARGS{$_super_package} = [ @_ ];
        local $Moose::INNER_BODY{$_super_package} = $method;
        $super_body->(@_);
    };

    # FIXME store additional attrs
    $class->wrap(
        $body,
        package_name => $meta->name,
        name         => $name
    );
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Method::Augmented - A Moose Method metaclass for augmented methods

=head1 DESCRIPTION

This class implements method augmenting logic for the L<Moose> C<augment> keyword.

This involves setting up C<inner> for the superclass body, and dispatching to
the superclass from the normal body.

The subclass definition (the augmentation itself) will be invoked explicitly
using the C<inner> keyword from the parent class's method definition.

=head1 METHODS

=over 4

=item B<new>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
