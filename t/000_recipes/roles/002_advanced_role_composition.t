use strict;
use warnings;
use Test::More tests => 5;
use Class::MOP;

# This is copied directly from recipe 11
{
    package Restartable;
    use Moose::Role;

    has 'is_paused' => (
        is      => 'rw',
        isa     => 'Bool',
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

# This is the actual tests
{
    my $unreliable = Moose::Meta::Class->create_anon_class(
        superclasses => [],
        roles        => [qw/Restartable::ButUnreliable/],
        methods      => {
            explode      => sub { },    # nop.
            'save_state' => sub { },
            'load_state' => sub { },
        },
    )->new_object();
    ok $unreliable, 'made anon class with Restartable::ButUnreliable role';
    can_ok $unreliable, qw/start stop/;
}

{
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
    ok $broken, 'made anon class with Restartable::ButBroken role';
    $broken->start();
    is $cnt, 1, '... start called explode';
    $broken->stop();
    is $cnt, 2, '... stop also called explode';
}
