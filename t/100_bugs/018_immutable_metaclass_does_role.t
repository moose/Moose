
{
    package MyRole;
    use Moose::Role;
    BEGIN {
        requires 'foo';
    }
    no Moose::Role;
}
{
    package MyMetaclass;
    use Moose;
    BEGIN {
        sub foo { 'i am foo' }
        extends 'Moose::Meta::Class';
        with 'MyRole';
    }
    no Moose;
}

{
    package MyClass;
    use metaclass 'MyMetaclass';
    use Moose;
    no Moose;
}

use Test::More tests => 5;

my $a = MyClass->new;
ok( $a->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );

# now try combinations of having the class/metaclass made immutable
# and run the same test

MyClass->meta->make_immutable;
ok( $a->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );

MyClass->meta->make_mutable;
ok( $a->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );

MyMetaclass->meta->make_immutable;
ok( $a->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );

MyClass->meta->make_immutable;
ok( $a->meta->meta->does_role('MyRole'), 'metaclass does MyRole' );

