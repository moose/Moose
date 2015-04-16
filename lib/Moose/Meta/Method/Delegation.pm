package Moose::Meta::Method::Delegation;
our $VERSION = '2.1405';

use strict;
use warnings;

use Scalar::Util 'blessed', 'weaken';

use parent 'Moose::Meta::Method',
         'Class::MOP::Method::Generated';

use Moose::Util 'throw_exception';

sub new {
    my $class   = shift;
    my %options = @_;

    ( exists $options{attribute} )
        || throw_exception( MustSupplyAnAttributeToConstructWith => params => \%options,
                                                                    class  => $class
                          );

    ( blessed( $options{attribute} )
            && $options{attribute}->isa('Moose::Meta::Attribute') )
        || throw_exception( MustSupplyAMooseMetaAttributeInstance => params => \%options,
                                                                     class  => $class
                          );

    ( $options{package_name} && $options{name} )
        || throw_exception( MustSupplyPackageNameAndName => params => \%options,
                                                            class  => $class
                          );

    ( $options{delegate_to_method} && ( !ref $options{delegate_to_method} )
            || ( 'CODE' eq ref $options{delegate_to_method} ) )
        || throw_exception( MustSupplyADelegateToMethod => params => \%options,
                                                           class  => $class
                          );

    exists $options{curried_arguments}
        || ( $options{curried_arguments} = [] );

    ( $options{curried_arguments} &&
        ( 'ARRAY' eq ref $options{curried_arguments} ) )
        || throw_exception( MustSupplyArrayRefAsCurriedArguments => params     => \%options,
                                                                    class_name => $class
                          );

    my $self = $class->_new( \%options );

    weaken( $self->{'attribute'} );

    $self->_initialize_body;

    return $self;
}

sub _new {
    my $class = shift;
    my $options = @_ == 1 ? $_[0] : {@_};

    return bless $options, $class;
}

sub curried_arguments { (shift)->{'curried_arguments'} }

sub associated_attribute { (shift)->{'attribute'} }

sub delegate_to_method { (shift)->{'delegate_to_method'} }

sub _initialize_body {
    my $self = shift;

    my $method_to_call = $self->delegate_to_method;
    return $self->{body} = $method_to_call
        if ref $method_to_call;

    my $accessor = $self->_get_delegate_accessor;

    my $handle_name = $self->name;

    # NOTE: we used to do a goto here, but the goto didn't handle
    # failure correctly (it just returned nothing), so I took that
    # out. However, the more I thought about it, the less I liked it
    # doing the goto, and I preferred the act of delegation being
    # actually represented in the stack trace.  - SL
    # not inlining this, since it won't really speed things up at
    # all... the only thing that would end up different would be
    # interpolating in $method_to_call, and a bunch of things in the
    # error handling that mostly never gets called - doy
    $self->{body} = sub {
        my $instance = shift;
        my $proxy    = $instance->$accessor();

        if( !defined $proxy ) {
            throw_exception( AttributeValueIsNotDefined => method     => $self,
                                                           instance   => $instance,
                                                           attribute  => $self->associated_attribute,
                           );
        }
        elsif( ref($proxy) && !blessed($proxy) ) {
            throw_exception( AttributeValueIsNotAnObject => method      => $self,
                                                            instance    => $instance,
                                                            attribute   => $self->associated_attribute,
                                                            given_value => $proxy
                           );
        }

        unshift @_, @{ $self->curried_arguments };
        $proxy->$method_to_call(@_);
    };
}

sub _get_delegate_accessor {
    my $self = shift;
    my $attr = $self->associated_attribute;

    # NOTE:
    # always use a named method when
    # possible, if you use the method
    # ref and there are modifiers on
    # the accessors then it will not
    # pick up the modifiers too. Only
    # the named method will assure that
    # we also have any modifiers run.
    # - SL
    my $accessor = $attr->has_read_method
        ? $attr->get_read_method
        : $attr->get_read_method_ref;

    $accessor = $accessor->body if Scalar::Util::blessed $accessor;

    return $accessor;
}

1;

# ABSTRACT: A Moose Method metaclass for delegation methods

__END__

=pod

=head1 DESCRIPTION

This is a subclass of L<Moose::Meta::Method> for delegation
methods.

=head1 METHODS

=over 4

=item B<< Moose::Meta::Method::Delegation->new(%options) >>

This creates the delegation methods based on the provided C<%options>.

=over 4

=item I<attribute>

This must be an instance of C<Moose::Meta::Attribute> which this
accessor is being generated for. This options is B<required>.

=item I<delegate_to_method>

The method in the associated attribute's value to which we
delegate. This can be either a method name or a code reference.

=item I<curried_arguments>

An array reference of arguments that will be prepended to the argument list for
any call to the delegating method.

=back

=item B<< $metamethod->associated_attribute >>

Returns the attribute associated with this method.

=item B<< $metamethod->curried_arguments >>

Return any curried arguments that will be passed to the delegated method.

=item B<< $metamethod->delegate_to_method >>

Returns the method to which this method delegates, as passed to the
constructor.

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
