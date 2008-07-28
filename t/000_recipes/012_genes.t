#!/usr/bin/perl

use strict;
use warnings;

{
    package Human;

    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'EyeColor'
        => as 'Object'
        => where { $_->isa('Human::EyeColor') };

    coerce 'EyeColor'
        => from 'ArrayRef'
            => via {
                return Human::EyeColor->new(
                    bey2_1 => $_->[0],
                    bey2_2 => $_->[1],
                    gey_1  => $_->[2],
                    gey_2  => $_->[3],
                );
            };

    subtype 'Gender'
        => as 'Str'
        => where { $_ =~ m{^[mf]$}s };

    has 'gender' => ( is => 'ro', isa => 'Gender', required => 1 );

    has 'eye_color' => ( is => 'ro', isa => 'EyeColor', coerce => 1, required => 1 );

    has 'mother' => ( is => 'ro', isa => 'Human' );
    has 'father' => ( is => 'ro', isa => 'Human' );

    use overload '+' => \&_overload_add, fallback => 1;

    sub _overload_add {
        my ($one, $two) = @_;

        die('Only male and female humans may have children')
            if ($one->gender() eq $two->gender());

        my ( $mother, $father ) = ( $one->gender eq 'f' ? ($one, $two) : ($two, $one) );

        my $gender = 'f';
        $gender = 'm' if (rand() >= 0.5);

        # Would be better to use Crypt::Random.
        #use Crypt::Random qw( makerandom ); 
        #$gender = 'm' if (makerandom( Size => 1, Strength => 1, Uniform => 1 ));

        return Human->new(
            gender => $gender,
            eye_color => ( $one->eye_color() + $two->eye_color() ),
            mother => $mother,
            father => $father,
        );
    }
}

{
    package Human::EyeColor;

    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'bey2Gene'
        => as 'Object'
        => where { $_->isa('Human::Gene::bey2') };

    coerce 'bey2Gene'
        => from 'Str'
            => via { Human::Gene::bey2->new( color => $_ ) };

    subtype 'geyGene'
        => as 'Object'
        => where { $_->isa('Human::Gene::gey') };

    coerce 'geyGene'
        => from 'Str'
            => via { Human::Gene::gey->new( color => $_ ) };

    has 'bey2_1' => ( is => 'ro', isa => 'bey2Gene', coerce => 1 );
    has 'bey2_2' => ( is => 'ro', isa => 'bey2Gene', coerce => 1 );

    has 'gey_1'  => ( is => 'ro', isa => 'geyGene', coerce => 1 );
    has 'gey_2'  => ( is => 'ro', isa => 'geyGene', coerce => 1 );

    use overload '+' => \&_overload_add, fallback => 1;
    use overload '""' => \&color, fallback => 1;

    sub color {
        my ( $self ) = @_;

        return 'brown' if ($self->bey2_1->color() eq 'brown' or $self->bey2_2->color() eq 'brown');
        return 'green' if ($self->gey_1->color() eq 'green' or $self->gey_2->color() eq 'green');
        return 'blue';
    }

    sub _overload_add {
        my ($one, $two) = @_;

        my $one_bey2 = 'bey2_' . _rand2();
        my $two_bey2 = 'bey2_' . _rand2();

        my $one_gey = 'gey_' . _rand2();
        my $two_gey = 'gey_' . _rand2();

        return Human::EyeColor->new(
            bey2_1 => $one->$one_bey2->color(),
            bey2_2 => $two->$two_bey2->color(),
            gey_1  => $one->$one_gey->color(),
            gey_2  => $two->$two_gey->color(),
        );
    }

    sub _rand2 {
        # Would be better to use Crypt::Random.
        #use Crypt::Random qw( makerandom ); 
        #return 1 + makerandom( Size => 1, Strength => 1, Uniform => 1 );
        return 1 + int( rand(2) );
    }
}

{
    package Human::Gene::bey2;

    use Moose;
    use Moose::Util::TypeConstraints;

    type 'bey2Color' => where { $_ =~ m{^(?:brown|blue)$}s };

    has 'color' => ( is => 'ro', isa => 'bey2Color' );
}

{
    package Human::Gene::gey;

    use Moose;
    use Moose::Util::TypeConstraints;

    type 'geyColor' => where { $_ =~ m{^(?:green|blue)$}s };

    has 'color' => ( is => 'ro', isa => 'geyColor' );
}

use Test::More tests => 10;

my $gene_color_sets = [
    [qw( blue blue blue blue ) => 'blue'],
    [qw( blue blue green blue ) => 'green'],
    [qw( blue blue blue green ) => 'green'],
    [qw( blue blue green green ) => 'green'],
    [qw( brown blue blue blue ) => 'brown'],
    [qw( brown brown green green ) => 'brown'],
    [qw( blue brown green blue ) => 'brown'],
];

foreach my $set (@$gene_color_sets) {
    my $expected_color = pop( @$set );
    my $person = Human->new(
        gender => 'f',
        eye_color => $set,
    );
    is(
        $person->eye_color(),
        $expected_color,
        'gene combination '.join(',',@$set).' produces '.$expected_color.' eye color',
    );
}

my $parent_sets = [
    [ [qw( blue blue blue blue )], [qw( blue blue blue blue )] => 'blue' ],
    [ [qw( blue blue blue blue )], [qw( brown brown green blue )] => 'brown' ],
    [ [qw( blue blue green green )], [qw( blue blue green green )] => 'green' ],
];

foreach my $set (@$parent_sets) {
    my $expected_color = pop( @$set );
    my $mother = Human->new(
        gender => 'f',
        eye_color => shift(@$set),
    );
    my $father = Human->new(
        gender => 'm',
        eye_color => shift(@$set),
    );
    my $child = $mother + $father;
    is(
        $child->eye_color(),
        $expected_color,
        'mother '.$mother->eye_color().' + father '.$father->eye_color().' = child '.$expected_color,
    );
}

# Hmm, not sure how to test for random selection of genes since
# I could theoretically run an infinite number of iterations and
# never find proof that a child has inherited a particular gene.

# AUTHOR: Aran Clary Deltac <bluefeet@cpan.org>

