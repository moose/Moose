#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;
use Test::Exception;

BEGIN {
    use_ok('Moose');
    use_ok('Moose::Role');    
}

=pod

The idea and examples for this feature are taken
from the Fortress spec.

http://research.sun.com/projects/plrg/fortress0903.pdf

trait OrganicMolecule extends Molecule 
    excludes { InorganicMolecule } 
end 
trait InorganicMolecule extends Molecule end 

=cut

{
    package Molecule;
    use strict;
    use warnings;
    use Moose::Role;

    package Molecule::Organic;
    use strict;
    use warnings;
    use Moose::Role;
    
    with 'Molecule';
    excludes 'Molecule::Inorganic';
    
    package Molecule::Inorganic;
    use strict;
    use warnings;
    use Moose::Role;     
    
    with 'Molecule';       
}

ok(Molecule::Organic->meta->excludes_role('Molecule::Inorganic'), '... Molecule::Organic exludes Molecule::Inorganic');
is_deeply(
   [ Molecule::Organic->meta->get_excluded_roles_list() ], 
   [ 'Molecule::Inorganic' ],
   '... Molecule::Organic exludes Molecule::Inorganic');

{
    package My::Test1;
    use strict;
    use warnings;
    use Moose;
    
    ::lives_ok {
        with 'Molecule::Organic';
    } '... adding the role (w/ excluded roles) okay';

    package My::Test2;
    use strict;
    use warnings;
    use Moose;
    
    ::throws_ok {
        with 'Molecule::Organic', 'Molecule::Inorganic';
    } qr/Conflict detected: Class::MOP::Class::__ANON__::SERIAL::1 excludes role \'Molecule::Inorganic\'/, 
    '... adding the role w/ excluded role conflict dies okay';    
    
    package My::Test3;
    use strict;
    use warnings;
    use Moose;
    
    ::lives_ok {
        with 'Molecule::Organic';
    } '... adding the role (w/ excluded roles) okay';   
    
    ::throws_ok {
        with 'Molecule::Inorganic';
    } qr/Conflict detected: My::Test3 excludes role 'Molecule::Inorganic'/, 
    '... adding the role w/ excluded role conflict dies okay'; 
}

ok(My::Test1->does('Molecule::Organic'), '... My::Test1 does Molecule::Organic');
ok(My::Test1->meta->excludes_role('Molecule::Inorganic'), '... My::Test1 excludes Molecule::Organic');
ok(!My::Test2->does('Molecule::Organic'), '... ! My::Test2 does Molecule::Organic');
ok(!My::Test2->does('Molecule::Inorganic'), '... ! My::Test2 does Molecule::Inorganic');
ok(My::Test3->does('Molecule::Organic'), '... My::Test3 does Molecule::Organic');
ok(My::Test3->meta->excludes_role('Molecule::Inorganic'), '... My::Test3 excludes Molecule::Organic');
ok(!My::Test3->does('Molecule::Inorganic'), '... ! My::Test3 does Molecule::Inorganic');









