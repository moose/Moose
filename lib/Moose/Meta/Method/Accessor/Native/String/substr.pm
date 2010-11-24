package Moose::Meta::Method::Accessor::Native::String::substr;

use strict;
use warnings;

use Moose::Util ();

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader' => {
    -excludes => [
        qw( _generate_method
            _minimum_arguments
            _maximum_arguments
            _inline_process_arguments
            _inline_check_arguments
            _return_value
            )
    ]
    },
    'Moose::Meta::Method::Accessor::Native::Writer' => {
    -excludes => [
        qw(
            _generate_method
            _minimum_arguments
            _maximum_arguments
            _inline_process_arguments
            _inline_check_arguments
            _inline_optimized_set_new_value
            _return_value
            )
    ]
    };

sub _generate_method {
    my $self = shift;

    my $inv = '$self';

    my $slot_access = $self->_inline_get($inv);

    my $code = 'sub {';

    $code .= "\n" . $self->_inline_pre_body(@_);
    $code .= "\n" . 'my $self = shift;';

    $code .= "\n" . $self->_inline_curried_arguments;

    $code .= "\n" . 'if ( @_ == 1 || @_ == 2 ) {';

    $code .= $self->_reader_core( $inv, $slot_access );

    $code .= "\n" . '} elsif ( @_ == 3 ) {';

    $code .= $self->_writer_core( $inv, $slot_access );

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
        . q{ unless $offset =~ /^-?\\d+$/;} . "\n"
        . $self->_inline_throw_error(
        q{'The second argument passed to substr must be an integer'})
        . q{ unless $length =~ /^-?\\d+$/;};

    if ($for_writer) {
        $code
            .= "\n"
            . $self->_inline_throw_error(
            q{'The third argument passed to substr must be a string'})
            . q{ unless Moose::Util::_STRINGLIKE0($replacement);};
    }

    return $code;
}

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return
        "( do { my \$potential = $slot_access; \@return = substr \$potential, \$offset, \$length, \$replacement; \$potential; } )";
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "\@return = substr $slot_access, \$offset, \$length, \$replacement";
}

sub _return_value {
    my ( $self, $slot_access, $for_writer ) = @_;

    return '$return[0]' if $for_writer;

    return "substr $slot_access, \$offset, \$length";
}

no Moose::Role;

1;
