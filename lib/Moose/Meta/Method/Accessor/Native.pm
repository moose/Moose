package Moose::Meta::Method::Accessor::Native;

use strict;
use warnings;

use Carp qw( confess );
use Scalar::Util qw( blessed weaken );

our $VERSION = '1.13';
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

sub _initialize_body {
    my $self = shift;

    $self->{'body'} = $self->_eval_code( $self->_generate_method );

    return;
}

1;
