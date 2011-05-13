use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moose;

    has bar => (
        is       => 'ro',
        weak_ref => 1,
    );
}

{
    package MyScopeGuard;

    sub new {
        my ($class, $cb) = @_;
        bless { cb => $cb }, $class;
    }

    sub DESTROY { shift->{cb}->() }
}

{
    my $destroyed = 0;

    my $foo = do {
        my $bar = MyScopeGuard->new(sub { $destroyed++ });
        my $foo = Foo->new({ bar => $bar });
        my $clone = $foo->meta->clone_object($foo);

        is $destroyed, 0;

        $clone;
    };

    isa_ok($foo, 'Foo');
    is $foo->bar, undef;
    is $destroyed, 1;
}

done_testing;
