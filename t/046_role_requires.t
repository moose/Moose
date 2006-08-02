#!/usr/bin/perl

# FIXME
## Add variants for everything
## with delegation

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

# a role requires methods
# this requirement can be satisfied by a matrix multiplication:
# either via an attribute (an accessor or a delegation) 
# or with an "actual" method
# which is provided via either the class, a base class, or a role

###########################
# Keep the noise level down
no warnings 'redefine';
sub Test::Builder::diag { }
###########################


{
    package Role::Requires;
    use Moose::Role;

    requires "foo";

    package Role::Provides;
    use Moose::Role;

    sub foo { __PACKAGE__ . "::foo" }

    package Class::Provides;
    use Moose;

    sub foo { __PACKAGE__ . "::foo" }
}

{
    package Class::Provider::class::Type::method::WithRole::requires;
    use Moose;
    
    sub foo { __PACKAGE__ . "::method::foo" }

    ::lives_ok { with 'Role::Requires' } "composed role that requires foo";

    ::ok( __PACKAGE__->does('Role::Requires'), "package does role" );

    ::is( __PACKAGE__->new->foo, __PACKAGE__ . "::method::foo", "foo method is from this class" );
}

{
    package Class::Provider::class::Type::method::WithRole::provides;
    use Moose;
    
    sub foo { __PACKAGE__ . "::method::foo" }

    ::lives_ok { with 'Role::Provides' } "composed role that provides foo";
    
    ::ok( __PACKAGE__->does('Role::Provides'), "package does role" );

    ::is( __PACKAGE__->new->foo, __PACKAGE__ . "::method::foo", "foo method is from this class" );
}

{
    package Class::Provider::class::Type::attr::WithRole::requires;
    use Moose;
    
    ::dies_ok { with 'Role::Requires' } "can't compose the role that requires foo yet";
    
    has foo => (
        isa => "Str",
        is  => "rw",
        default => __PACKAGE__ . "::attr::foo",
    );

    ::lives_ok { with 'Role::Requires' } "composed role that requires foo";

    ::ok( __PACKAGE__->does('Role::Requires'), "package does role" );

    ::is( __PACKAGE__->new->foo, __PACKAGE__ . "::attr::foo", "foo method is from an attr in this class" );
}

{
    package Class::Provider::class::Type::attr::WithRole::provides;
    use Moose;
    
    has foo => (
        isa => "Str",
        is  => "rw",
        default => __PACKAGE__ . "::attr::foo",
    );    
    
    ::lives_ok { with 'Role::Provides' } "composed role that provides foo";
    
    ::ok( __PACKAGE__->does('Role::Provides'), "package does role" );

    ::is( __PACKAGE__->new->foo, __PACKAGE__ . "::attr::foo", "foo method is from an attr in this class" );
}

{
    package Class::Provider::baseclass::Type::method::WithRole::requires;
    use Moose;

    ::dies_ok { with 'Role::Requires' } "can't compose the role that requires foo yet";

    extends "Class::Provides";

    ::lives_ok { with 'Role::Requires' } "composed role that requires foo, foo satisfied by base class";
    ::ok( __PACKAGE__->does('Role::Requires'), "package does role" );

    ::is( __PACKAGE__->new->foo, "Class::Provides::foo", "method came from base class" );
}

{
    package Class::Provider::baseclass::Type::method::WithRole::provides;
    use Moose;
    
    extends "Class::Provides";

    ::lives_ok { with 'Role::Provides' } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provides'), "package does role" );

    ::is( __PACKAGE__->new->foo, "Class::Provides::foo", "role didn't overwrite method from base class" );
}


{
    package Role::Provider::role::Type::method::WithRole::requires;
    use Moose::Role;

    with "Role::Requires";

    sub foo { __PACKAGE__ . "::method::foo" }
}

