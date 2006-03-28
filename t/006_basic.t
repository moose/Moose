#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

=pod

==> AtLeast.pm <==
package BAST::Web::Model::Constraint::AtLeast;

use strict;
use warnings;
use Moose;
use BAST::Web::Model::Constraint;

extends 'BAST::Web::Model::Constraint';

has 'value' => (isa => 'Num', is => 'ro');

sub validate {
  my ($self, $field) = @_;
  if ($self->validation_value($field) >= $self->value) {
    return undef;
  } else {
    return $self->error_message;
  }
}

sub error_message { 'must be at least '.shift->value; }

1;

==> NoMoreThan.pm <==
package BAST::Web::Model::Constraint::NoMoreThan;

use strict;
use warnings;
use Moose;
use BAST::Web::Model::Constraint;

extends 'BAST::Web::Model::Constraint';

has 'value' => (isa => 'Num', is => 'ro');

sub validate {
  my ($self, $field) = @_;
  if ($self->validation_value($field) <= $self->value) {
    return undef;
  } else {
    return $self->error_message;
  }
}

sub error_message { 'must be no more than '.shift->value; }

1;

==> OnLength.pm <==
package BAST::Web::Model::Constraint::OnLength;

use strict;
use warnings;
use Moose;

has 'units' => (isa => 'Str', is => 'ro');

override 'value' => sub {
  return length(super());
};

override 'error_message' => sub {
  my $self = shift;
  return super().' '.$self->units;
};

1;

package BAST::Web::Model::Constraint::LengthNoMoreThan;

use strict;
use warnings;
use Moose;
use BAST::Web::Model::Constraint::NoMoreThan;
use BAST::Web::Model::Constraint::OnLength;

extends 'BAST::Web::Model::Constraint::NoMoreThan';
   with 'BAST::Web::Model::Constraint::OnLength';

=cut