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

    # FIXME this needs to be in a header that's written by a perl script
    my $i;
    my %checks = map { $_ => $i++ } qw(
        Any
        Undef
        Defined
        Str
        Num
        Int
        GlobRef
        ArrayRef
        HashRef
        CodeRef
        Ref
        ScalarRef
        FileHandle
        RegexpRef
        Object
        Role
        ClassName
    );

    # aliases
    $checks{Bool} = $checks{Item} = $checks{Any};
    $checks{Value} = $checks{Str};

    sub tc_params {
        my $tc = shift;

        return ( undef, 0, undef ) unless $tc; # tc_none

        if (
            # sleazy check for core types that haven't been parametrized
            #(ref $tc eq 'Moose::Meta::TypeConstraint' or ref $tc eq 'Moose::Meta::TypeConstraint::Parameterizable')
            #    and
            exists $checks{$tc->name}
        ) {
            # builtin moose type # 
            return ( $tc, 1, $checks{$tc->name} ); # tc_type
        } elsif ( $tc->isa("Moose::Meta::TypeConstraint::Class") ) {
            return ( $tc, 2, $tc->class ); # tc_stash
        } else {
            # FIXME enum is its own tc_kind
            return ( $tc, 3, $tc->_compiled_type_constraint ); # tc_cv
        }
    }

    sub meta_instance_to_attr_descs {
        my $mi = shift;

        return (
            $mi->associated_metaclass->name,
            [ map {[
                $_,
                [$_->slots],

                $_->is_weak_ref,
                $_->should_coerce,
                $_->is_lazy,

                tc_params($_->type_constraint),
                $_->trigger,
                $_->initializer,

                $_->has_default,
                $_->default,
                $_->builder,

                $_->init_arg,
            ]} $mi->get_all_attributes ]
        );
    }
}

ok( defined &Moose::XS::new_reader, "new_reader" );
ok( defined &Moose::XS::new_writer, "new_writer" );
ok( defined &Moose::XS::new_accessor, "new_accessor" );
ok( defined &Moose::XS::new_predicate, "new_predicate" );

{
    package Foo;
    use Moose;

    use Moose::Util::TypeConstraints;

    subtype( 'FiveChars',
        as "Str",
        where { length == 5 },
    );

    has x => ( is => "rw", predicate => "has_x" );
    has y => ( is => "ro" );
    has z => ( reader => "z", writer => "set_z" );
    has ref => ( is => "rw", weak_ref => 1 );
    has i => ( isa => "Int", is => "rw" );
    has s => ( isa => "Str", is => "rw" );
    has a => ( isa => "ArrayRef", is => "rw" );
    has o => ( isa => "Object", is => "rw" );
    has f => ( isa => "Foo", is => "rw" );
    has c => ( isa => "ClassName", is => "rw" );
    has b => ( is => "ro", lazy_build => 1 ); # fixme type constraint checking
    has tc => ( is => "rw", isa => "FiveChars" );

    sub _build_b { "builded!" }

    # FIXME Regexp, ScalarRef, parametrized, filehandle

    package Gorch;
    use Moose;

    extends qw(Foo);

    package Quxx;
    use Moose;

    sub isa {
        return $_[1] eq 'Foo';
    }
}

{
    my ( $x, $y, $z, $ref, $a, $s, $i, $o, $f, $c, $b ) = map { Foo->meta->get_attribute($_) } qw(x y z ref a s i o f c b);
    $x->Moose::XS::new_accessor("Foo::x");
    $x->Moose::XS::new_predicate("Foo::has_x");
    $y->Moose::XS::new_reader("Foo::y");
    $z->Moose::XS::new_reader("Foo::z");
    $z->Moose::XS::new_writer("Foo::set_z");
    $ref->Moose::XS::new_accessor("Foo::ref");
    $a->Moose::XS::new_accessor("Foo::a");
    $s->Moose::XS::new_accessor("Foo::s");
    $i->Moose::XS::new_accessor("Foo::i");
    $o->Moose::XS::new_accessor("Foo::o");
    $f->Moose::XS::new_accessor("Foo::f");
    $c->Moose::XS::new_accessor("Foo::c");
    $b->Moose::XS::new_accessor("Foo::b");
}


my $ref = [ ];

my $foo = Foo->new( x => "ICKS", y => "WHY", z => "ZEE", ref => $ref );

is( $foo->x, "ICKS", "accessor as reader" );
is( $foo->y, "WHY", "reader" );
is( $foo->z, "ZEE", "reader" );
is( $foo->ref, $ref, "accessor for ref" );
is( $foo->b, "builded!", "lazy builder" );

lives_ok { $foo->x("YASE") } "accessor";

is( $foo->x, "YASE", "attr value set by accessor" );

dies_ok { $foo->y("blah") } "reader dies when used as writer";

is( $foo->y, "WHY", "reader" );

dies_ok { $foo->z("blah") } "reader dies when used as writer";

is( $foo->z, "ZEE", "reader" );

lives_ok { $foo->set_z("new") } "writer";

is( $foo->z, "new", "attr set by writer" );

ok( $foo->has_x, "predicate" );

ok( !Foo->new->has_x, "predicate on new obj is false" );

is( $foo->ref, $ref, "ref attr" );

undef $ref;
is( $foo->ref(), undef, "weak ref detstroyed" );

$ref = { };

$foo->ref($ref);
is( $foo->ref, $ref, "attr set" );

undef $ref;
is( $foo->ref(), undef, "weak ref destroyed" );

ok( !eval { $foo->a("not a ref"); 1 }, "ArrayRef" );
ok( !eval { $foo->a(3); 1 }, "ArrayRef" );
ok( !eval { $foo->a({}); 1 }, "ArrayRef" );
ok( !eval { $foo->a(undef); 1 }, "ArrayRef" );
ok( !eval { $foo->i(1.3); 1 }, "Int" );
ok( !eval { $foo->i("1.3"); 1 }, "Int" );
ok( !eval { $foo->i("foo"); 1 }, "Int" );
ok( !eval { $foo->i(undef); 1 }, "Int" );
ok( !eval { $foo->i(\undef); 1 }, "Int" );
ok( !eval { $foo->s(undef); 1 }, "Str" );
ok( !eval { $foo->s([]); 1 }, "Str" );
ok( !eval { $foo->o({}); 1 }, "Object" );
ok( !eval { $foo->o(undef); 1 }, "Object" );
ok( !eval { $foo->o(42); 1 }, "Object" );
ok( !eval { $foo->o("hi ho"); 1 }, "Object" );
ok( !eval { $foo->o(" ho"); 1 }, "Object" );
ok( !eval { $foo->f(bless {}, "Bar"); 1 }, "Class (Foo)" );
ok( !eval { $foo->f(undef); 1 }, "Class (Foo)" );
ok( !eval { $foo->f("foo"); 1 }, "Class (Foo)" );
ok( !eval { $foo->f(3); 1 }, "Class (Foo)" );
ok( !eval { $foo->f({}); 1 }, "Class (Foo)" );
ok( !eval { $foo->f("Foo"); 1 }, "Class (Foo)" );
ok( !eval { $foo->c("Horse"); 1 }, "ClassName" );
ok( !eval { $foo->c(3); 1 }, "ClassName" );
ok( !eval { $foo->c(undef); 1 }, "ClassName" );
ok( !eval { $foo->c("feck"); 1 }, "ClassName" );
ok( !eval { $foo->c({}); 1 }, "ClassName" );
ok( !eval { $foo->tc(undef); 1 }, "custom type" );
ok( !eval { $foo->tc(""); 1 }, "custom type" );
ok( !eval { $foo->tc("foo"); 1 }, "custom type" );
ok( !eval { $foo->tc(3); 1 }, "custom type" );
ok( !eval { $foo->tc([]); 1 }, "custom type" );

ok( eval { $foo->a([]); 1 }, "ArrayRef" );
ok( eval { $foo->i(3); 1 }, "Int" );
ok( eval { $foo->i("3"); 1 }, "Int" );
ok( eval { $foo->i("-3"); 1 }, "Int" );
ok( eval { $foo->i("  -3  "); 1 }, "Int" );
ok( eval { $foo->s("foo"); 1 }, "Str" );
ok( eval { $foo->s(""); 1 }, "Str" );
ok( eval { $foo->s(4); 1 }, "Str" );
ok( eval { $foo->o(bless {}, "Bar"); 1 }, "Object" );
ok( eval { $foo->f(Foo->new); 1 }, "Class (Foo)" );
ok( eval { $foo->f(Gorch->new); 1 }, "Class (Foo), real subclass");
ok( eval { $foo->f(Quxx->new); 1 }, "Class (Foo), fake subclass");
ok( eval { $foo->c("Foo"); 1 }, "ClassName" );
ok( eval { $foo->tc("hello"); 1 }, "custom type" );



$foo->meta->invalidate_meta_instance();
isa_ok( $foo->f, 'Foo' );
$foo->meta->invalidate_meta_instance();
isa_ok( $foo->f, 'Foo' );

