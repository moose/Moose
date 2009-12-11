#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Moose::Util', ':all');
}

{   package SCBR::Role;
    use Moose::Role;
}

{   package SCBR::A;
    use Moose;
}
is search_class_by_role('SCBR::A', 'SCBR::Role'), undef, '... not found role returns undef';

{   package SCBR::B;
    use Moose;
    extends 'SCBR::A';
    with 'SCBR::Role';
}
is search_class_by_role('SCBR::B', 'SCBR::Role'), 'SCBR::B', '... class itself returned if it does role';

{   package SCBR::C;
    use Moose;
    extends 'SCBR::B';
}
is search_class_by_role('SCBR::C', 'SCBR::Role'), 'SCBR::B', '... nearest class doing role returned';

{   package SCBR::D;
    use Moose;
    extends 'SCBR::C';
    with 'SCBR::Role';
}
is search_class_by_role('SCBR::D', 'SCBR::Role'), 'SCBR::D', '... nearest class being direct class returned';

done_testing;
