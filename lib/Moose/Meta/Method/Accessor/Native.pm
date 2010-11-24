package Moose::Meta::Method::Accessor::Native;

use strict;
use warnings;

use Carp qw( confess );
use Scalar::Util qw( blessed weaken );

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

around new => sub {
    my $orig = shift;
    my $class   = shift;
    my %options = @_;

    exists $options{curried_arguments}
        || ( $options{curried_arguments} = [] );

    ( $options{curried_arguments}
            && ( 'ARRAY' eq ref $options{curried_arguments} ) )
        || confess
        'You must supply a curried_arguments which is an ARRAY reference';

    $options{definition_context} = $options{attribute}->definition_context;

    $options{accessor_type} = 'native';

    return $class->$orig(%options);
};

around _new => sub {
    shift;
    my $class = shift;
    my $options = @_ == 1 ? $_[0] : {@_};

    return bless $options, $class;
};

sub root_types { (shift)->{'root_types'} }

sub _initialize_body {
    my $self = shift;

    $self->{'body'} = $self->_eval_code( $self->_generate_method );

    return;
}

sub _inline_curried_arguments {
    my $self = shift;

    return q{} unless @{ $self->curried_arguments };

    return 'unshift @_, @curried;'
}

sub _inline_check_argument_count {
    my $self = shift;

    my $code = q{};

    if ( my $min = $self->_minimum_arguments ) {
        my $err_msg = sprintf(
            q{"Cannot call %s without at least %s argument%s"},
            $self->delegate_to_method,
            $min,
            ( $min == 1 ? q{} : 's' )
        );

        $code
            .= "\n"
            . $self->_inline_throw_error($err_msg)
            . " unless \@_ >= $min;";
    }

    if ( defined( my $max = $self->_maximum_arguments ) ) {
        my $err_msg = sprintf(
            q{"Cannot call %s with %s argument%s"},
            $self->delegate_to_method,
            ( $max ? "more than $max" : 'any' ),
            ( $max == 1 ? q{} : 's' )
        );

        $code
            .= "\n"
            . $self->_inline_throw_error($err_msg)
            . " if \@_ > $max;";
    }

    return $code;
}

sub _minimum_arguments { 0 }
sub _maximum_arguments { undef }

override _inline_get => sub {
    my ( $self, $instance ) = @_;

    return $self->_slot_access_can_be_inlined
        ? super()
        : "${instance}->\$reader";
};

override _inline_store => sub {
    my ( $self, $instance, $value ) = @_;

    return $self->_slot_access_can_be_inlined
        ? super()
        : "${instance}->\$writer($value)";
};

override _eval_environment => sub {
    my $self = shift;

    my $env = super();

    $env->{'@curried'} = $self->curried_arguments;

    return $env if $self->_slot_access_can_be_inlined;

    my $reader = $self->associated_attribute->get_read_method_ref;
    $reader = $reader->body if blessed $reader;

    $env->{'$reader'} = \$reader;

    my $writer = $self->associated_attribute->get_write_method_ref;
    $writer = $writer->body if blessed $writer;

    $env->{'$writer'} = \$writer;

    return $env;
};

sub _slot_access_can_be_inlined {
    my $self = shift;

    return $self->is_inline && $self->_instance_is_inlinable;
}

no Moose::Role;

1;