{
    package Role::Provider::role::Type::attr::WithRole::requires;
    use Moose::Role;

    with "Role::Requires";

    has foo => (
        isa => "Str",
        is  => "rw",
        default => __PACKAGE__ . "::attr::foo",
    );
}

{
    package Role::Provider::role::Type::attr::WithRole::provides;
    use Moose::Role;

    with "Role::Provides";

    has foo => (
        isa => "Str",
        is  => "rw",
        default => __PACKAGE__ . "::attr::foo",
    );
}


{
    package Role::Provider::baserole::Type::method;
    use Moose::Role;

    with "Role::Provides";
}


{
    package Role::Provider::baserole::Type::attr::WithRole::requires::base;
    use Moose::Role;

    with "Role::Requires";

    has foo => (
        isa => "Str",
        is  => "rw",
        default => __PACKAGE__ . "::attr::foo",
    ); 

    package Role::Provider::baserole::Type::attr::WithRole::requires;
    use Moose::Role;

    with "Role::Provider::baserole::Type::attr::WithRole::requires::base";

    package Role::Provider::baserole::Type::attr::WithRole::requires::overridden;
    use Moose::Role;

    with "Role::Provider::baserole::Type::attr::WithRole::requires::base";

    sub foo { __PACKAGE__ . "::method::foo" }
}

{
    package Role::Provider::baserole::Type::method::WithRole::requires::base;
    use Moose::Role;

    with "Role::Requires";

    sub foo { __PACKAGE__ . "::method::foo" }

    package Role::Provider::baserole::Type::method::WithRole::requires::overridden;
    use Moose::Role;

    with "Role::Provider::baserole::Type::method::WithRole::requires::base";

    has foo => (
        isa => "Str",
        is  => "rw",
        default => __PACKAGE__ . "::attr::foo",
    );
}

##############################


