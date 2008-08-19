#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    plan skip_all => "no XSLoader" unless eval { require XSLoader };

    plan skip_all => $@ unless eval {
        require Moose;
        Moose->XSLoader::load($Moose::VERSION);
        1;
    };

    plan 'no_plan';
}

{
    package Moose::XS;

    sub attr_to_meta_instance {
        my $attr = shift;
        return $attr->associated_class->get_meta_instance;
    }

    sub meta_instance_to_attr_descs {
        my $mi = shift;

        return (
            $mi->associated_metaclass->name,
            [ map { {
                meta => $_,
                key  => ($_->slots)[0],
            } } $mi->get_all_attributes ]
        );
    }
}

ok( defined &Moose::XS::new_getter );
ok( defined &Moose::XS::new_setter );
ok( defined &Moose::XS::new_accessor );
ok( defined &Moose::XS::new_predicate );

{
    package Foo;
    use Moose;

    has x => ( is => "rw", predicate => "has_x" );
    has y => ( is => "ro" );
    has z => ( reader => "z", setter => "set_z" );
    has ref => ( is => "rw", weak_ref => 1 );
    has i => ( isa => "Int", is => "rw" );
    has s => ( isa => "Str", is => "rw" );
    has a => ( isa => "ArrayRef", is => "rw" );
}

{
    my ( $x, $y, $z, $ref, $a, $s, $i ) = map { Foo->meta->get_attribute($_) } qw(x y z ref a s i);
    $x->Moose::XS::new_accessor("Foo::x");
    $x->Moose::XS::new_predicate("Foo::has_x");
    $y->Moose::XS::new_getter("Foo::y");
    $z->Moose::XS::new_getter("Foo::z");
    $z->Moose::XS::new_setter("Foo::set_z");
    $ref->Moose::XS::new_accessor("Foo::ref");
    $a->Moose::XS::new_accessor("Foo::a");
    $s->Moose::XS::new_accessor("Foo::s");
    $i->Moose::XS::new_accessor("Foo::i");
}


my $ref = [ ];

my $foo = Foo->new( x => "ICKS", y => "WHY", z => "ZEE", ref => $ref );

is( $foo->x, "ICKS" );
is( $foo->y, "WHY" );
is( $foo->z, "ZEE" );
is( $foo->ref, $ref, );

lives_ok { $foo->x("YASE") };

is( $foo->x, "YASE" );

dies_ok { $foo->y("blah") };

is( $foo->y, "WHY" );

dies_ok { $foo->z("blah") };

is( $foo->z, "ZEE" );

lives_ok { $foo->set_z("new") };

is( $foo->z, "new" );

ok( $foo->has_x );

ok( !Foo->new->has_x );

undef $ref;

is( $foo->ref(), undef );

$ref = { };

$foo->ref($ref);

is( $foo->ref, $ref, );

undef $ref;

is( $foo->ref(), undef );

ok( !eval { $foo->a("not a ref"); 1 } );
ok( !eval { $foo->i(1.3); 1 } );
ok( !eval { $foo->s(undef); 1 } );

ok( eval { $foo->a([]); 1 } );
ok( eval { $foo->i(3); 1 } );
ok( eval { $foo->s("foo"); 1 } );

use Data::Dumper;
warn Dumper($foo);
