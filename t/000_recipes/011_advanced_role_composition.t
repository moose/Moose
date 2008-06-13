use strict;
use warnings;
use Test::More skip_all => 'not working yet';
use Class::MOP;

# follow is original code
{
    package Restartable;
    use Moose::Role;

    has 'is_paused' => (
        is      => 'rw',
        isa     => 'Boo',
        default => 0,
    );

    requires 'save_state', 'load_state';

    sub stop { }

    sub start { }

    package Restartable::ButUnreliable;
    use Moose::Role;

    with 'Restartable' => {
        alias => {
            stop  => '_stop',
            start => '_start'
        }
    };

    sub stop {
        my $self = shift;

        $self->explode() if rand(1) > .5;

        $self->_stop();
    }

    sub start {
        my $self = shift;

        $self->explode() if rand(1) > .5;

        $self->_start();
    }

    package Restartable::ButBroken;
    use Moose::Role;

    with 'Restartable' => { excludes => [ 'stop', 'start' ] };

    sub stop {
        my $self = shift;

        $self->explode();
    }

    sub start {
        my $self = shift;

        $self->explode();
    }
}

# follow is test
do {
    my $unreliable = Moose::Meta::Class->create_anon_class(
        superclasses => [],
        roles        => [qw/Restartable::ButUnreliable/],
        methods      => {
            explode      => sub { },    # nop.
            'save_state' => sub { },
            'load_state' => sub { },
        },
    )->new_object();
    ok $unreliable, 'Restartable::ButUnreliable based class';
    can_ok $unreliable, qw/start stop/, '... can call start and stop';
};

do {
    my $cnt = 0;
    my $broken = Moose::Meta::Class->create_anon_class(
        superclasses => [],
        roles        => [qw/Restartable::ButBroken/],
        methods      => {
            explode => sub { $cnt++ },
            'save_state' => sub { },
            'load_state' => sub { },
        },
    )->new_object();
    ok $broken, 'Restartable::ButBroken based class';
    $broken->start();
    is $cnt, 1, '... start is exploded';
    $broken->stop();
    is $cnt, 2, '... stop is also exploeded';
};
