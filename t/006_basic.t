#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

=pod

This test will eventually be for the code shown below. 
Moose::Role is on the TODO list for 0.04.

    package Constraint;
    use strict;
    use warnings;
    use Moose;

    sub validate      { confess "Abstract method!" }
    sub error_message { confess "Abstract method!" }

    sub validation_value {
        my ($self, $field) = @_;
        return $field->value;
    }

    package Constraint::AtLeast;
    use strict;
    use warnings;
    use Moose;

    extends 'Constraint';

    has 'value' => (isa => 'Num', is => 'ro');

    sub validate {
        my ($self, $field) = @_;
        if ($self->validation_value($field) >= $self->value) {
            return undef;
        } 
        else {
            return $self->error_message;
        }
    }

    sub error_message { 'must be at least ' . (shift)->value; }

    package Constraint::NoMoreThan;
    use strict;
    use warnings;
    use Moose;

    extends 'Constraint';

    has 'value' => (isa => 'Num', is => 'ro');

    sub validate {
        my ($self, $field) = @_;
        if ($self->validation_value($field) <= $self->value) {
            return undef;
        } else {
            return $self->error_message;
        }
    }

    sub error_message { 'must be no more than ' . (shift)->value; }

    package Constraint::OnLength;
    use strict;
    use warnings;
    use Moose::Role;

    has 'units' => (isa => 'Str', is => 'ro');

    override 'value' => sub {
        return length(super());
    };

    override 'error_message' => sub {
        my $self = shift;
        return super() . ' ' . $self->units;
    };

    package Constraint::LengthNoMoreThan;
    use strict;
    use warnings;
    use Moose;

    extends 'Constraint::NoMoreThan';
       with 'Constraint::OnLength';
       
   package Constraint::LengthAtLeast;
   use strict;
   use warnings;
   use Moose;

   extends 'Constraint::AtLeast';
      with 'Constraint::OnLength';       

=cut