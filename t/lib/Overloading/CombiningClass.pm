package Overloading::CombiningClass;

use Moose;

with 'Overloading::RoleWithOverloads', 'Overloading::RoleWithoutOverloads';

1;
