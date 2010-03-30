package Moose::Meta::Mixin::HasMethods;

use strict;
use warnings;

our $VERSION   = '0.99';
our $AUTHORITY = 'cpan:STEVAN';

use base 'Class::MOP::Mixin::HasMethods';

sub add_method_modifier {
    my ( $self, $modifier_name, $args ) = @_;

    my $code                = pop @{$args};
    my $add_modifier_method = 'add_' . $modifier_name . '_method_modifier';

    if ( my $method_modifier_type = ref( @{$args}[0] ) ) {
        if ( $method_modifier_type eq 'Regexp' ) {
            my @all_methods = $self->get_all_methods;
            my @matched_methods
                = grep { $_->name =~ @{$args}[0] } @all_methods;
            $self->$add_modifier_method( $_->name, $code )
                for @matched_methods;
        }
        elsif ( $method_modifier_type eq 'ARRAY' ) {
            $self->$add_modifier_method( $_, $code ) for @{ $args->[0] };
        }
        else {
            $self->throw_error(
                sprintf(
                    "Methods passed to %s must be provided as a list, arrayref or regex, not %s",
                    $modifier_name,
                    $method_modifier_type,
                )
            );
        }
    }
    else {
        $self->$add_modifier_method( $_, $code ) for @{$args};
    }
}

1;
