#!/usr/bin/perl

=begin comment

04:09 <@konobi> nothingmuch: konobi.co.uk/code/utilsxs.tar.gz
04:09 <@konobi> or utilxs.tar.gz iirc

=cut

package Moose::Util::TypeConstraints::OptimizedConstraints;

use strict;
use warnings;

use Scalar::Util qw(blessed looks_like_number);

sub Value { defined($_[0]) && !ref($_[0]) }

sub Ref { ref($_[0]) }

sub Str { defined($_[0]) && !ref($_[0]) }

sub Num { !ref($_[0]) && looks_like_number($_[0]) }

sub Int { defined($_[0]) && !ref($_[0]) && $_[0] =~ /^-?[0-9]+$/ }

sub ScalarRef { ref($_[0]) eq 'SCALAR' }
sub ArrayRef { ref($_[0]) eq 'ARRAY'  }
sub HashRef { ref($_[0]) eq 'HASH'   }
sub CodeRef { ref($_[0]) eq 'CODE'   }
sub RegexpRef { ref($_[0]) eq 'Regexp' }
sub GlobRef { ref($_[0]) eq 'GLOB'   }

sub FileHandle { ref($_[0]) eq 'GLOB' && Scalar::Util::openhandle($_[0]) }

sub Object { blessed($_[0]) && blessed($_[0]) ne 'Regexp' }

sub Role { blessed($_[0]) && $_[0]->can('does') }


__PACKAGE__

__END__

=pod

=head1 NAME

Moose::Util::TypeConstraints::OptimizedConstraints - Optimized constraint
bodies for various moose types

=head1 SYNOPSIS

=head1 DESCRIPTION

This file contains optimized versions of Moose type constraints.

=head1 FUNCTIONS

=over 4

=item Value

=item Ref

=item Str

=item Num

=item Int

=item ScalarRef

=item ArrayRef

=item HashRef

=item CodeRef

=item RegexpRef

=item GlobRef

=item FileHandle

=item Object

=item Role

=back
