package Overloading::CombiningRole;

use Moose::Role;

with 'Overloading::RoleWithOverloads', 'Overloading::RoleWithoutOverloads';

1;
