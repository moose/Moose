use strict;
use warnings;

use Test::Exception;
use Test::More;

use Test::Requires {
    'Test::Output' => '0.01',
};

# All tests are wrapped with lives_and because the stderr output tests will
# otherwise eat exceptions, and the test just dies silently.

{
    package Role;

    use Moose::Role;

    sub thing { }
}

{
    package Foo;

    use Moose;

    ::lives_and(
        sub {
            ::stderr_like{ has foo => (
                    traits => ['String'],
                    is     => 'ro',
                    isa    => 'Str',
                );
                }
                qr{\QAllowing a native trait to automatically supply a default is deprecated. You can avoid this warning by supply a default, builder, or making the attribute required at t/010_basics/030_deprecations.t line},
                'Not providing a default for native String trait warns';

            ::stderr_is{ has bar => (
                    traits  => ['Bool'],
                    isa     => 'Bool',
                    default => q{},
                );
                } q{}, 'No warning when _default_is is set';

            ::stderr_like{ Foo->new->bar }
                qr{\QThe bar method in the Foo class was automatically created by the native delegation trait for the bar attribute. This "default is" feature is deprecated. Explicitly set "is" or define accessor names to avoid this at t/010_basics/030_deprecations.t line},
                'calling a reader on a method created by a _default_is warns';

            ::stderr_like{ with 'Role' =>
                    { excludes => ['thing'], alias => { thing => 'thing2' } };
                }
                qr/\QThe alias and excludes options for role application have been renamed -alias and -excludes (Foo is consuming Role - do you need to upgrade Foo?)/,
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
    );
}

{
    package Pack1;

    use Moose;

    ::lives_and(
        sub {
            ::stderr_is{ has foo => (
                    traits  => ['String'],
                    is      => 'ro',
                    isa     => 'Str',
                    builder => '_build_foo',
                );
                } q{},
                'Providing a builder for a String trait avoids default default warning';

            has bar => (
                traits  => ['String'],
                reader  => '_bar',
                isa     => 'Str',
                default => q{},
            );

            ::ok(
                !Pack1->can('bar'),
                'no default is assigned when reader is provided'
            );

            ::stderr_is{ Pack1->new->_bar } q{},
                'Providing a reader for a String trait avoids default is warning';
        }
    );

    sub _build_foo { q{} }
}

{
    package Pack2;

    use Moose;

    ::lives_and(
        sub {
            ::stderr_is{ has foo => (
                    traits   => ['String'],
                    is       => 'ro',
                    isa      => 'Str',
                    required => 1,
                );
                } q{},
                'Making a String trait required avoids default default warning';

            has bar => (
                traits  => ['String'],
                writer  => '_bar',
                isa     => 'Str',
                default => q{},
            );

            ::ok(
                !Pack2->can('bar'),
                'no default is assigned when writer is provided'
            );

            ::stderr_is{ Pack2->new( foo => 'x' )->_bar('x') }
                q{},
                'Providing a writer for a String trait avoids default is warning';
        }
    );
}

{
    package Pack3;

    use Moose;

    ::lives_and(
        sub {
            ::stderr_is{ has foo => (
                    traits     => ['String'],
                    is         => 'ro',
                    isa        => 'Str',
                    lazy_build => 1,
                );
                } q{},
                'Making a String trait lazy_build avoids default default warning';

            has bar => (
                traits   => ['String'],
                accessor => '_bar',
                isa      => 'Str',
                default  => q{},
            );

            ::ok(
                !Pack3->can('bar'),
                'no default is assigned when accessor is provided'
            );

            ::stderr_is{ Pack3->new->_bar }
                q{},
                'Providing a accessor for a String trait avoids default is warning';
        }
    );

    sub _build_foo { q{} }
}

done_testing;

