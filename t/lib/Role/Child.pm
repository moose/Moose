package Role::Child;
use Moose::Role;

with 'Role::Parent' => { alias => { meth1 => '_aliased', } };

sub meth1 { }

1;
