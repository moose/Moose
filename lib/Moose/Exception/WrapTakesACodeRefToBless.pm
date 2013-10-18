package Moose::Exception::WrapTakesACodeRefToBless;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::ParamsHash';

has 'code' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1
);

has 'class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_message {
    my $self = shift;
    "You must supply a CODE reference to bless, not (" . ( $self->code ? $self->code : 'undef' ) . ")";
}

1;
