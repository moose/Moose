package Moose::Util;

use strict;
use warnings;

use Sub::Exporter;
use Scalar::Util 'blessed';
use Carp         'confess';
use Class::MOP   ();

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

my @exports = qw[
    find_meta 
    does_role
    search_class_by_role   
    apply_all_roles
];

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { all => \@exports }
});

## some utils for the utils ...

sub find_meta { 
    return unless $_[0];
    return Class::MOP::get_metaclass_by_name(blessed($_[0]) || $_[0]);
}

## the functions ...

sub does_role {
    my ($class_or_obj, $role) = @_;

    my $meta = find_meta($class_or_obj);
    
    return unless defined $meta;

    return 1 if $meta->does_role($role);
    return;
}

sub search_class_by_role {
    my ($class_or_obj, $role_name) = @_;
    
    my $meta = find_meta($class_or_obj);

    return unless defined $meta;

    foreach my $class ($meta->class_precedence_list) {
        
        my $_meta = find_meta($class);        

        next unless defined $_meta;

        foreach my $role (@{ $_meta->roles || [] }) {
            return $class if $role->name eq $role_name;
        }
    }

    return;
}

sub apply_all_roles {
    my $applicant = shift;
    
    confess "Must specify at least one role to apply to $applicant" unless @_;
    
    my $roles = Data::OptList::mkopt([ @_ ]);
    
    #use Data::Dumper;
    #warn Dumper $roles;
    
    my $meta = (blessed $applicant ? $applicant : find_meta($applicant));
    
    Class::MOP::load_class($_->[0]) for @$roles;
    
    ($_->[0]->can('meta') && $_->[0]->meta->isa('Moose::Meta::Role'))
        || confess "You can only consume roles, " . $_->[0] . " is not a Moose role"
            foreach @$roles;

    if (scalar @$roles == 1) {
        my ($role, $params) = @{$roles->[0]};
        $role->meta->apply($meta, (defined $params ? %$params : ()));
    }
    else {
        Moose::Meta::Role->combine(
            @$roles
        )->apply($meta);
    }    
}


1;

__END__

=pod

=head1 NAME

Moose::Util - Utilities for working with Moose classes

=head1 SYNOPSIS

  use Moose::Util qw/find_meta does_role search_class_by_role/;

  my $meta = find_meta($object) || die "No metaclass found";

  if (does_role($object, $role)) {
    print "The object can do $role!\n";
  }

  my $class = search_class_by_role($object, 'FooRole');
  print "Nearest class with 'FooRole' is $class\n";

=head1 DESCRIPTION

This is a set of utility functions to help working with Moose classes. This 
is an experimental module, and it's not 100% clear what purpose it will serve. 
That said, ideas, suggestions and contributions to this collection are most 
welcome. See the L<TODO> section below for a list of ideas for possible 
functions to write.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<find_meta ($class_or_obj)>

This will attempt to locate a metaclass for the given C<$class_or_obj>
and return it.

=item B<does_role ($class_or_obj, $role_name)>

Returns true if C<$class_or_obj> can do the role C<$role_name>.

=item B<search_class_by_role ($class_or_obj, $role_name)>

Returns first class in precedence list that consumed C<$role_name>.

=item B<apply_all_roles ($applicant, @roles)>

Given an C<$applicant> (which can somehow be turned into either a 
metaclass or a metarole) and a list of C<@roles> this will do the 
right thing to apply the C<@roles> to the C<$applicant>. This is 
actually used internally by both L<Moose> and L<Moose::Role>, and the
C<@roles> will be pre-processed through L<Data::OptList::mkopt>
to allow for the additional arguments to be passed. 

=back

=head1 TODO

Here is a list of possible functions to write

=over 4

=item discovering original method from modified method

=item search for origin class of a method or attribute

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

B<with contributions from:>

Robert (phaylon) Sedlacek

Stevan Little

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

