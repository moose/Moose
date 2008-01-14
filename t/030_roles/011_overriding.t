#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 40;
use Test::Exception;

BEGIN {
    use_ok('Moose');
}

{ 
    # test no conflicts here
    package Role::A;
    use Moose::Role;

    sub bar { 'Role::A::bar' }

    package Role::B;
    use Moose::Role;

    sub xxy { 'Role::B::xxy' }

    package Role::C;
    use Moose::Role;
    
    ::lives_ok {
        with qw(Role::A Role::B); # no conflict here
    } "define role C";

    sub foo { 'Role::C::foo' }
    sub zot { 'Role::C::zot' }

    package Class::A;
    use Moose;

    ::lives_ok {
        with qw(Role::C);
    } "define class A";
    
    sub zot { 'Class::A::zot' }
}

can_ok( Class::A->new, qw(foo bar xxy zot) );

is( Class::A->new->foo, "Role::C::foo",  "... got the right foo method" );
is( Class::A->new->zot, "Class::A::zot", "... got the right zot method" );
is( Class::A->new->bar, "Role::A::bar",  "... got the right bar method" );
is( Class::A->new->xxy, "Role::B::xxy",  "... got the right xxy method" );

{
    # check that when a role is added to another role
    # and they conflict and the method they conflicted
    # with is then required. 
    
    package Role::A::Conflict;
    use Moose::Role;
    
    with 'Role::A';
    
    sub bar { 'Role::A::Conflict::bar' }
    
    package Class::A::Conflict;
    use Moose;
    
    ::throws_ok {
        with 'Role::A::Conflict';
    }  qr/requires.*'bar'/, '... did not fufill the requirement of &bar method';
    
    package Class::A::Resolved;
    use Moose;
    
    ::lives_ok {
        with 'Role::A::Conflict';
    } '... did fufill the requirement of &bar method';    
    
    sub bar { 'Class::A::Resolved::bar' }
}

ok(Role::A::Conflict->meta->requires_method('bar'), '... Role::A::Conflict created the bar requirement');

can_ok( Class::A::Resolved->new, qw(bar) );

is( Class::A::Resolved->new->bar, 'Class::A::Resolved::bar', "... got the right bar method" );

{
    # check that when two roles are composed, they conflict
    # but the composing role can resolve that conflict
    
    package Role::D;
    use Moose::Role;

    sub foo { 'Role::D::foo' }
    sub bar { 'Role::D::bar' }    

    package Role::E;
    use Moose::Role;

    sub foo { 'Role::E::foo' }
    sub xxy { 'Role::E::xxy' }

    package Role::F;
    use Moose::Role;

    ::lives_ok {
        with qw(Role::D Role::E); # conflict between 'foo's here
    } "define role Role::F";
    
    sub foo { 'Role::F::foo' }
    sub zot { 'Role::F::zot' }    
    
    package Class::B;
    use Moose;
    
    ::lives_ok {
        with qw(Role::F);
    } "define class Class::B";
    
    sub zot { 'Class::B::zot' }
}

can_ok( Class::B->new, qw(foo bar xxy zot) );

is( Class::B->new->foo, "Role::F::foo",  "... got the &foo method okay" );
is( Class::B->new->zot, "Class::B::zot", "... got the &zot method okay" );
is( Class::B->new->bar, "Role::D::bar",  "... got the &bar method okay" );
is( Class::B->new->xxy, "Role::E::xxy",  "... got the &xxy method okay" );

ok(!Role::F->meta->requires_method('foo'), '... Role::F fufilled the &foo requirement');

{
    # check that a conflict can be resolved
    # by a role, but also new ones can be 
    # created just as easily ...
    
    package Role::D::And::E::Conflict;
    use Moose::Role;

    ::lives_ok {
        with qw(Role::D Role::E); # conflict between 'foo's here
    } "... define role Role::D::And::E::Conflict";
    
    sub foo { 'Role::D::And::E::Conflict::foo' }  # this overrides ...
      
    # but these conflict      
    sub xxy { 'Role::D::And::E::Conflict::xxy' }  
    sub bar { 'Role::D::And::E::Conflict::bar' }        

}

ok(!Role::D::And::E::Conflict->meta->requires_method('foo'), '... Role::D::And::E::Conflict fufilled the &foo requirement');
ok(Role::D::And::E::Conflict->meta->requires_method('xxy'), '... Role::D::And::E::Conflict adds the &xxy requirement');
ok(Role::D::And::E::Conflict->meta->requires_method('bar'), '... Role::D::And::E::Conflict adds the &bar requirement');

{
    # conflict propagation
    
    package Role::H;
    use Moose::Role;

    sub foo { 'Role::H::foo' }
    sub bar { 'Role::H::bar' }    

    package Role::J;
    use Moose::Role;

    sub foo { 'Role::J::foo' }
    sub xxy { 'Role::J::xxy' }

    package Role::I;
    use Moose::Role;

    ::lives_ok {
        with qw(Role::J Role::H); # conflict between 'foo's here
    } "define role Role::I";
    
    sub zot { 'Role::I::zot' }

    package Class::C;
    use Moose;
    
    ::throws_ok {
        with qw(Role::I);
    } qr/requires.*'foo'/, "defining class Class::C fails";

    sub zot { 'Class::C::zot' }

    package Class::E;
    use Moose;

    ::lives_ok {
        with qw(Role::I);
    } "resolved with method";        

    sub foo { 'Class::E::foo' }
    sub zot { 'Class::E::zot' }    
}

can_ok( Class::E->new, qw(foo bar xxy zot) );

is( Class::E->new->foo, "Class::E::foo", "... got the right &foo method" );
is( Class::E->new->zot, "Class::E::zot", "... got the right &zot method" );
is( Class::E->new->bar, "Role::H::bar",  "... got the right &bar method" );
is( Class::E->new->xxy, "Role::J::xxy",  "... got the right &xxy method" );

ok(Role::I->meta->requires_method('foo'), '... Role::I still have the &foo requirement');

{
    # fix these later ...
    TODO: {
        local $TODO = "add support for attribute methods fufilling reqs";

        lives_ok {
            package Class::D;
            use Moose;

            has foo => ( default => __PACKAGE__ . "::foo", is => "rw" );

            sub zot { 'Class::D::zot' }

            with qw(Role::I);
            
        } "resolved with attr";

        can_ok( Class::D->new, qw(foo bar xxy zot) );
        is( eval { Class::D->new->bar }, "Role::H::bar", "bar" );
        is( eval { Class::D->new->xxy }, "Role::I::xxy", "xxy" );
    }

    is( eval { Class::D->new->foo }, "Class::D::foo", "foo" );
    is( eval { Class::D->new->zot }, "Class::D::zot", "zot" );

}

