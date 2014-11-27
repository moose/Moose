use strict;
use warnings;
use Test::More;

{
    # so we don't pick up stuff from Moose::Object
    package Base;
    sub foo { } # touch it so that 'extends' doesn't try to load it
}

{
    package Foo;
    use Moose;
    extends 'Base';
    no Moose;
}
can_ok('Foo', 'meta');
is(Foo->meta, Class::MOP::class_of('Foo'), 'Foo is a class_of Foo, via Foo->meta');
isa_ok(Foo->meta->get_method('meta'), 'Moose::Meta::Method::Meta');

{
    package Bar;
    use Moose -meta_name => 'bar_meta';
    extends 'Base';
    no Moose;
}
ok(!Bar->can('meta'), q{Bar->cant('meta')});
can_ok('Bar', 'bar_meta');
is(Bar->bar_meta, Class::MOP::class_of('Bar'), 'Bar is a class_of Bar, via Bar->bar_meta');
isa_ok(Bar->bar_meta->get_method('bar_meta'), 'Moose::Meta::Method::Meta');

{
    package Baz;
    use Moose -meta_name => undef;
    extends 'Base';
    no Moose;
}
ok(!Baz->can('meta'), q{Baz->cant('meta')});

my $universal_method_count = scalar Class::MOP::class_of('UNIVERSAL')->get_all_methods;
# 1 because of the dummy method we installed in Base
is(
    ( scalar Class::MOP::class_of('Baz')->get_all_methods ) - $universal_method_count,
    1,
    'Baz has one method',
);

{
    package Qux;
    use Moose -meta_name => 'qux_meta';
}

can_ok('Qux', 'qux_meta');
is(Qux->qux_meta, Class::MOP::class_of('Qux'), 'Qux is a class_of Qux, via Qux->qux_meta');
isa_ok(Qux->qux_meta->get_method('qux_meta'), 'Moose::Meta::Method::Meta');

{
    package FooBar;
    sub meta { 42 }
    use Moose -meta_name => 'foo_bar_meta';
}

is(FooBar->meta, 42, 'FooBar->meta returns 42, not metaclass object');

{
    package FooBar::Child;
    use Moose -meta_name => 'foo_bar_child_meta';
    extends 'FooBar';
}

is(FooBar::Child->meta, 42, 'FooBar::Child->meta returns 42, not metaclass object');

done_testing;
