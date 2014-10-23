package Class::MOP::Overload;

use strict;
use warnings;

use overload ();
use Scalar::Util qw( weaken );
use Try::Tiny;

use parent 'Class::MOP::Object';

my %Operators = (
    map { $_ => 1 }
    grep { $_ ne 'fallback' }
    map  { split /\s+/ } values %overload::ops
);

sub new {
    my ( $class, %params ) = @_;

    unless ( defined $params{operator} ) {
        $class->_throw_exception('OverloadRequiresAnOperator');
    }
    unless ( $Operators{ $params{operator} } ) {
        $class->_throw_exception(
            'InvalidOverloadOperator',
            operator => $params{operator},
        );
    }

    unless ( defined $params{method_name} || $params{coderef} ) {
        $class->_throw_exception(
            'OverloadRequiresAMethodNameOrCoderef',
            operator => $params{operator},
        );
    }

    if ( $params{coderef} ) {
        unless ( defined $params{coderef_package}
            && defined $params{coderef_name} ) {

            $class->_throw_exception('OverloadRequiresNamesForCoderef');
        }
    }

    if ( $params{method}
        && !try { $params{method}->isa('Class::MOP::Method') } ) {

        $class->_throw_exception('OverloadRequiresAMetaMethod');
    }

    if ( $params{associated_metaclass}
        && !try { $params{associated_metaclass}->isa('Class::MOP::Module') } )
    {

        $class->_throw_exception('OverloadRequiresAMetaClass');
    }

    my @optional_attrs
        = qw( method_name coderef coderef_package coderef_name method associated_metaclass );

    return bless {
        operator => $params{operator},
        map { defined $params{$_} ? ( $_ => $params{$_} ) : () }
            @optional_attrs
        },
        $class;
}

sub operator { $_[0]->{operator} }

sub method_name { $_[0]->{method_name} }
sub has_method_name { exists $_[0]->{method_name} }

sub method { $_[0]->{method} }
sub has_method { exists $_[0]->{method} }

sub coderef { $_[0]->{coderef} }
sub has_coderef { exists $_[0]->{coderef} }

sub coderef_package { $_[0]->{coderef_package} }
sub has_coderef_package { exists $_[0]->{coderef_package} }

sub coderef_name { $_[0]->{coderef_name} }
sub has_coderef_name { exists $_[0]->{coderef_name} }

sub associated_metaclass { $_[0]->{associated_metaclass} }

sub is_anonymous {
    my $self = shift;
    return $self->has_coderef && $self->coderef_name eq '__ANON__';
}

sub attach_to_class {
    my ( $self, $class ) = @_;
    $self->{associated_metaclass} = $class;
    weaken $self->{associated_metaclass};
}

sub clone {
    my $self = shift;

    my $clone = bless { %{$self}, @_ }, blessed($self);
    weaken $clone->{associated_metaclass} if $clone->{associated_metaclass};

    $clone->_set_original_overload($self);

    return $clone;
}

sub original_overload { $_[0]->{original_overload} }
sub _set_original_overload { $_[0]->{original_overload} = $_[1] }

sub _is_equal_to {
    my $self  = shift;
    my $other = shift;

    if ( $self->has_coderef ) {
        return unless $other->has_coderef;
        return $self->coderef == $other->coderef;
    }
    else {
        return $self->method_name eq $other->method_name;
    }
}

1;
