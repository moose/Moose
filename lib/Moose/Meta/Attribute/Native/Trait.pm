
package Moose::Meta::Attribute::Native::Trait;
use Moose::Role;
use Moose::Util::TypeConstraints;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

requires '_helper_type';

# these next two are the possible methods you can use in the 'handles'
# map.

# provide a Class or Role which we can collect the method providers
# from

# or you can provide a HASH ref of anon subs yourself. This will also
# collect and store the methods from a method_provider as well
has 'method_constructors' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return +{} unless $self->has_method_provider;
        # or grab them from the role/class
        my $method_provider = $self->method_provider->meta;
        return +{
            map {
                $_ => $method_provider->get_method($_)
            } $method_provider->get_method_list
        };
    },
);

has '+default'         => ( required => 1 );
has '+type_constraint' => ( required => 1 );

# methods called prior to instantiation

before '_process_options' => sub {
    my ( $self, $name, $options ) = @_;

    $self->_check_helper_type( $options, $name );

    $options->{is} = $self->_default_is
        if ! exists $options->{is} && $self->can('_default_is');

    $options->{default} = $self->_default_default
        if ! exists $options->{default} && $self->can('_default_default');
};

sub _check_helper_type {
    my ( $self, $options, $name ) = @_;

    my $type = $self->_helper_type;

    $options->{isa} = $type
        unless exists $options->{isa};

    my $isa = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        $options->{isa} );

    ( $isa->is_a_type_of($type) )
        || confess
        "The type constraint for $name must be a subtype of $type but it's a $isa";
}

around '_canonicalize_handles' => sub {
    my $next    = shift;
    my $self    = shift;
    my $handles = $self->handles;

    return unless $handles;

    unless ( 'HASH' eq ref $handles ) {
        $self->throw_error(
            "The 'handles' option must be a HASH reference, not $handles" );
    }

    return map {
        my $to = $handles->{$_};
        $to = [$to] unless ref $to;
        $_ => $to
    } keys %$handles;
};

# methods called after instantiation

before 'install_accessors' => sub { (shift)->_check_handles_values };

sub _check_handles_values {
    my $self = shift;

    my $method_constructors = $self->method_constructors;

    my %handles = $self->_canonicalize_handles;

    for my $original_method ( values %handles ) {
        my $name = $original_method->[0];
        ( exists $method_constructors->{$name} )
            || confess "$name is an unsupported method type";
    }

}

around '_make_delegation_method' => sub {
    my $next = shift;
    my ( $self, $handle_name, $method_to_call ) = @_;

    my ( $name, @curried_args ) = @$method_to_call;

    my $method_constructors = $self->method_constructors;

    my $code = $method_constructors->{$name}->(
        $self,
        $self->get_read_method_ref,
        $self->get_write_method_ref,
    );

    return $next->(
        $self,
        $handle_name,
        sub {
            my $instance = shift;
            return $code->( $instance, @curried_args, @_ );
        },
    );
};

no Moose::Role;
no Moose::Util::TypeConstraints;

1;

__END__

=head1 NAME

Moose::Meta::Attribute::Native::Trait - Base role for helpers

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

Documentation for Moose native traits starts at L<Moose::Meta::Attribute Native>

=head1 AUTHORS

Yuval Kogman

Shawn M Moore

Jesse Luehrs

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
