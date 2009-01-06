
package Moose::Object;

use strict;
use warnings;

use if ( not our $__mx_is_compiled ), 'Moose::Meta::Class';
use if ( not our $__mx_is_compiled ), metaclass => 'Moose::Meta::Class';

our $VERSION   = '0.64';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

sub new {
    my $class = shift;
    my $params = $class->BUILDARGS(@_);
    my $self = $class->meta->new_object($params);
    $self->BUILDALL($params);
    return $self;
}

sub BUILDARGS {
    my $class = shift;
    if (scalar @_ == 1) {
        if (defined $_[0]) {
            (ref($_[0]) eq 'HASH')
                || $class->meta->throw_error("Single parameters to new() must be a HASH ref", data => $_[0]);
            return {%{$_[0]}};
        } 
        else {
            return {}; # FIXME this is compat behavior, but is it correct?
        }
    } 
    else {
        return {@_};
    }
}

sub BUILDALL {
    # NOTE: we ask Perl if we even 
    # need to do this first, to avoid
    # extra meta level calls
    return unless $_[0]->can('BUILD');    
    my ($self, $params) = @_;
    foreach my $method (reverse $self->meta->find_all_methods_by_name('BUILD')) {
        $method->{code}->execute($self, $params);
    }
}

sub DEMOLISHALL {
    my $self = shift;    
    foreach my $method ($self->meta->find_all_methods_by_name('DEMOLISH')) {
        $method->{code}->execute($self);
    }
}

sub DESTROY { 
    # NOTE: we ask Perl if we even 
    # need to do this first, to avoid
    # extra meta level calls    
    return unless $_[0]->can('DEMOLISH');
    # if we have an exception here ...
    if ($@) {
        # localize the $@ ...
        local $@;
        # run DEMOLISHALL ourselves, ...
        $_[0]->DEMOLISHALL;
        # and return ...
        return;
    }
    # otherwise it is normal destruction
    $_[0]->DEMOLISHALL;
}

# support for UNIVERSAL::DOES ...
BEGIN {
    my $does = UNIVERSAL->can("DOES") ? "SUPER::DOES" : "isa";
    eval 'sub DOES {
        my ( $self, $class_or_role_name ) = @_;
        return $self->'.$does.'($class_or_role_name)
            || $self->does($class_or_role_name);
    }';
}

# new does() methods will be created 
# as appropiate see Moose::Meta::Role
sub does {
    my ($self, $role_name) = @_;
    my $meta = $self->meta;
    (defined $role_name)
        || $meta->throw_error("You much supply a role name to does()");
    foreach my $class ($meta->class_precedence_list) {
        my $m = $meta->initialize($class);
        return 1 
            if $m->can('does_role') && $m->does_role($role_name);            
    }
    return 0;   
}

# RANT:
# Cmon, how many times have you written 
# the following code while debugging:
# 
#  use Data::Dumper; 
#  warn Dumper \%thing;
#
# It can get seriously annoying, so why 
# not just do this ...
sub dump { 
    my $self = shift;
    require Data::Dumper;
    local $Data::Dumper::Maxdepth = shift if @_;
    Data::Dumper::Dumper $self;
}

1;

__END__

=pod

=head1 NAME

Moose::Object - The base object for Moose

=head1 DESCRIPTION

This serves as the base object for all Moose classes. Every 
effort will be made to ensure that all classes which C<use Moose> 
will inherit from this class. It provides a default constructor 
and destructor, which run all the BUILD and DEMOLISH methods in 
the class tree.

You don't actually I<need> to inherit from this in order to 
use Moose though. It is just here to make life easier.

=head1 METHODS

=over 4

=item B<meta>

This will return the metaclass associated with the given class.

=item B<new>

This will call C<BUILDARGS>, create a new instance and call C<BUILDALL>.

=item B<BUILDARGS>

This method processes an argument list into a hash reference. It is used by
C<new>.

=item B<BUILDALL>

This will call every C<BUILD> method in the inheritance hierarchy, 
and pass it a hash-ref of the the C<%params> passed to C<new>.

=item B<DEMOLISHALL>

This will call every C<DEMOLISH> method in the inheritance hierarchy.

=item B<does ($role_name)>

This will check if the invocant's class C<does> a given C<$role_name>. 
This is similar to C<isa> for object, but it checks the roles instead.

=item B<DOES ($class_or_role_name)>

A Moose Role aware implementation of L<UNIVERSAL/DOES>.

C<DOES> is equivalent to C<isa> or C<does>.

=item B<dump ($maxdepth)>

Cmon, how many times have you written the following code while debugging:

 use Data::Dumper; 
 warn Dumper $obj;

It can get seriously annoying, so why not just use this.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
