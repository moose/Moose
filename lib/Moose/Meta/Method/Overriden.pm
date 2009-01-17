package Moose::Meta::Method::Overriden;

use strict;
use warnings;

our $VERSION   = '0.64';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method';

sub new {
    my ( $class, %args ) = @_;

    # the package can be overridden by roles
    # it is really more like body's compilation stash
    # this is where we need to override the definition of super() so that the
    # body of the code can call the right overridden version
    my $super_package = $args{package} || $args{class}->name;

    my $name = $args{name};

    my $super = $args{class}->find_next_method_by_name($name);

    (defined $super)
        || $class->throw_error("You cannot override '$name' because it has no super method", data => $name);

    my $super_body = $super->body;

    my $method = $args{method};

    my $body = sub {
        local $Moose::SUPER_PACKAGE = $super_package;
        local @Moose::SUPER_ARGS = @_;
        local $Moose::SUPER_BODY = $super_body;
        return $method->(@_);
    };

    # FIXME do we need this make sure this works for next::method?
    # subname "${super_package}::${name}", $method;

    # FIXME store additional attrs
    $class->wrap(
        $body,
        package_name => $args{class}->name,
        name         => $name
    );
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Method::Overriden - A Moose Method metaclass for overriden methods

=head1 DESCRIPTION

This class implements method overriding logic for the L<Moose> C<override> keyword.

This involves setting up C<super> for the overriding body, and dispatching to
the correct parent method upon its invocation.

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
