package Moose::Exception::Role::RoleForCreate;
our $VERSION = '2.1501'; # TRIAL

use Moose::Role;
with 'Moose::Exception::Role::ParamsHash';

has 'attribute_class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
