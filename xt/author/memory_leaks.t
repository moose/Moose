use strict;
use warnings;

use Test::More;
use Test::LeakTrace 0.01;
use Test::Memory::Cycle;

BEGIN {
    plan skip_all => 'Leak tests fail under Devel::Cover' if $INC{'Devel/Cover.pm'};
}

use Moose ();
use Moose::Util qw( apply_all_roles );
use Moose::Util::TypeConstraints;

{
    package MyRole;
    use Moose::Role;
    sub myname { "I'm a role" }
}

{
    package Fake::DateTime;
    use Moose;

    has 'string_repr' => ( is => 'ro' );

    package Mortgage;
    use Moose;
    use Moose::Util::TypeConstraints;

    coerce 'Fake::DateTime' => from 'Str' =>
        via { Fake::DateTime->new( string_repr => $_ ) };

    has 'closing_date' => (
        is      => 'rw',
        isa     => 'Fake::DateTime',
        coerce  => 1,
        trigger => sub {
            my ( $self, $val ) = @_;
            ::pass('... trigger is being called');
            ::isa_ok( $self->closing_date, 'Fake::DateTime' );
            ::isa_ok( $val,                'Fake::DateTime' );
        }
    );
}

{
    package Man;
    use Moose;

    my @actions;

    sub live {
        push @actions, 'live';
    }

    sub create {
        push @actions, 'create';
    }

    sub breathe {
        push @actions, 'breathe';
    }

    package Earth;
    use Moose;
    use Moose::Util::TypeConstraints;

    has man => (
        isa     => 'Man',
        handles => [qw( live create breathe )],
    );
}


{
    local $TODO = 'anonymous classes leak on 5.8' if $] < 5.010;
    no_leaks_ok(
        sub {
            Moose::Meta::Class->create_anon_class->new_object;
        },
        'anonymous class with no roles is leak-free'
    );
}

no_leaks_ok(
    sub {
        Moose::Meta::Role->initialize('MyRole2');
    },
    'Moose::Meta::Role->initialize is leak-free'
);

no_leaks_ok(
    sub {
        Moose::Meta::Class->create('MyClass2')->new_object;
    },
    'creating named class is leak-free'
);

{
    local $TODO
        = 'role application leaks because we end up applying the role more than once to the meta object';
    no_leaks_ok(
        sub {
            Moose::Meta::Class->create( 'MyClass', roles => ['MyRole'] );
        },
        'named class with roles is leak-free'
    );

    no_leaks_ok(
        sub {
            Moose::Meta::Role->create( 'MyRole2', roles => ['MyRole'] );
        },
        'named role with roles is leak-free'
    );
}

no_leaks_ok(
    sub {
        my $object = Moose::Meta::Class->create('MyClass2')->new_object;
        apply_all_roles( $object, 'MyRole' );
    },
    'applying role to an instance is leak-free'
);

no_leaks_ok(
    sub {
        Moose::Meta::Role->create_anon_role;
    },
    'anonymous role is leak-free'
);

{
    # fixing this leak currently triggers a bug in Carp
    # we can un-TODO once that fix goes in allowing the leak
    # in Eval::Closure to be fixed
    local $TODO = 'Eval::Closure leaks a bit at the moment';
    no_leaks_ok(
        sub {
            my $meta = Moose::Meta::Class->create_anon_class;
            $meta->make_immutable;
        },
        'making an anon class immutable is leak-free'
    );
}

{
    my $meta3 = Moose::Meta::Class->create('MyClass3');
    memory_cycle_ok( $meta3, 'named metaclass object is cycle-free' );
    memory_cycle_ok( $meta3->new_object, 'MyClass3 object is cycle-free' );

    my $anon_class = Moose::Meta::Class->create_anon_class;
    memory_cycle_ok($anon_class, 'anon metaclass object is cycle-free' );
    memory_cycle_ok( $anon_class->new_object, 'object from anon metaclass is cycle-free' );

    $anon_class->make_immutable;
    memory_cycle_ok($anon_class, 'immutable anon metaclass object is cycle-free' );
    memory_cycle_ok( $anon_class->new_object, 'object from immutable anon metaclass is cycle-free' );

    my $anon_role = Moose::Meta::Role->create_anon_role;
    memory_cycle_ok($anon_role, 'anon role meta object is cycle-free' );
}

{
    my $Str = find_type_constraint('Str');
    my $Undef = find_type_constraint('Undef');
    my $Str_or_Undef = Moose::Meta::TypeConstraint::Union->new(
        type_constraints => [ $Str, $Undef ] );
    memory_cycle_ok($Str_or_Undef, 'union types do not leak');
}

{
    my $mtg = Mortgage->new( closing_date => 'yesterday' );
    $mtg->closing_date;
    Mortgage->meta->make_immutable;

    memory_cycle_ok($mtg->meta, 'meta (triggers/coerce) is cycle-free');
}

{
    local $TODO = 'meta cycles exist at the moment';
    memory_cycle_ok(Earth->new->meta, 'meta (handles) is cycle-free');
    memory_cycle_ok(Earth->meta,      'meta (class) is cycle-free');
}

{
    my $Point = Class::MOP::Class->create('Point' => (
        version    => '0.01',
        attributes => [
            Class::MOP::Attribute->new('x' => (
                reader   => 'x',
                init_arg => 'x'
            )),
            Class::MOP::Attribute->new('y' => (
                accessor => 'y',
                init_arg => 'y'
            )),
        ],
        methods => {
            'new' => sub {
                my $class = shift;
                my $instance = $class->meta->new_object(@_);
                bless $instance => $class;
            },
            'clear' => sub {
                my $self = shift;
                $self->{'x'} = 0;
                $self->{'y'} = 0;
            }
        }
    ));

    my $Point3D = Class::MOP::Class->create('Point3D' => (
        version      => '0.01',
        superclasses => [ 'Point' ],
        attributes => [
            Class::MOP::Attribute->new('z' => (
                default  => 123
            )),
        ],
        methods => {
            'clear' => sub {
                my $self = shift;
                $self->{'z'} = 0;
                $self->SUPER::clear();
            }
        }
    ));

    local $TODO = 'CMOP cycles exist at the moment';
    memory_cycle_ok($Point3D,       'Point3D is cycle-free');
    memory_cycle_ok($Point,         'Point is cycle-free');
    memory_cycle_ok($Point3D->meta, 'Point3D meta is cycle-free');
    memory_cycle_ok($Point->meta,   'Point meta is cycle-free');
}

done_testing;
