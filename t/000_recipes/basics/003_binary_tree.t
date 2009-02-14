#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 41;
use Test::Exception;

use Scalar::Util 'isweak';

{
    package BinaryTree;
    use Moose;

    has 'node' => ( is => 'rw', isa => 'Any' );

    has 'parent' => (
        is        => 'rw',
        isa       => 'BinaryTree',
        predicate => 'has_parent',
        weak_ref  => 1,
    );

    has 'left' => (
        is        => 'rw',
        isa       => 'BinaryTree',
        predicate => 'has_left',
        lazy      => 1,
        default   => sub { BinaryTree->new( parent => $_[0] ) },
        trigger   => \&_set_parent_for_child
    );

    has 'right' => (
        is        => 'rw',
        isa       => 'BinaryTree',
        predicate => 'has_right',
        lazy      => 1,
        default   => sub { BinaryTree->new( parent => $_[0] ) },
        trigger   => \&_set_parent_for_child
    );

    sub _set_parent_for_child {
        my ( $self, $child ) = @_;

        confess "You cannot insert a tree which already has a parent"
            if $child->has_parent;

        $child->parent($self);
    }
}

my $root = BinaryTree->new(node => 'root');
isa_ok($root, 'BinaryTree');

is($root->node, 'root', '... got the right node value');

ok(!$root->has_left, '... no left node yet');
ok(!$root->has_right, '... no right node yet');

ok(!$root->has_parent, '... no parent for root node');

# make a left node

my $left = $root->left;
isa_ok($left, 'BinaryTree');

is($root->left, $left, '... got the same node (and it is $left)');
ok($root->has_left, '... we have a left node now');

ok($left->has_parent, '... lefts has a parent');
is($left->parent, $root, '... lefts parent is the root');

ok(isweak($left->{parent}), '... parent is a weakened ref');

ok(!$left->has_left, '... $left no left node yet');
ok(!$left->has_right, '... $left no right node yet');

is($left->node, undef, '... left has got no node value');

lives_ok {
    $left->node('left')
} '... assign to lefts node';

is($left->node, 'left', '... left now has a node value');

# make a right node

ok(!$root->has_right, '... still no right node yet');

is($root->right->node, undef, '... right has got no node value');

ok($root->has_right, '... now we have a right node');

my $right = $root->right;
isa_ok($right, 'BinaryTree');

lives_ok {
    $right->node('right')
} '... assign to rights node';

is($right->node, 'right', '... left now has a node value');

is($root->right, $right, '... got the same node (and it is $right)');
ok($root->has_right, '... we have a right node now');

ok($right->has_parent, '... rights has a parent');
is($right->parent, $root, '... rights parent is the root');

ok(isweak($right->{parent}), '... parent is a weakened ref');

# make a left node of the left node

my $left_left = $left->left;
isa_ok($left_left, 'BinaryTree');

ok($left_left->has_parent, '... left does have a parent');

is($left_left->parent, $left, '... got a parent node (and it is $left)');
ok($left->has_left, '... we have a left node now');
is($left->left, $left_left, '... got a left node (and it is $left_left)');

ok(isweak($left_left->{parent}), '... parent is a weakened ref');

# make a right node of the left node

my $left_right = BinaryTree->new;
isa_ok($left_right, 'BinaryTree');

lives_ok {
    $left->right($left_right)
} '... assign to rights node';

ok($left_right->has_parent, '... left does have a parent');

is($left_right->parent, $left, '... got a parent node (and it is $left)');
ok($left->has_right, '... we have a left node now');
is($left->right, $left_right, '... got a left node (and it is $left_left)');

ok(isweak($left_right->{parent}), '... parent is a weakened ref');

# and check the error

dies_ok {
    $left_right->right($left_left)
} '... cant assign a node which already has a parent';

