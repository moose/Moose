
package Moose::Object;

use strict;
use warnings;

use if ( not our $__mx_is_compiled ), 'Moose::Meta::Class';
use if ( not our $__mx_is_compiled ), metaclass => 'Moose::Meta::Class';

our $VERSION   = '0.72_01';
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
    if ( scalar @_ == 1 ) {
        unless ( defined $_[0] && ref $_[0] eq 'HASH' ) {
            $class->meta->throw_error(
                "Single parameters to new() must be a HASH ref",
                data => $_[0] );
        }
        return { %{ $_[0] } };
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
    # NOTE: we ask Perl if we even 
    # need to do this first, to avoid
    # extra meta level calls    
    return unless $self->can('DEMOLISH');
    foreach my $method ($self->meta->find_all_methods_by_name('DEMOLISH')) {
        $method->{code}->execute($self);
    }
}

sub DESTROY { 
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

This class is the default base class for all Moose-using classes. When
you C<use Moose> in this class, your class will inherit from this
class.

It provides a default constructor and destructor, which run the
C<BUILDALL> and C<DEMOLISHALL> methods respectively.

You don't actually I<need> to inherit from this in order to use Moose,
but it makes it easier to take advantage of all of Moose's features.

=head1 METHODS

=over 4

=item B<< Moose::Object->new(%params) >>

This method calls C<< $class->BUILDARGS(@_) >>, and then creates a new
instance of the appropriate class. Once the instance is created, it
calls C<< $instance->BUILDALL($params) >>.

=item B<< Moose::Object->BUILDARGS(%params) >>

The default implementation of this method accepts a hash or hash
reference of named parameters. If it receives a single argument that
I<isn't> a hash reference it throws an error.

You can override this method in your class to handle other types of
options passed to the constructor.

This method should always return a hash reference of named options.

=item B<< $object->BUILDALL($params) >>

This method will call every C<BUILD> method in the inheritance
hierarchy, starting with the most distant parent class and ending with
the object's class.

The C<BUILD> method will be passed the hash reference returned by
C<BUILDARGS>.

=item B<< $object->DEMOLISHALL >>

This will call every C<DEMOLISH> method in the inheritance hierarchy,
starting with the object's class and ending with the most distant
parent.

=item B<< $object->does($role_name) >>

This returns true if the object does the given role.

=item B<DOES ($class_or_role_name)>

This is a a Moose role-aware implementation of L<UNIVERSAL/DOES>.

This is effectively the same as writing:

  $object->does($name) || $object->isa($name)

This method will work with Perl 5.8, which did not implement
C<UNIVERSAL::DOES>.

=item B<< $object->dump($maxdepth) >>

This is a handy utility for C<Data::Dumper>ing an object. By default,
the maximum depth is 1, to avoid making a mess.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
