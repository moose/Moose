use strict;
use warnings;

use Test::More;

{
    package Role;

    use Moose::Role;

    has foo => ( reader => 'foo', writer => 'set_foo', handles => ['bar'] );
}

my $meta = Role->meta;
ok( $meta->has_method('foo'), 'Role has a meta method for foo reader' );
ok(
    $meta->get_method('foo')->isa('Moose::Meta::Method::Stub'),
    'meta method is a Stub'
);

ok( $meta->has_method('set_foo'), 'Role has a meta method for foo writer' );
ok(
    $meta->get_method('set_foo')->isa('Moose::Meta::Method::Stub'),
    'meta method is a Stub'
);

ok( $meta->has_method('bar'), 'Role has a meta method for foo delegation' );
ok(
    $meta->get_method('bar')->isa('Moose::Meta::Method::Stub'),
    'meta method is a Stub'
);

done_testing;
