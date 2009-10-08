package Moose::Error::Default;

use strict;
use warnings;

our $VERSION   = '0.92';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Carp::Heavy;

# this list is generated using
# ack -h --output "\$1" "package\s+((?:Class::MOP|Moose)::[\\w:]+)" lib | grep -v '::Custom::' | sort -u

$Carp::Internal{$_}++ for qw(
    Class::MOP::Attribute
    Class::MOP::Class
    Class::MOP::Class::Immutable::Trait
    Class::MOP::Deprecated
    Class::MOP::Instance
    Class::MOP::Method
    Class::MOP::Method::Accessor
    Class::MOP::Method::Constructor
    Class::MOP::Method::Generated
    Class::MOP::Method::Inlined
    Class::MOP::Method::Wrapped
    Class::MOP::Module
    Class::MOP::Object
    Class::MOP::Package

    Moose::Error::Confess
    Moose::Error::Croak
    Moose::Error::Default
    Moose::Exporter
    Moose::Meta::Attribute
    Moose::Meta::Attribute::Native
    Moose::Meta::Attribute::Native::MethodProvider::Array
    Moose::Meta::Attribute::Native::MethodProvider::Bool
    Moose::Meta::Attribute::Native::MethodProvider::Code
    Moose::Meta::Attribute::Native::MethodProvider::Counter
    Moose::Meta::Attribute::Native::MethodProvider::Hash
    Moose::Meta::Attribute::Native::MethodProvider::String
    Moose::Meta::Attribute::Native::Trait
    Moose::Meta::Attribute::Native::Trait::Array
    Moose::Meta::Attribute::Native::Trait::Bool
    Moose::Meta::Attribute::Native::Trait::Code
    Moose::Meta::Attribute::Native::Trait::Counter
    Moose::Meta::Attribute::Native::Trait::Hash
    Moose::Meta::Attribute::Native::Trait::Number
    Moose::Meta::Attribute::Native::Trait::String
    Moose::Meta::Class
    Moose::Meta::Class::Immutable::Trait
    Moose::Meta::Instance
    Moose::Meta::Method
    Moose::Meta::Method::Accessor
    Moose::Meta::Method::Augmented
    Moose::Meta::Method::Constructor
    Moose::Meta::Method::Delegation
    Moose::Meta::Method::Destructor
    Moose::Meta::Method::Overridden
    Moose::Meta::Role
    Moose::Meta::Role::Application
    Moose::Meta::Role::Application::RoleSummation
    Moose::Meta::Role::Application::ToClass
    Moose::Meta::Role::Application::ToInstance
    Moose::Meta::Role::Application::ToRole
    Moose::Meta::Role::Composite
    Moose::Meta::Role::Method
    Moose::Meta::Role::Method::Conflicting
    Moose::Meta::Role::Method::Required
    Moose::Meta::TypeCoercion
    Moose::Meta::TypeCoercion::Union
    Moose::Meta::TypeConstraint
    Moose::Meta::TypeConstraint::Class
    Moose::Meta::TypeConstraint::DuckType
    Moose::Meta::TypeConstraint::Enum
    Moose::Meta::TypeConstraint::Parameterizable
    Moose::Meta::TypeConstraint::Parameterized
    Moose::Meta::TypeConstraint::Registry
    Moose::Meta::TypeConstraint::Role
    Moose::Meta::TypeConstraint::Union
    Moose::Object
    Moose::Role
    Moose::Util
    Moose::Util::MetaRole
    Moose::Util::TypeConstraints
    Moose::Util::TypeConstraints::OptimizedConstraints
);

sub new {
    my ( $self, @args ) = @_;
    $self->create_error_confess( @args );
}

sub create_error_croak {
    my ( $self, @args ) = @_;
    $self->_create_error_carpmess( @args );
}

sub create_error_confess {
    my ( $self, @args ) = @_;
    $self->_create_error_carpmess( @args, longmess => 1 );
}

sub _create_error_carpmess {
    my ( $self, %args ) = @_;

    my $carp_level = 3 + ( $args{depth} || 1 );
    local $Carp::MaxArgNums = 20; # default is 8, usually we use named args which gets messier though

    my @args = exists $args{message} ? $args{message} : ();

    if ( $args{longmess} || $Carp::Verbose ) {
        local $Carp::CarpLevel = ( $Carp::CarpLevel || 0 ) + $carp_level;
        return Carp::longmess(@args);
    } else {
        return Carp::ret_summary($carp_level, @args);
    }
}

__PACKAGE__

__END__

=pod

=head1 NAME

Moose::Error::Default - L<Carp> based error generation for Moose.

=head1 DESCRIPTION

This class implements L<Carp> based error generation.

The default behavior is like L<Moose::Error::Confess>.

=head1 METHODS

=over 4

=item new @args

Create a new error. Delegates to C<create_error_confess>.

=item create_error_confess @args

=item create_error_croak @args

Creates a new errors string of the specified style.

=back

=cut


