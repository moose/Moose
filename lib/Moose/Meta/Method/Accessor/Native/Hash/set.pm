package Moose::Meta::Method::Accessor::Native::Hash::set;

use strict;
use warnings;

use List::MoreUtils ();
use Scalar::Util qw( looks_like_number );

our $VERSION = '1.21';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Hash::Writer' => {
    -excludes => [
        qw(
            _minimum_arguments
            _maximum_arguments
            _inline_process_arguments
            _inline_check_arguments
            _inline_optimized_set_new_value
            _return_value
            )
    ],
};

sub _minimum_arguments { 2 }

sub _maximum_arguments { undef }

around _inline_check_argument_count => sub {
    my $orig = shift;
    my $self = shift;

    return
        $self->$orig(@_) . "\n"
        . $self->_inline_throw_error(
        q{'You must pass an even number of arguments to set'})
        . ' if @_ % 2;';
};

sub _inline_process_arguments {
    my $self = shift;

    return 'my @keys_idx = grep { ! ($_ % 2) } 0..$#_;' . "\n"
        . 'my @values_idx = grep { $_ % 2 } 0..$#_;';
}

sub _inline_check_arguments {
    my $self = shift;

    return
        'for (@keys_idx) {' . "\n"
        . $self->_inline_throw_error(
        q{'Hash keys passed to set must be defined'})
        . ' unless defined $_[$_];' . "\n" . '}';
}

sub _adds_members { 1 }

# We need to override this because while @_ can be written to, we cannot write
# directly to $_[1].
around _inline_coerce_new_values => sub {
    shift;
    my $self = shift;

    return q{} unless $self->associated_attribute->should_coerce;

    return q{} unless $self->_tc_member_type_can_coerce;

    # Is there a simpler way to do this?
    return 'my $iter = List::MoreUtils::natatime 2, @_;'
         .  '@_ = ();'
         . 'while ( my ( $key, $val ) = $iter->() ) {'
         .     'push @_, $key, $member_tc_obj->coerce($val);'
         . '}';
};

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "{ %{ ($slot_access) }, \@_ }";
}

sub _new_members { '@_[ @values_idx ]' }

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "\@{ ($slot_access) }{ \@_[ \@keys_idx] } = \@_[ \@values_idx ]";
}

sub _return_value {
    my ( $self, $slot_access ) = @_;

    return "return wantarray ? \@{ ($slot_access) }{ \@_[ \@keys_idx ] } : ${slot_access}->{ \$_[ \$keys_idx[0] ] };";
}

no Moose::Role;

1;
