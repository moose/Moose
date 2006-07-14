#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 67;
use Test::Exception;

BEGIN {
    use_ok('Moose');
    use_ok('Moose::Role');    
}

=pod

Mutually recursive roles.

=cut

{
    package Role::Foo;
    use Moose::Role;

    requires 'foo';
    
    sub bar { 'Role::Foo::bar' }
    
    package Role::Bar;
    use Moose::Role;
    
    requires 'bar';
    
    sub foo { 'Role::Bar::foo' }    
}

{
    package My::Test1;
    use Moose;
    
    ::lives_ok {
        with 'Role::Foo', 'Role::Bar';
    } '... our mutually recursive roles combine okay';
    
    package My::Test2;
    use Moose;
    
    ::lives_ok {
        with 'Role::Bar', 'Role::Foo';
    } '... our mutually recursive roles combine okay (no matter what order)';    
}

my $test1 = My::Test1->new;
isa_ok($test1, 'My::Test1');

ok($test1->does('Role::Foo'), '... $test1 does Role::Foo');
ok($test1->does('Role::Bar'), '... $test1 does Role::Bar');

can_ok($test1, 'foo');
can_ok($test1, 'bar');

is($test1->foo, 'Role::Bar::foo', '... $test1->foo worked');
is($test1->bar, 'Role::Foo::bar', '... $test1->bar worked');

my $test2 = My::Test2->new;
isa_ok($test2, 'My::Test2');

ok($test2->does('Role::Foo'), '... $test2 does Role::Foo');
ok($test2->does('Role::Bar'), '... $test2 does Role::Bar');

can_ok($test2, 'foo');
can_ok($test2, 'bar');

is($test2->foo, 'Role::Bar::foo', '... $test2->foo worked');
is($test2->bar, 'Role::Foo::bar', '... $test2->bar worked');

# check some meta-stuff

ok(Role::Foo->meta->has_method('bar'), '... it still has the bar method');
ok(Role::Foo->meta->requires_method('foo'), '... it still has the required foo method');

ok(Role::Bar->meta->has_method('foo'), '... it still has the foo method');
ok(Role::Bar->meta->requires_method('bar'), '... it still has the required bar method');

=pod

Role method conflicts

=cut

{
    package Role::Bling;
    use Moose::Role;
    
    sub bling { 'Role::Bling::bling' }
    
    package Role::Bling::Bling;
    use Moose::Role;
    
    sub bling { 'Role::Bling::Bling::bling' }    
}

{
    package My::Test3;
    use Moose;
    
    ::throws_ok {
        with 'Role::Bling', 'Role::Bling::Bling';
    } qr/requires the method \'bling\' to be implemented/, '... role methods conflicted and method was required';
    
    package My::Test4;
    use Moose;
    
    ::lives_ok {
        with 'Role::Bling';
        with 'Role::Bling::Bling';
    } '... role methods didnt conflict when manually combined';    
    
    package My::Test5;
    use Moose;
    
    ::lives_ok {
        with 'Role::Bling::Bling';
        with 'Role::Bling';
    } '... role methods didnt conflict when manually combined (in opposite order)';    
    
    package My::Test6;
    use Moose;
    
    ::lives_ok {
        with 'Role::Bling::Bling', 'Role::Bling';
    } '... role methods didnt conflict when manually resolved';    
    
    sub bling { 'My::Test6::bling' }
}

ok(!My::Test3->meta->has_method('bling'), '... we didnt get any methods in the conflict');
ok(My::Test4->meta->has_method('bling'), '... we did get the method when manually dealt with');
ok(My::Test5->meta->has_method('bling'), '... we did get the method when manually dealt with');
ok(My::Test6->meta->has_method('bling'), '... we did get the method when manually dealt with');

ok(!My::Test3->does('Role::Bling'), '... our class does() the correct roles');
ok(!My::Test3->does('Role::Bling::Bling'), '... our class does() the correct roles');
ok(My::Test4->does('Role::Bling'), '... our class does() the correct roles');
ok(My::Test4->does('Role::Bling::Bling'), '... our class does() the correct roles');
ok(My::Test5->does('Role::Bling'), '... our class does() the correct roles');
ok(My::Test5->does('Role::Bling::Bling'), '... our class does() the correct roles');
ok(My::Test6->does('Role::Bling'), '... our class does() the correct roles');
ok(My::Test6->does('Role::Bling::Bling'), '... our class does() the correct roles');

