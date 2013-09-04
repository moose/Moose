#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Moose ();
use Module::Runtime 'module_notional_filename';

{
    ok(!exists $INC{module_notional_filename('Foo')});
    my $meta = Moose::Meta::Class->create('Foo');
    like($INC{module_notional_filename('Foo')}, qr{Class.MOP.Package\.pm$});
}
like($INC{module_notional_filename('Foo')}, qr{Class.MOP.Package\.pm$});

{
    ok(!exists $INC{module_notional_filename('Bar')});
    my $meta = Class::MOP::Package->create('Bar');
    like($INC{module_notional_filename('Bar')}, qr{Class.MOP.Package\.pm$});
}
like($INC{module_notional_filename('Bar')}, qr{Class.MOP.Package\.pm$});

my $anon_name;
{
    my $meta = Moose::Meta::Class->create_anon_class;
    $anon_name = $meta->name;
    like($INC{module_notional_filename($anon_name)}, qr{Class.MOP.Package\.pm$});
}
ok(!exists $INC{module_notional_filename($anon_name)});

{
    ok(!exists $INC{module_notional_filename('Real::Package')});
    require Real::Package;
    like($INC{module_notional_filename('Real::Package')}, qr{t.lib.Real.Package\.pm$});
    my $meta = Moose::Meta::Class->create('Real::Package');
    like($INC{module_notional_filename('Real::Package')}, qr{t.lib.Real.Package\.pm$});
}
like($INC{module_notional_filename('Real::Package')}, qr{t.lib.Real.Package\.pm$});

BEGIN { ok(!exists $INC{module_notional_filename('UseMoose')}) }
{
    package UseMoose;
    use Moose;
}
BEGIN { like($INC{module_notional_filename('UseMoose')}, qr{Moose\.pm$}) }

BEGIN { ok(!exists $INC{module_notional_filename('UseMooseRole')}) }
{
    package UseMooseRole;
    use Moose::Role;
}
BEGIN { like($INC{module_notional_filename('UseMooseRole')}, qr{Moose.Role\.pm$}) }

BEGIN {
    package My::Custom::Moose;
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        also => ['Moose'],
    );
    $INC{::module_notional_filename(__PACKAGE__)} = __FILE__;
}

BEGIN { ok(!exists $INC{module_notional_filename('UseMooseCustom')}) }
{
    package UseMooseCustom;
    use My::Custom::Moose;
}
BEGIN { like($INC{module_notional_filename('UseMooseCustom')}, qr{Moose\.pm$}) }

BEGIN {
    package My::Custom::Moose::Role;
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        also => ['Moose::Role'],
    );
    $INC{::module_notional_filename(__PACKAGE__)} = __FILE__;
}

BEGIN { ok(!exists $INC{module_notional_filename('UseMooseCustomRole')}) }
{
    package UseMooseCustomRole;
    use My::Custom::Moose::Role;
}
BEGIN { like($INC{module_notional_filename('UseMooseCustomRole')}, qr{Moose.Role\.pm$}) }

done_testing;
