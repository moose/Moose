package Moose::Meta::Method::Accessor::Native;

use strict;
use warnings;

use Carp qw( confess );
use Scalar::Util qw( blessed weaken );

our $VERSION = '1.14';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor', 'Moose::Meta::Method::Delegation';

sub new {
    my $class   = shift;
    my %options = @_;

    die "Cannot instantiate a $class object directly"
        if $class eq __PACKAGE__;

    ( exists $options{attribute} )
        || confess "You must supply an attribute to construct with";

    ( blessed( $options{attribute} )
            && $options{attribute}->isa('Class::MOP::Attribute') )
        || confess
        "You must supply an attribute which is a 'Class::MOP::Attribute' instance";

    ( $options{package_name} && $options{name} )
        || confess "You must supply the package_name and name parameters";

    exists $options{curried_arguments}
        || ( $options{curried_arguments} = [] );

    ( $options{curried_arguments}
            && ( 'ARRAY' eq ref $options{curried_arguments} ) )
        || confess
        'You must supply a curried_arguments which is an ARRAY reference';

    $options{delegate_to_method} = lc( ( split /::/, $class)[-1] );

    $options{definition_context} = $options{attribute}->definition_context;

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

sub _inline_check_arguments { q{} }

sub _inline_get {
    my ( $self, $instance ) = @_;

    return $self->_slot_access_can_be_inlined
        ? $self->SUPER::_inline_get($instance)
        : "${instance}->\$reader";
}

sub _inline_store {
    my ( $self, $instance, $value ) = @_;

    return $self->_slot_access_can_be_inlined
        ? $self->SUPER::_inline_store( $instance, $value )
        : "${instance}->\$writer($value)";
}

sub _eval_environment {
    my $self = shift;

    my $env = $self->SUPER::_eval_environment(@_);

    $env->{'@curried'} = $self->curried_arguments;

    return $env if $self->_slot_access_can_be_inlined;

    my $reader = $self->associated_attribute->get_read_method_ref;
    $reader = $reader->body if blessed $reader;

    $env->{'$reader'} = \$reader;

    my $writer = $self->associated_attribute->get_write_method_ref;
    $writer = $writer->body if blessed $writer;

    $env->{'$writer'} = \$writer;

    return $env;
}

sub _slot_access_can_be_inlined {
    my $self = shift;

    return $self->is_inline && $self->_instance_is_inlinable;
}

1;
