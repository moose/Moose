use strict;
use warnings;

use Test::More;

{
    package Foo;
    use Moose;

    sub foo { }
}
{
    package Bar;
    use Moose;

    has foo     => (
        is      => 'ro',
        isa     => 'Foo',
        handles => {
            foo_foo => 'foo',
        },
    );
}

my $meta_method = Bar->meta->get_method('foo_foo');
isa_ok $meta_method => 'Moose::Meta::Method::Delegation';
cmp_ok $meta_method->_get_delegate_accessor, 'eq', ${ $meta_method->_get_delegate_accessor_ref },
    'both coderefs are identical';

done_testing;
