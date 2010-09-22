package Moose::Meta::Method::Accessor::Native::String::substr;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base qw(
    Moose::Meta::Method::Accessor::Native::Reader
    Moose::Meta::Method::Accessor::Native::Writer
);

sub _generate_method {
    my $self = shift;

    my $inv = '$self';

    my $slot_access = $self->_inline_get($inv);

    my $code = 'sub {';

    $code .= "\n" . $self->_inline_pre_body(@_);
    $code .= "\n" . 'my $self = shift;';

    $code .= "\n" . $self->_inline_curried_arguments;

    $code .= "\n" . 'if ( @_ == 1 || @_ == 2 ) {';

    $code .= $self->_reader_core( $inv, $slot_access, @_ );

    $code .= "\n" . '} elsif ( @_ == 3 ) {';

    $code .= $self->_writer_core( $inv, $slot_access, @_ );

    $code .= "\n" . $self->_inline_post_body(@_);

    $code .= "\n" . '} else {';

    $code .= "\n" . $self->_inline_check_argument_count;

    $code .= "\n" . '}';
    $code .= "\n" . '}';

    return $code;
}

sub _minimum_arguments {1}
sub _maximum_arguments {3}

sub _inline_process_arguments {
    my ( $self, $inv, $slot_access ) = @_;

    return
          'my $offset = shift;' . "\n"
        . "my \$length = \@_ ? shift : length $slot_access;" . "\n"
        . 'my $replacement = shift;';
}

sub _inline_check_arguments {
    my ( $self, $for_writer ) = @_;

    my $code
        = $self->_inline_throw_error(
        q{'The first argument passed to substr must be an integer'})
        . q{ if ref $offset || $offset !~ /^-?\\d+$/;} . "\n"
        . $self->_inline_throw_error(
        q{'The second argument passed to substr must be a positive integer'})
        . q{ if ref $length || $offset !~ /^-?\\d+$/;};

    if ($for_writer) {
        $code
            .= "\n"
            . $self->_inline_throw_error(
            q{'The third argument passed to substr must be a string'})
            . q{ unless defined $replacement && ! ref $replacement;};
    }

    return $code;
}

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return
        "( do { my \$potential = $slot_access; substr \$potential, \$offset, \$length, \$replacement; \$potential; } )";
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "substr $slot_access, \$offset, \$length, \$replacement;";
}

sub _return_value {
    my ( $self, $slot_access, $for_writer ) = @_;

    return q{} if $for_writer;

    return "substr $slot_access, \$offset, \$length";
}

1;
