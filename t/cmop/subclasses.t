use strict;
use warnings;
use Test::More;
use Class::MOP;

do {
    package Grandparent;
    use metaclass;

    package Parent;
    use metaclass;
    use parent -norequire => 'Grandparent';

    package Uncle;
    use metaclass;
    use parent -norequire => 'Grandparent';

    package Son;
    use metaclass;
    use parent -norequire => 'Parent';

    package Daughter;
    use metaclass;
    use parent -norequire => 'Parent';

    package Cousin;
    use metaclass;
    use parent -norequire => 'Uncle';
};

is_deeply([sort Grandparent->meta->subclasses], ['Cousin', 'Daughter', 'Parent', 'Son', 'Uncle']);
is_deeply([sort Parent->meta->subclasses],      ['Daughter', 'Son']);
is_deeply([sort Uncle->meta->subclasses],       ['Cousin']);
is_deeply([sort Son->meta->subclasses],         []);
is_deeply([sort Daughter->meta->subclasses],    []);
is_deeply([sort Cousin->meta->subclasses],      []);

is_deeply([sort Grandparent->meta->direct_subclasses], ['Parent', 'Uncle']);
is_deeply([sort Parent->meta->direct_subclasses],      ['Daughter', 'Son']);
is_deeply([sort Uncle->meta->direct_subclasses],       ['Cousin']);
is_deeply([sort Son->meta->direct_subclasses],         []);
is_deeply([sort Daughter->meta->direct_subclasses],    []);
is_deeply([sort Cousin->meta->direct_subclasses],      []);

done_testing;
