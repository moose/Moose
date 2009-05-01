use strict;
use warnings;
use Test::More tests => 3;

{
    package Foo;
    use Moose::Role;
}

my $meta = Class::MOP::class_of('Foo');
my $method = $meta->get_method('meta');
ok($method, 'meta method exists');
is($method->associated_metaclass->name, 'Foo', 'meta method belongs to the right class');
TODO: {
    local $TODO = "get_method_list doesn't include the meta method for roles yet";
    ok((+grep { $_ eq 'meta' } $meta->get_method_list), 'get_method_list returns meta');
}