{
    package Role::Provider::role::Type::method::WithRole::requires::ClassWithNothing;
    use Moose;
    
    ::lives_ok { with "Role::Provider::role::Type::method::WithRole::requires" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provider::role::Type::method::WithRole::requires'), "package does role" );
    ::ok( __PACKAGE__->does('Role::Requires'), "package does base role" );

    ::is(  __PACKAGE__->new->foo, "Role::Provider::role::Type::method::WithRole::requires::method::foo", "foo was defined in the role" );
}

{
    package Role::Provider::role::Type::method::WithRole::requires::ClassWithMethod;
    use Moose;

    ::lives_ok { with "Role::Provider::role::Type::method::WithRole::requires" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Requires'), "package does role" );

    sub foo { __PACKAGE__ . "::method::foo" }

    ::is(  __PACKAGE__->new->foo, __PACKAGE__ . "::method::foo", "foo was defined in the class" );
}

{
    package Role::Provider::role::Type::method::WithRole::requires::ClassWithBase;
    use Moose;

    extends "Class::Provides";

    ::lives_ok { with "Role::Provider::role::Type::method::WithRole::requires" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Requires'), "package does role" );

    ::is(  __PACKAGE__->new->foo, "Class::Provides::foo", "foo was defined in the base class" );
}

##

{
    package Role::Provider::role::Type::attr::WithRole::requires::ClassWithNothing;
    use Moose;

    ::lives_ok { with "Role::Provider::role::Type::attr::WithRole::requires" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Requires'), "package does role" );

    ::is( eval {  __PACKAGE__->new->foo }, "Role::Provider::role::Type::attr::WithRole::requires::attr::foo", "foo was defined in the class" );
}

{
    package Role::Provider::role::Type::attr::WithRole::requires::ClassWithMethod;
    use Moose;

    ::lives_ok { with "Role::Provider::role::Type::attr::WithRole::requires" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Requires'), "package does role" );

    sub foo { __PACKAGE__ . "::method::foo" }

    local our $TODO = "Attribute vs. method shadowing not yet clear";
    ::is(  __PACKAGE__->new->foo, __PACKAGE__ . "::method::foo", "foo was defined in the class" );
}

{
    package Role::Provider::role::Type::attr::WithRole::requires::ClassWithBase;
    use Moose;
    
    extends "Class::Provides";

    ::lives_ok { with "Role::Provider::role::Type::attr::WithRole::requires" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Requires'), "package does role" );

    local our $TODO = "Attribute vs. method shadowing not yet clear";
    ::is(  __PACKAGE__->new->foo, "Class::Provides::foo", "foo was defined in the base class" );
}

##

{
    package Role::Provider::role::Type::attr::WithRole::provides::ClassWithNothing;
    use Moose;
    
    ::lives_ok { with "Role::Provider::role::Type::attr::WithRole::provides" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provides'), "package does role" );

    ::is(  __PACKAGE__->new->foo, "Role::Provider::role::Type::attr::WithRole::provides::attr::foo", "foo was defined in the role" );
}

{
    package Role::Provider::role::Type::attr::WithRole::provides::ClassWithMethod;
    use Moose;

    ::lives_ok { with "Role::Provider::role::Type::attr::WithRole::provides" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provides'), "package does role" );

    sub foo { __PACKAGE__ . "::method::foo" }

    local our $TODO = "Attribute vs. method shadowing not yet clear";
    ::is(  __PACKAGE__->new->foo, __PACKAGE__ . "::method::foo", "foo was defined in the class" );
}

{
    package Role::Provider::role::Type::attr::WithRole::provides::ClassWithBase;
    use Moose;
    
    extends "Class::Provides";

    ::lives_ok { with "Role::Provider::role::Type::attr::WithRole::provides" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provides'), "package does role" );

    local our $TODO = "Attribute vs. method shadowing not yet clear";
    ::is(  __PACKAGE__->new->foo, "Class::Provides::foo", "foo was defined in the base class" );
}

##

{
    package Role::Provider::baserole::Type::method::ClassWithNothing;
    use Moose;
    
    ::lives_ok { with "Role::Provider::baserole::Type::method" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provides'), "package does role" );

    ::is(  __PACKAGE__->new->foo, "Role::Provides::foo", "foo was defined in the base role" );
}

{
    package Role::Provider::baserole::Type::method::ClassWithMethod;
    use Moose;

    ::lives_ok { with "Role::Provider::baserole::Type::method" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provides'), "package does role" );

    sub foo { __PACKAGE__ . "::method::foo" }

    ::is(  __PACKAGE__->new->foo, __PACKAGE__ . "::method::foo", "foo was defined in the role" );
}

{
    package Role::Provider::baserole::Type::method::ClassWithBase;
    use Moose;
    
    extends "Class::Provides";

    ::lives_ok { with "Role::Provider::baserole::Type::method" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provides'), "package does role" );

    ::is(  __PACKAGE__->new->foo, "Class::Provides::foo", "foo was defined in the base class" );
}

##

{
    package Role::Provider::baserole::Type::attr::WithRole::requires::ClassWithNothing;
    use Moose;
 
    ::lives_ok { with "Role::Provider::baserole::Type::attr::WithRole::requires" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provider::baserole::Type::attr::WithRole::requires'), "package does role" );

    ::is(  eval { __PACKAGE__->new->foo }, "Role::Provider::baserole::Type::attr::WithRole::requires::base::attr::foo", "foo was defined in the base role" );
}

{
    package Role::Provider::baserole::Type::attr::WithRole::requires::ClassWithMethod;
    use Moose;

    ::lives_ok { with "Role::Provider::baserole::Type::attr::WithRole::requires" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provider::baserole::Type::attr::WithRole::requires'), "package does role" );

    sub foo { __PACKAGE__ . "::method::foo" }

    local our $TODO = "Attribute vs. method shadowing not yet clear";
    ::is(  __PACKAGE__->new->foo, __PACKAGE__ . "::method::foo", "foo was defined in the class" );
}

{
    package Role::Provider::baserole::Type::attr::WithRole::requires::ClassWithBase;
    use Moose;

    extends "Class::Provides";

    ::lives_ok { with "Role::Provider::baserole::Type::attr::WithRole::requires" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provider::baserole::Type::attr::WithRole::requires'), "package does role" );

    local our $TODO = "Attribute vs. method shadowing not yet clear";
    ::is(  __PACKAGE__->new->foo, "Class::Provides::foo", "foo was defined in the base class" );
}


##

{
    package Role::Provider::baserole::Type::attr::WithRole::requires::overridden::ClassWithNothing;
    use Moose;

    ::lives_ok { with "Role::Provider::baserole::Type::attr::WithRole::requires::overridden" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provider::baserole::Type::attr::WithRole::requires::overridden'), "package does role" );

    local our $TODO = "Attribute vs. method shadowing not yet clear";
    ::is(  eval {  __PACKAGE__->new->foo}, "Role::Provider::baserole::Type::attr::WithRole::requires::overridden::method::foo", "foo was defined in the overridding role" );
}

{
    package Role::Provider::baserole::Type::attr::WithRole::requires::overridden::ClassWithMethod;
    use Moose;

    ::lives_ok { with "Role::Provider::baserole::Type::attr::WithRole::requires::overridden" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provider::baserole::Type::attr::WithRole::requires::overridden'), "package does role" );

    sub foo { __PACKAGE__ . "::method::foo" }

    local our $TODO = "Attribute vs. method shadowing not yet clear";
    ::is(  __PACKAGE__->new->foo, __PACKAGE__ . "::method::foo", "foo was defined in the class" );
}

{
    package Role::Provider::baserole::Type::attr::WithRole::requires::overridden::ClassWithBase;
    use Moose;

    extends "Class::Provides";

    ::lives_ok { with "Role::Provider::baserole::Type::attr::WithRole::requires::overridden" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provider::baserole::Type::attr::WithRole::requires::overridden'), "package does role" );

    local our $TODO = "Attribute vs. method shadowing not yet clear";
    ::is(  __PACKAGE__->new->foo, "Class::Provides::foo", "foo was defined in the base class" );
}

##

{
    package Role::Provider::baserole::Type::method::WithRole::requires::overridden::ClassWithNothing;
    use Moose;

    ::lives_ok { with "Role::Provider::baserole::Type::method::WithRole::requires::overridden" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provider::baserole::Type::method::WithRole::requires::overridden'), "package does role" );

    ::is(  __PACKAGE__->new->foo, "Role::Provider::baserole::Type::method::WithRole::requires::overridden::attr::foo", "foo was defined in the overriding role" );
}

{
    package Role::Provider::baserole::Type::method::WithRole::requires::overridden::ClassWithMethod;
    use Moose;

    ::lives_ok { with "Role::Provider::baserole::Type::method::WithRole::requires::overridden" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provider::baserole::Type::method::WithRole::requires::overridden'), "package does role" );

    sub foo { __PACKAGE__ . "::method::foo" }

    local our $TODO = "Attribute vs. method shadowing not yet clear";
    ::is(  __PACKAGE__->new->foo, __PACKAGE__ . "::method::foo", "foo was defined in the class" );
}

{
    package Role::Provider::baserole::Type::method::WithRole::requires::overridden::ClassWithBase;
    use Moose;

    extends "Class::Provides";

    ::lives_ok { with "Role::Provider::baserole::Type::method::WithRole::requires::overridden" } "composed role that provides foo";
    ::ok( __PACKAGE__->does('Role::Provider::baserole::Type::method::WithRole::requires::overridden'), "package does role" );

    local our $TODO = "Attribute vs. method shadowing not yet clear";
    ::is(  __PACKAGE__->new->foo, "Class::Provides::foo", "foo was defined in the base class" );
}
