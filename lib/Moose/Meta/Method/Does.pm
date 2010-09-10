package Moose::Meta::Method::Does;

use strict;
use warnings;

use Scalar::Util 'blessed', 'weaken', 'looks_like_number', 'refaddr';

our $VERSION   = '1.12';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Inlined';

sub new {
    my $class   = shift;
    my %options = @_;

    my $meta = $options{metaclass};

    ( ref $options{options} eq 'HASH' )
        || $class->throw_error( "You must pass a hash of options",
        data => $options{options} );

    $options{package_name}
        || $class->throw_error(
        "You must supply the package_name parameter" );

    my $self = bless {
        'body'                   => undef,
        'package_name'           => $options{package_name},
        'name'                   => 'does',
        'options'                => $options{options},
        'associated_metaclass'   => $meta,
        '_expected_method_class' => $options{_expected_method_class}
            || 'Moose::Object',
    } => $class;

    weaken( $self->{'associated_metaclass'} );

    $self->_initialize_body;

    return $self;
}

sub _initialize_body {
    my $self = shift;

    my $source = 'sub {';
    $source
        .= "\n"
        . 'defined $_[1] || '
        . $self->_inline_throw_error(
        q{"You must supply a role name to does()"});
    $source .= ";\n" . 'my $name = Scalar::Util::blessed( $_[1] ) ? $_[1]->name : $_[1]';
    $source .= ";\n" . 'return $does{$name} || 0';
    $source .= ";\n" . '}';

    my %does = map { $_->name => 1 }
        $self->associated_metaclass->calculate_all_roles_with_inheritance;

    my ( $code, $e ) = $self->_compile_code(
        code        => $source,
        environment => {
            '%does' => \%does,
            '$meta' => \$self,
        },
    );

    $self->throw_error(
        "Could not eval the does method :\n\n$source\n\nbecause :\n\n$e",
        error => $e,
        data  => $source,
    ) if $e;

    $self->{'body'} = $code;
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Method::Does - Method Meta Object for does

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Class::Generated> that provides
Moose-specific functionality for inlining does.

To understand this class, you should read the L<Class::MOP::Class::Generated>
documentation as well.

=head1 INHERITANCE

C<Moose::Meta::Method::Does> is a subclass of
L<Moose::Meta::Method> I<and> L<Class::MOP::Method::Generated>.

=head1 METHODS

=over 4

=item B<< Moose::Meta::Method::Does->new(%options) >>

This constructs a new object. It accepts the following options:

=over 8

=item * package_name

The package for the class in which the does is being inlined. This option is
required.

=item * metaclass

The metaclass for the class this does belongs to. This is optional, as it can
be set later by calling C<< $metamethod->attach_to_class >>.

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHORS

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

