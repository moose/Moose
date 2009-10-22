#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

use Moose::Meta::Role::Application::RoleSummation;
use Moose::Meta::Role::Composite;

{
    package Role::Foo;
    use Moose::Role;
    requires_class 'Class::Foo';

    package Role::Bar;
    use Moose::Role;
    requires_class 'Class::Bar';

    package Class::Foo;
    use Moose;
    with 'Role::Foo';

    package Class::Bar;
    use Moose;
    with 'Role::Bar';

}

fail "This needs a test";