use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Output' => '0.01',
};

{
    package Role;

    use Moose::Role;

    sub thing { }
}

{
    package Foo;

    use Moose;

    ::stderr_like{ has foo => (
            traits => ['String'],
            is     => 'ro',
            isa    => 'Str',
        );
        }
        qr/\QAllowing a native trait to automatically supply a default is deprecated/,
        'Not providing a default for native String trait warns';

    ::stderr_like{ has bar => (
            traits  => ['String'],
            isa     => 'Str',
            default => q{},
        );
        }
        qr/\QAllowing a native trait to automatically supply a value for "is" is deprecated/,
        'Not providing a value for is with native String trait warns';

    ::stderr_like{ with 'Role' =>
            { excludes => ['thing'], alias => { thing => 'thing2' } };
        }
        qr/\QThe alias and excludes options for role application have been renamed -alias and -excludes/,
        'passing excludes or alias with a leading dash warns';
    ::ok(
        !Foo->meta->has_method('thing'),
        'thing method is excluded from role application'
    );
    ::ok(
        Foo->meta->has_method('thing2'),
        'thing2 method is created as alias in role application'
    );
}

done_testing;

