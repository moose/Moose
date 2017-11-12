package Moose::Exception::Role::RoleForCreate;
our $VERSION = '2.2008';

use Moose::Role;
with 'Moose::Exception::Role::ParamsHash';

has 'attribute_class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
