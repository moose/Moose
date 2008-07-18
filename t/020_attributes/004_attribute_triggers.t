#!/usr/bin/perl

use strict;
use warnings;

use Scalar::Util 'isweak';

use Test::More tests => 43;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
    package Foo;
    use Moose;
    
    has 'bar' => (is      => 'rw', 
                  isa     => 'Maybe[Bar]',
                  trigger => sub { 
                      my ($self, $bar) = @_;
                      $bar->foo($self) if defined $bar;
                  });
                  
    has 'baz' => (writer => 'set_baz',
                  reader => 'get_baz',
                  isa    => 'Baz',
                  trigger => sub { 
                      my ($self, $baz) = @_;
                      $baz->foo($self);
                  });              
     
                  
    package Bar;
    use Moose;
    
    has 'foo' => (is => 'rw', isa => 'Foo', weak_ref => 1);           
    
    package Baz;
    use Moose;
    
    has 'foo' => (is => 'rw', isa => 'Foo', weak_ref => 1);           
}

{
    my $foo = Foo->new;
    isa_ok($foo, 'Foo');

    my $bar = Bar->new;
    isa_ok($bar, 'Bar');

    my $baz = Baz->new;
    isa_ok($baz, 'Baz');

    lives_ok {
        $foo->bar($bar);
    } '... did not die setting bar';

    is($foo->bar, $bar, '... set the value foo.bar correctly');
    is($bar->foo, $foo, '... which in turn set the value bar.foo correctly');

    ok(isweak($bar->{foo}), '... bar.foo is a weak reference');
    
    lives_ok {
        $foo->bar(undef);
    } '... did not die un-setting bar';

    is($foo->bar, undef, '... set the value foo.bar correctly');
    is($bar->foo, $foo, '... which in turn set the value bar.foo correctly');    

    # test the writer

    lives_ok {
        $foo->set_baz($baz);
    } '... did not die setting baz';

    is($foo->get_baz, $baz, '... set the value foo.baz correctly');
    is($baz->foo, $foo, '... which in turn set the value baz.foo correctly');

    ok(isweak($baz->{foo}), '... baz.foo is a weak reference');
}

{
    my $bar = Bar->new;
    isa_ok($bar, 'Bar');

    my $baz = Baz->new;
    isa_ok($baz, 'Baz');
    
    my $foo = Foo->new(bar => $bar, baz => $baz);
    isa_ok($foo, 'Foo');    

    is($foo->bar, $bar, '... set the value foo.bar correctly');
    is($bar->foo, $foo, '... which in turn set the value bar.foo correctly');

    ok(isweak($bar->{foo}), '... bar.foo is a weak reference');

    is($foo->get_baz, $baz, '... set the value foo.baz correctly');
    is($baz->foo, $foo, '... which in turn set the value baz.foo correctly');

    ok(isweak($baz->{foo}), '... baz.foo is a weak reference');
}

# before/around/after triggers
{
    package Fweet;
    use Moose;

    has calls => (
        is      => 'ro',
        isa     => 'ArrayRef',
        default => sub {[]},
    );

    sub called {
        my ($self, $str, @args) = @_;
        push(@{$self->calls}, $str);
    }

    has noise => (
        is => 'rw',
        default => 'Sartak',
        trigger => {
            before => sub {
                $_[0]->called('before');
            },
            around => sub {
                my ($ori, $self, $val, @whatever) = @_;
                $self->called('around');
                $ori->($self, $val.'-diddly', @whatever);
            },
            after => sub {
                $_[0]->called('after');
            },
        },
    );
}

sub fancy_trigger_tests
{
    my $type = shift;
    my $blah;
    ::lives_ok {
        $blah = Fweet->new;
    } "... $type constructor";
    my $expected_calls = [qw(before around after)];

    is_deeply($blah->calls, $expected_calls, "$type default triggered");
    is($blah->noise, 'Sartak-diddly', "$type default around modified value");
    @{$blah->calls} = ();

    $blah->noise('argle-bargle');
    is_deeply($blah->calls, $expected_calls, "$type set triggered");
    is($blah->noise, 'argle-bargle-diddly', "$type set around modified value");

    $blah = Fweet->new(noise => 'woot');
    is_deeply($blah->calls, $expected_calls, "$type constructor triggered");
    is($blah->noise, 'woot-diddly', "$type constructor around modified value");
}

{
  fancy_trigger_tests('normal');
  ::lives_ok {
    Fweet->meta->make_immutable;
  } '... make_immutable works';
  fancy_trigger_tests('inline');
}

# some errors

{
    package Bling;
    use Moose;

    ::dies_ok {
        has('bling' => (is => 'rw', trigger => {FAIL => sub {}}));
    } '... hash specifier has to be before/around/after';

    ::dies_ok {
        has('bling' => (is => 'rw', trigger => {around => 'FAIL'}));
    } '... hash specifier value must be CODE ref';
    
    ::dies_ok { 
        has('bling' => (is => 'rw', trigger => 'Fail'));
    } '... a trigger must be a CODE or HASH ref';
    
    ::dies_ok { 
        has('bling' => (is => 'rw', trigger => []));
    } '... a trigger must be a CODE or HASH ref';    
}


