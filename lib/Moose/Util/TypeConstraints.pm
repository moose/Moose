
package Moose::Util::TypeConstraints;

use strict;
use warnings;

use Sub::Name    'subname';
use Scalar::Util 'blessed';

our $VERSION = '0.01';

sub import {
	shift;
	my $pkg = shift || caller();
	return if $pkg eq ':no_export';
	no strict 'refs';
	foreach my $export (qw(
		type subtype as where
		)) {
		*{"${pkg}::${export}"} = \&{"${export}"};
	}
	
	foreach my $constraint (qw(
		Any 
		Value Ref
		Str Int
		ScalarRef ArrayRef HashRef CodeRef RegexpRef
		Object
		)) {
		*{"${pkg}::${constraint}"} = \&{"${constraint}"};
	}	
	
}

my %TYPES;

# might need this later
#sub find_type_constraint { $TYPES{$_[0]} }

sub type ($$) {
	my ($name, $check) = @_;
	my $pkg = caller();
	my $full_name = "${pkg}::${name}";
	no strict 'refs';
	*{$full_name} = $TYPES{$name} = subname $full_name => sub { 
		return $TYPES{$name} unless defined $_[0];
		local $_ = $_[0];
		return undef unless $check->($_[0]);
		$_[0];
	};
}

sub subtype ($$;$) {
	my ($name, $parent, $check) = @_;
	if (defined $check) {
		my $pkg = caller();
		my $full_name = "${pkg}::${name}";		
		no strict 'refs';
		$parent = $TYPES{$parent} unless $parent && ref($parent) eq 'CODE';
		*{$full_name} = $TYPES{$name} = subname $full_name => sub { 
			return $TYPES{$name} unless defined $_[0];			
			local $_ = $_[0];
			return undef unless defined $parent->($_[0]) && $check->($_[0]);
			$_[0];
		};	
	}
	else {
		($parent, $check) = ($name, $parent);
		$parent = $TYPES{$parent} unless $parent && ref($parent) eq 'CODE';		
		return subname((caller() . '::__anon_subtype__') => sub { 
			return $TYPES{$name} unless defined $_[0];			
			local $_ = $_[0];
			return undef unless defined $parent->($_[0]) && $check->($_[0]);
			$_[0];
		});		
	}
}

sub as    ($) { $_[0] }
sub where (&) { $_[0] }

# define some basic types

type Any => where { 1 };

type Value => where { !ref($_) };
type Ref   => where {  ref($_) };

subtype Int => as Value => where {  Scalar::Util::looks_like_number($_) };
subtype Str => as Value => where { !Scalar::Util::looks_like_number($_) };

subtype ScalarRef => as Ref => where { ref($_) eq 'SCALAR' };	
subtype ArrayRef  => as Ref => where { ref($_) eq 'ARRAY'  };
subtype HashRef   => as Ref => where { ref($_) eq 'HASH'   };	
subtype CodeRef   => as Ref => where { ref($_) eq 'CODE'   };
subtype RegexpRef => as Ref => where { ref($_) eq 'Regexp' };	

# NOTE: 
# blessed(qr/.../) returns true,.. how odd
subtype Object => as Ref => where { blessed($_) && blessed($_) ne 'Regexp' };

1;

__END__

=pod

=head1 NAME

Moose::Util::TypeConstraints - Type constraint system for Moose

=head1 SYNOPSIS

  use Moose::Util::TypeConstraints;

  type Num => where { Scalar::Util::looks_like_number($_) };
  
  subtype Natural 
      => as Num 
      => where { $_ > 0 };
  
  subtype NaturalLessThanTen 
      => as Natural
      => where { $_ < 10 };

=head1 DESCRIPTION

This module provides Moose with the ability to create type contraints 
to be are used in both attribute definitions and for method argument 
validation. 

This is B<NOT> a type system for Perl 5.

The type and subtype constraints are basically functions which will 
validate their first argument. If called with no arguments, they will 
return themselves (this is syntactic sugar for Moose attributes).

This module also provides a simple hierarchy for Perl 5 types, this 
could probably use some work, but it works for me at the moment.

  Any
      Value
          Int
          Str
      Ref
          ScalarRef
          ArrayRef
          HashRef
          CodeRef
          RegexpRef
          Object	

Suggestions for improvement are welcome.	
    
=head1 FUNCTIONS

=head2 Type Constraint Constructors

=over 4

=item B<type>

=item B<subtype>

=item B<as>

=item B<where>

=back

=head2 Built-in Type Constraints

=over 4

=item B<Any>

=item B<Value>

=item B<Int>

=item B<Str>

=item B<Ref>

=item B<ArrayRef>

=item B<CodeRef>

=item B<HashRef>

=item B<RegexpRef>

=item B<ScalarRef>

=item B<Object>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut