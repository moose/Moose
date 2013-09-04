package Moose::Error::Confess;

use strict;
use warnings;

use base qw(Moose::Error::Default);

sub new {
    my ( $self, @args ) = @_;
    $self->create_error_confess(@args);
}

sub _inline_new {
    my ( $self, %args ) = @_;

    my $depth = ($args{depth} || 0) - 1;
    return 'Moose::Error::Util::create_error_confess('
      . 'message => ' . $args{message} . ', '
      . 'depth   => ' . $depth         . ', '
  . ')';
}

__PACKAGE__->meta->make_immutable(
    inline_constructor => 0,
    inline_accessors   => 0,
);

1;

# ABSTRACT: Prefer C<confess>

__END__

=pod

=head1 SYNOPSIS

    # Metaclass definition must come before Moose is used.
    use metaclass (
        metaclass => 'Moose::Meta::Class',
        error_class => 'Moose::Error::Confess',
    );
    use Moose;
    # ...

=head1 DESCRIPTION

This error class uses L<Carp/confess> to raise errors generated in your
metaclass.

=cut



