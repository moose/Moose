
package Moose::Meta::Method::Destructor;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed', 'weaken';

our $VERSION   = '0.55_01';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Generated';

sub new {
    my $class   = shift;
    my %options = @_;
    
    (exists $options{options} && ref $options{options} eq 'HASH')
        || confess "You must pass a hash of options";    
        
    ($options{package_name} && $options{name})
        || confess "You must supply the package_name and name parameters $Class::MOP::Method::UPGRADE_ERROR_TEXT";        
    
    my $self = bless {
        # from our superclass
        'body'                 => undef, 
        'package_name'         => $options{package_name},
        'name'                 => $options{name},              
        # ...
        'options'              => $options{options},        
        'associated_metaclass' => $options{metaclass},
    } => $class;

    # we don't want this creating 
    # a cycle in the code, if not 
    # needed
    weaken($self->{'associated_metaclass'});    

    $self->initialize_body;

    return $self;    
}

## accessors 

sub options              { (shift)->{'options'}              }
sub associated_metaclass { (shift)->{'associated_metaclass'} }

## method

sub is_needed { 
    my $self = shift;
    # if called as a class method
    # then must pass in a class name
    unless (blessed $self) {
        (blessed $_[0] && $_[0]->isa('Class::MOP::Class')) 
            || confess "When calling is_needed as a class method you must pass a class name";
        return $_[0]->meta->can('DEMOLISH');
    }
    defined $self->{'body'} ? 1 : 0 
}

sub initialize_body {
    my $self = shift;
    # TODO:
    # the %options should also include a both 
    # a call 'initializer' and call 'SUPER::' 
    # options, which should cover approx 90% 
    # of the possible use cases (even if it 
    # requires some adaption on the part of 
    # the author, after all, nothing is free)
    
    my @DEMOLISH_methods = $self->associated_metaclass->find_all_methods_by_name('DEMOLISH');
    
    return unless @DEMOLISH_methods;
    
    my $source = 'sub {';

    my @DEMOLISH_calls;
    foreach my $method (@DEMOLISH_methods) {
        push @DEMOLISH_calls => '$_[0]->' . $method->{class} . '::DEMOLISH()';    
    }
    
    $source .= join ";\n" => @DEMOLISH_calls;

    $source .= ";\n" . '}'; 
    warn $source if $self->options->{debug};    
    
    my $code;
    {
        $code = eval $source;
        confess "Could not eval the destructor :\n\n$source\n\nbecause :\n\n$@" if $@;
    }
    $self->{'body'} = $code;
}


1;

__END__

=pod

=head1 NAME 

Moose::Meta::Method::Destructor - Method Meta Object for destructors

=head1 DESCRIPTION

This is a subclass of L<Class::MOP::Method> which handles 
constructing an approprate Destructor method. This is primarily 
used in the making of immutable metaclasses, otherwise it is 
not particularly useful.

=head1 METHODS

=over 4

=item B<new>

=item B<attributes>

=item B<meta_instance>

=item B<options>

=item B<is_needed>

=item B<initialize_body>

=item B<associated_metaclass>

=back

=head1 AUTHORS

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

