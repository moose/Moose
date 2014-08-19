use strict;
use warnings;

use Test::More;

{
    package First;
    use Moose;

    sub foo {
        ::BAIL_OUT('First::foo called twice') if $main::seen{'First::foo'}++;
        return '1';
    }

    sub bar {
        ::BAIL_OUT('First::bar called twice') if $main::seen{'First::bar'}++;
        return '1';
    }

    sub baz {
        ::BAIL_OUT('First::baz called twice') if $main::seen{'First::baz'}++;
        return '1';
    }
}

{
    package Second;
    use Moose;
    extends qw(First);

    sub foo {
        ::BAIL_OUT('Second::foo called twice') if $main::seen{'Second::foo'}++;
        return '2' . super();
    }

    sub bar {
        ::BAIL_OUT('Second::bar called twice') if $main::seen{'Second::bar'}++;
        return '2' . ( super() || '' );
    }

    override baz => sub {
        ::BAIL_OUT('Second::baz called twice') if $main::seen{'Second::baz'}++;
        return '2' . super();
    };
}

{
    package Third;
    use Moose;
    extends qw(Second);

    sub foo { return '3' . ( super() || '' ) }

    override bar => sub {
        ::BAIL_OUT('Third::bar called twice') if $main::seen{'Third::bar'}++;
        return '3' . super();
    };

    override baz => sub {
        ::BAIL_OUT('Third::baz called twice') if $main::seen{'Third::baz'}++;
        return '3' . super();
    };
}

is( Third->new->foo, '3' );
is( Third->new->bar, '32' );
is( Third->new->baz, '321' );

done_testing;
