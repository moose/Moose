package Overloading::RoleWithOverloads;

use Moose::Role;

use overload
    q{""}    => 'as_string',
    fallback => 1;

has message => (
    is  => 'rw',
    isa => 'Str',
);

sub as_string { shift->message }

1;
