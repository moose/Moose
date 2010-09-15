package Moose::Meta::Method::Accessor::Native::Array::sort;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Reader';

sub _inline_process_arguments {
    return 'my $func = shift if @_;';
}

sub _inline_check_arguments {
    return
        q{die 'Argument must be a code reference' if $func && ( ref $func || q{} ) ne 'CODE';};
}

sub _return_value {
    my $self        = shift;
    my $slot_access = shift;

    return
        "\$func ? sort { \$func->( \$a, \$b ) } \@{ ${slot_access} } : sort \@{ $slot_access }";
}

1;
