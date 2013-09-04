package Role::BreakOnLoad;
use Moose::Role;

sub meth1 { }

this role has a syntax error and should crash on load.

1;
