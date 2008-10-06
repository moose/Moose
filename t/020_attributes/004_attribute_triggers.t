#!/usr/bin/perl

use strict;
use warnings;

use Scalar::Util 'isweak';

use Test::More tests => 36;
use Test::Exception;



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

# some errors

{
    package Bling;
    use Moose;
    
    ::dies_ok { 
        has('bling' => (is => 'rw', trigger => 'Fail'));
    } '... a trigger must be a CODE ref';
    
    ::dies_ok { 
        has('bling' => (is => 'rw', trigger => []));
    } '... a trigger must be a CODE ref';    
}

# Triggers do not fire on built values

{
    package Blarg;
    use Moose;

    our %trigger_calls;
    our %trigger_vals;
    has foo => (is => 'rw', default => sub { 'default foo value' },
                trigger => sub { my ($self, $val, $attr) = @_;
                                 $trigger_calls{foo}++;
                                 $trigger_vals{foo} = $val });
    has bar => (is => 'rw', lazy_build => 1,
                trigger => sub { my ($self, $val, $attr) = @_;
                                 $trigger_calls{bar}++;
                                 $trigger_vals{bar} = $val });
    sub _build_bar { return 'default bar value' }
    has baz => (is => 'rw', builder => '_build_baz',
                trigger => sub { my ($self, $val, $attr) = @_;
                                 $trigger_calls{baz}++;
                                 $trigger_vals{baz} = $val });
    sub _build_baz { return 'default baz value' }
}

{
    my $blarg;
    lives_ok { $blarg = Blarg->new; } 'Blarg->new() lives';
    ok($blarg, 'Have a $blarg');
    foreach my $attr (qw/foo bar baz/) {
        is($blarg->$attr(), "default $attr value", "$attr has default value");
    }
    is_deeply(\%Blarg::trigger_calls, {}, 'No triggers fired');
    foreach my $attr (qw/foo bar baz/) {
        $blarg->$attr("Different $attr value");
    }
    is_deeply(\%Blarg::trigger_calls, { map { $_ => 1 } qw/foo bar baz/ }, 'All triggers fired once on assign');
    is_deeply(\%Blarg::trigger_vals, { map { $_ => "Different $_ value" } qw/foo bar baz/ }, 'All triggers given assigned values');

    lives_ok { $blarg => Blarg->new( map { $_ => "Yet another $_ value" } qw/foo bar baz/ ) } '->new() with parameters';
    is_deeply(\%Blarg::trigger_calls, { map { $_ => 2 } qw/foo bar baz/ }, 'All triggers fired once on construct');
    is_deeply(\%Blarg::trigger_vals, { map { $_ => "Yet another $_ value" } qw/foo bar baz/ }, 'All triggers given assigned values');
}

