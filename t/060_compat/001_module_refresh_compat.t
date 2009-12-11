#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Test::More;
use Test::Exception;

BEGIN {
    eval "use Module::Refresh;";
    plan skip_all => "Module::Refresh is required for this test" if $@;
}

=pod

First lets test some of our simple example modules ...

=cut

my @modules = qw[Foo Bar MyMooseA MyMooseB MyMooseObject];

do {
    use_ok($_);

    is($_->meta->name, $_, '... initialized the meta correctly');

    lives_ok {
        Module::Refresh->new->refresh_module($_ . '.pm')
    } '... successfully refreshed ' . $_;
} foreach @modules;

=pod

Now, lets try something a little trickier
and actually change the module itself.

=cut

my $test_module_file = 'TestBaz.pm';

my $test_module_source_1 = q|
package TestBaz;
use Moose;
has 'foo' => (is => 'ro', isa => 'Int');
1;
|;

my $test_module_source_2 = q|
package TestBaz;
use Moose;
extends 'Foo';
has 'foo' => (is => 'rw', isa => 'Int');
1;
|;

{
    open FILE, ">", $test_module_file
        || die "Could not open $test_module_file because $!";
    print FILE $test_module_source_1;
    close FILE;
}

use_ok('TestBaz');
is(TestBaz->meta->name, 'TestBaz', '... initialized the meta correctly');
ok(TestBaz->meta->has_attribute('foo'), '... it has the foo attribute as well');
ok(!TestBaz->isa('Foo'), '... TestBaz is not a Foo');

{
    open FILE, ">", $test_module_file
        || die "Could not open $test_module_file because $!";
    print FILE $test_module_source_2;
    close FILE;
}

lives_ok {
    Module::Refresh->new->refresh_module($test_module_file)
} '... successfully refreshed ' . $test_module_file;

is(TestBaz->meta->name, 'TestBaz', '... initialized the meta correctly');
ok(TestBaz->meta->has_attribute('foo'), '... it has the foo attribute as well');
ok(TestBaz->isa('Foo'), '... TestBaz is a Foo');

unlink $test_module_file;

done_testing;