is(My::Test4->bling, 'Role::Bling::bling', '... and we got the first method that was added');
is(My::Test5->bling, 'Role::Bling::Bling::bling', '... and we got the first method that was added');
is(My::Test6->bling, 'My::Test6::bling', '... and we got the local method');

# check how this affects role compostion

{
    package Role::Bling::Bling::Bling;
    use Moose::Role;
    
    with 'Role::Bling::Bling';
    
    sub bling { 'Role::Bling::Bling::Bling::bling' }    
}

ok(Role::Bling::Bling->meta->has_method('bling'), '... still got the bling method in Role::Bling::Bling');
ok(Role::Bling::Bling->meta->does_role('Role::Bling::Bling'), '... our role correctly does() the other role');
ok(Role::Bling::Bling::Bling->meta->has_method('bling'), '... still got the bling method in Role::Bling::Bling::Bling');
is(Role::Bling::Bling::Bling->meta->get_method('bling')->(), 
    'Role::Bling::Bling::Bling::bling',
    '... still got the bling method in Role::Bling::Bling::Bling');

=pod

Role attribute conflicts

=cut

{
    package Role::Boo;
    use Moose::Role;
    
    has 'ghost' => (is => 'ro', default => 'Role::Boo::ghost');
    
    package Role::Boo::Hoo;
    use Moose::Role;
    
    has 'ghost' => (is => 'ro', default => 'Role::Boo::Hoo::ghost');
}

{
    package My::Test7;
    use Moose;
    
    ::throws_ok {
        with 'Role::Boo', 'Role::Boo::Hoo';
    } qr/Role \'Role::Boo::Hoo\' has encountered an attribute conflict/, 
      '... role attrs conflicted and method was required';

    package My::Test8;
    use Moose;

    ::lives_ok {
        with 'Role::Boo';
        with 'Role::Boo::Hoo';
    } '... role attrs didnt conflict when manually combined';
    
    package My::Test9;
    use Moose;

    ::lives_ok {
        with 'Role::Boo::Hoo';
        with 'Role::Boo';
    } '... role attrs didnt conflict when manually combined';    

    package My::Test10;
    use Moose;
    
    has 'ghost' => (is => 'ro', default => 'My::Test10::ghost');    
    
    ::throws_ok {
        with 'Role::Boo', 'Role::Boo::Hoo';
    } qr/Role \'Role::Boo::Hoo\' has encountered an attribute conflict/, 
      '... role attrs conflicted and cannot be manually disambiguted';  

}

ok(!My::Test7->meta->has_attribute('ghost'), '... we didnt get any attributes in the conflict');
ok(My::Test8->meta->has_attribute('ghost'), '... we did get an attributes when manually composed');
ok(My::Test9->meta->has_attribute('ghost'), '... we did get an attributes when manually composed');
ok(My::Test10->meta->has_attribute('ghost'), '... we did still have an attribute ghost (conflict does not mess with class)');

ok(!My::Test7->does('Role::Boo'), '... our class does() the correct roles');
ok(!My::Test7->does('Role::Boo::Hoo'), '... our class does() the correct roles');
ok(My::Test8->does('Role::Boo'), '... our class does() the correct roles');
ok(My::Test8->does('Role::Boo::Hoo'), '... our class does() the correct roles');
ok(My::Test9->does('Role::Boo'), '... our class does() the correct roles');
ok(My::Test9->does('Role::Boo::Hoo'), '... our class does() the correct roles');
ok(!My::Test10->does('Role::Boo'), '... our class does() the correct roles');
ok(!My::Test10->does('Role::Boo::Hoo'), '... our class does() the correct roles');

can_ok('My::Test8', 'ghost');
can_ok('My::Test9', 'ghost');
can_ok('My::Test10', 'ghost');

is(My::Test8->new->ghost, 'Role::Boo::ghost', '... got the expected default attr value');
is(My::Test9->new->ghost, 'Role::Boo::Hoo::ghost', '... got the expected default attr value');
is(My::Test10->new->ghost, 'My::Test10::ghost', '... got the expected default attr value');

=pod

Role override method conflicts

=cut

