#!/usr/bin/perl
# https://rt.cpan.org/Ticket/Display.html?id=46347
use strict;
use Test::More tests =>14;
use Test::Exception;

{ package My::Role1;
  use Moose::Role;
  requires 'test_output';
}
{ package My::Role2;
  use Moose::Role;
  has test_output => (is => 'rw');
  with 'My::Role1';
}
{ package My::Role3;
  use Moose::Role;
  sub test_output {}
  with 'My::Role1';
}
{ package My::Role4;
  use Moose::Role;
  has test_output => (is => 'rw');
}
{ package My::Role5;
  use Moose::Role;
  sub test_output {}
}
{ package My::Base1;
  use Moose;
  has test_output => (is => 'rw');
}
{ package My::Base2;
  use Moose;
  sub test_output {}
}

# Roles providing attributes/methods should satisfy requires() of other
# roles they consume.
{ local $TODO = "role attributes don't satisfy method requirements";
    lives_ok { package My::Test1; use Moose; with 'My::Role2'; } 
    'role2(provides attribute) consumes role1';
}

lives_ok { package My::Test2; use Moose; with 'My::Role3'; }
    'role3(provides method) consumes role1';

# As I understand the design, Roles composed in the same with() statement
# should NOT demonstrate ordering dependency. Alter these tests if that
# assumption is false. -Vince Veselosky
{ local $TODO = "role attributes don't satisfy method requirements";
    lives_ok { package My::Test3; use Moose; with 'My::Role4','My::Role1'; }
    'class consumes role4(provides attribute), role1';
}

{ local $TODO = "role attributes don't satisfy method requirements";
    lives_ok { package My::Test4; use Moose; with 'My::Role1','My::Role4'; }
    'class consumes role1, role4(provides attribute)';
}

lives_ok { package My::Test5; use Moose; with 'My::Role5','My::Role1'; }
    'class consumes role5(provides method), role1';

lives_ok { package My::Test6; use Moose; with 'My::Role1','My::Role5'; }
    'class consumes role1, role5(provides method)';

# Inherited methods/attributes should satisfy requires(), as long as 
# extends() comes first in code order.
lives_ok {package My::Test7; use Moose; extends 'My::Base1'; with 'My::Role1';}
    'class extends base1(provides attribute), consumes role1';

lives_ok {package My::Test8; use Moose; extends 'My::Base2'; with 'My::Role1';}
    'class extends base2(provides method), consumes role1';

# Attributes/methods implemented in class should satisfy requires()
lives_ok {package My::Test9; use Moose; has 'test_output',is=>'rw'; with 'My::Role1';}
    'class provides attribute, consumes role1';

lives_ok {package My::Test10; use Moose; sub test_output{} with 'My::Role1'; }
    'class provides method, consumes role1';

# Roles composed in separate with() statements SHOULD demonstrate ordering 
# dependency. See comment with tests 3-6 above.
lives_ok { package My::Test11; use Moose; with 'My::Role4'; with 'My::Role1';}
    'class consumes role4(provides attribute); consumes role1';

dies_ok { package My::Test12; use Moose; with 'My::Role1'; with 'My::Role4';}
    'class consumes role1; consumes role4(provides attribute)';

lives_ok { package My::Test13; use Moose; with 'My::Role5'; with 'My::Role1';}
    'class consumes role5(provides method); consumes role1';

dies_ok { package My::Test14; use Moose; with 'My::Role1'; with 'My::Role5'; }
    'class consumes role1; consumes role5(provides method)';


