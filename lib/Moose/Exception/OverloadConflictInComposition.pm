package Moose::Exception::OverloadConflictInComposition;

use Moose;
extends 'Moose::Exception';
with 'Moose::Exception::Role::Role';

has 'role_being_applied_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'overloaded_op' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_message {
    my $self = shift;

    my $applied  = $self->role_being_applied_name;
    my $consumer = $self->role_name;

    my $op = $self->overloaded_op;
    if ( $op eq 'fallback' ) {
        return
            'We have encountered an overloading conflict for the fallback setting '
            . "when applying $applied to $consumer. This is a fatal error.";
    }
    else {
        return
            'We have encountered an overloading conflict between overloading methods '
            . "when applying $applied to $consumer. The two roles both overload the '$op' operator. "
            . 'This is a fatal error.';
    }
}

1;
