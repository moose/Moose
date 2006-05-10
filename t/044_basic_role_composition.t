#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 90;
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
    use strict;
    use warnings;
    use Moose::Role;

    requires 'foo';
    
    sub bar { 'Role::Foo::bar' }
    
    package Role::Bar;
    use strict;
    use warnings;
    use Moose::Role;
    
    requires 'bar';
    
    sub foo { 'Role::Bar::foo' }    
}

{
    package My::Test1;
    use strict;
    use warnings;
    use Moose;
    
    ::lives_ok {
        with 'Role::Foo', 'Role::Bar';
    } '... our mutually recursive roles combine okay';
    
    package My::Test2;
    use strict;
    use warnings;
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
    use strict;
    use warnings;
    use Moose::Role;
    
    sub bling { 'Role::Bling::bling' }
    
    package Role::Bling::Bling;
    use strict;
    use warnings;
    use Moose::Role;
    
    sub bling { 'Role::Bling::Bling::bling' }    
}

{
    package My::Test3;
    use strict;
    use warnings;
    use Moose;
    
    ::throws_ok {
        with 'Role::Bling', 'Role::Bling::Bling';
    } qr/requires the method \'bling\' to be implemented/, '... role methods conflicted and method was required';
    
    package My::Test4;
    use strict;
    use warnings;
    use Moose;
    
    ::lives_ok {
        with 'Role::Bling';
        with 'Role::Bling::Bling';
    } '... role methods didnt conflict when manually combined';    
    
    package My::Test5;
    use strict;
    use warnings;
    use Moose;
    
    ::lives_ok {
        with 'Role::Bling::Bling';
        with 'Role::Bling';
    } '... role methods didnt conflict when manually combined (in opposite order)';    
    
    package My::Test6;
    use strict;
    use warnings;
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
    use strict;
    use warnings;
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
    use strict;
    use warnings;
    use Moose::Role;
    
    has 'ghost' => (is => 'ro', default => 'Role::Boo::ghost');
    
    package Role::Boo::Hoo;
    use strict;
    use warnings;
    use Moose::Role;
    
    has 'ghost' => (is => 'ro', default => 'Role::Boo::Hoo::ghost');
}

{
    package My::Test7;
    use strict;
    use warnings;
    use Moose;
    
    ::throws_ok {
        with 'Role::Boo', 'Role::Boo::Hoo';
    } qr/Role \'Role::Boo::Hoo\' has encountered an attribute conflict/, 
      '... role attrs conflicted and method was required';

    package My::Test8;
    use strict;
    use warnings;
    use Moose;

    ::lives_ok {
        with 'Role::Boo';
        with 'Role::Boo::Hoo';
    } '... role attrs didnt conflict when manually combined';
    
    package My::Test9;
    use strict;
    use warnings;
    use Moose;

    ::lives_ok {
        with 'Role::Boo::Hoo';
        with 'Role::Boo';
    } '... role attrs didnt conflict when manually combined';    

    package My::Test10;
    use strict;
    use warnings;
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

{
    package Role::Plot;
    use strict;
    use warnings;
    use Moose::Role;
    
    override 'twist' => sub {
        super() . ' -> Role::Plot::twist';
    };
    
    package Role::Truth;
    use strict;
    use warnings;
    use Moose::Role;
    
    override 'twist' => sub {
        super() . ' -> Role::Truth::twist';
    };
}

{
    package My::Test::Base;
    use strict;
    use warnings;
    use Moose;
    
    sub twist { 'My::Test::Base::twist' }
        
    package My::Test11;
    use strict;
    use warnings;
    use Moose;
    
    extends 'My::Test::Base';

    ::lives_ok {
        with 'Role::Truth';
    } '... composed the role with override okay';
       
    package My::Test12;
    use strict;
    use warnings;
    use Moose;

    extends 'My::Test::Base';

    ::lives_ok {    
       with 'Role::Plot';
    } '... composed the role with override okay';
              
    package My::Test13;
    use strict;
    use warnings;
    use Moose;

    ::dies_ok {
        with 'Role::Plot';       
    } '... cannot compose it because we have no superclass';
    
    package My::Test14;
    use strict;
    use warnings;
    use Moose;

    extends 'My::Test::Base';

    ::throws_ok {
        with 'Role::Plot', 'Role::Truth';       
    } qr/Two \'override\' methods of the same name encountered/, 
      '... cannot compose it because we have no superclass';       
}

ok(My::Test11->meta->has_method('twist'), '... the twist method has been added');
ok(My::Test12->meta->has_method('twist'), '... the twist method has been added');
ok(!My::Test13->meta->has_method('twist'), '... the twist method has not been added');
ok(!My::Test14->meta->has_method('twist'), '... the twist method has not been added');

ok(!My::Test11->does('Role::Plot'), '... our class does() the correct roles');
ok(My::Test11->does('Role::Truth'), '... our class does() the correct roles');
ok(!My::Test12->does('Role::Truth'), '... our class does() the correct roles');
ok(My::Test12->does('Role::Plot'), '... our class does() the correct roles');
ok(!My::Test13->does('Role::Plot'), '... our class does() the correct roles');
ok(!My::Test14->does('Role::Truth'), '... our class does() the correct roles');
ok(!My::Test14->does('Role::Plot'), '... our class does() the correct roles');

is(My::Test11->twist(), 'My::Test::Base::twist -> Role::Truth::twist', '... got the right method return');
is(My::Test12->twist(), 'My::Test::Base::twist -> Role::Plot::twist', '... got the right method return');
ok(!My::Test13->can('twist'), '... no twist method here at all');
is(My::Test14->twist(), 'My::Test::Base::twist', '... got the right method return (from superclass)');

{
    package Role::Reality;
    use strict;
    use warnings;
    use Moose::Role;

    ::throws_ok {    
        with 'Role::Plot';
    } qr/A local method of the same name as been found/, 
    '... could not compose roles here, it dies';

    sub twist {
        'Role::Reality::twist';
    }
}    

ok(Role::Reality->meta->has_method('twist'), '... the twist method has not been added');
ok(!Role::Reality->meta->does_role('Role::Plot'), '... our role does() the correct roles');
is(Role::Reality->meta->get_method('twist')->(), 
    'Role::Reality::twist', 
    '... the twist method returns the right value');
