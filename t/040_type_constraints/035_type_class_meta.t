use strict;
use Test::More tests => 1;

{ 
package Type;
use Moose;
}

{ package 
  Signatures;

use Moose;

use Moose::Util::TypeConstraints;

subtype CustomType => as class_type('Type');
subtype CustomType2 => as 'Type';

has file => ( isa => 'CustomType', is => 'rw' );
has file2 => ( isa => 'CustomType2', is => 'rw' );
}


my $sig = new Signatures;
$sig->file(Type->new);

is(ref $sig->meta->get_attribute('file')->type_constraint, 'Moose::Meta::TypeConstraint::Class');
is(ref $sig->meta->get_attribute('file2')->type_constraint, 'Moose::Meta::TypeConstraint::Class');