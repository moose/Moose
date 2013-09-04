#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Moose ();
use Module::Runtime 'module_notional_filename';

sub inc_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($class) = @_;
    is($INC{module_notional_filename($class)}, '(set by Moose)');
}

sub no_inc_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($class) = @_;
    ok(!exists $INC{module_notional_filename($class)});
}

{
    no_inc_ok('Foo');
    my $meta = Moose::Meta::Class->create('Foo');
    inc_ok('Foo');
}
inc_ok('Foo');

{
    no_inc_ok('Bar');
    ok(!exists $INC{module_notional_filename('Bar')});
    my $meta = Class::MOP::Package->create('Bar');
    inc_ok('Bar');
}
inc_ok('Bar');

my $anon_name;
{
    my $meta = Moose::Meta::Class->create_anon_class;
    $anon_name = $meta->name;
    inc_ok($anon_name);
}
no_inc_ok($anon_name);

{
    no_inc_ok('Real::Package');
    require Real::Package;
    like($INC{module_notional_filename('Real::Package')}, qr{t.lib.Real.Package\.pm$});
    my $meta = Moose::Meta::Class->create('Real::Package');
    like($INC{module_notional_filename('Real::Package')}, qr{t.lib.Real.Package\.pm$});
}
like($INC{module_notional_filename('Real::Package')}, qr{t.lib.Real.Package\.pm$});

BEGIN { no_inc_ok('UseMoose') }
{
    package UseMoose;
    use Moose;
}
BEGIN { inc_ok('UseMoose') }

BEGIN { no_inc_ok('UseMooseRole') }
{
    package UseMooseRole;
    use Moose::Role;
}
BEGIN { inc_ok('UseMooseRole') }

BEGIN {
    package My::Custom::Moose;
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        also => ['Moose'],
    );
    $INC{::module_notional_filename(__PACKAGE__)} = __FILE__;
}

BEGIN { no_inc_ok('UseMooseCustom') }
{
    package UseMooseCustom;
    use My::Custom::Moose;
}
BEGIN { inc_ok('UseMooseCustom') }

BEGIN {
    package My::Custom::Moose::Role;
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        also => ['Moose::Role'],
    );
    $INC{::module_notional_filename(__PACKAGE__)} = __FILE__;
}

BEGIN { no_inc_ok('UseMooseCustomRole') }
{
    package UseMooseCustomRole;
    use My::Custom::Moose::Role;
}
BEGIN { inc_ok('UseMooseCustomRole') }

done_testing;
