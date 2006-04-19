#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}


{
    package Foo::Meta;
    use strict;
    use warnings;

    use base 'Moose::Meta::Class';
    
    package Foo;
    use strict;
    use warnings;
    use metaclass 'Foo::Meta';
    ::use_ok('Moose');
}

isa_ok(Foo->meta, 'Foo::Meta');

{
    package Bar::Meta;
    use strict;
    use warnings;
    
    use base 'Class::MOP::Class';
    
    package Bar;
    use strict;
    use warnings;
    use metaclass 'Bar::Meta';
    eval 'use Moose;';
    ::ok($@, '... could not load moose without correct metaclass');
    ::like($@, qr/^Whoops\, not møøsey enough/, '... got the right error too');
}
