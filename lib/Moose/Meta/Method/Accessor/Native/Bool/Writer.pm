package Moose::Meta::Method::Accessor::Native::Bool::Writer;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Writer';

sub _new_value       {q{}}
sub _potential_value {q{}}

sub _value_needs_copy {0}

# The Bool type does not have any methods that take a user-provided value
sub _inline_tc_code {q{}}

1;
