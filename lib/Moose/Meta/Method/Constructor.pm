package Moose::Meta::Method::Constructor;
our $VERSION = '2.2006';

use strict;
use warnings;

use Scalar::Util 'weaken';

use parent 'Moose::Meta::Method',
         'Class::MOP::Method::Constructor';

use Moose::Util 'throw_exception';

sub new {
    my $class   = shift;
    my %options = @_;

    my $meta = $options{metaclass};

    (ref $options{options} eq 'HASH')
        || throw_exception( MustPassAHashOfOptions => params => \%options,
                                                      class  => $class
                          );

    ($options{package_name} && $options{name})
        || throw_exception( MustSupplyPackageNameAndName => params => \%options,
                                                            class  => $class
                          );

    my $self = bless {
        'body'          => undef,
        'package_name'  => $options{package_name},
        'name'          => $options{name},
        'options'       => $options{options},
        'associated_metaclass' => $meta,
        'definition_context' => $options{definition_context},
        '_expected_method_class' => $options{_expected_method_class} || 'Moose::Object',
    } => $class;

    # we don't want this creating
    # a cycle in the code, if not
    # needed
    weaken($self->{'associated_metaclass'});

    $self->_initialize_body;

    return $self;
}

## method

sub _initialize_body {
    my $self = shift;
    $self->{'body'} = $self->_generate_constructor_method_inline;
}

1;

# ABSTRACT: Method Meta Object for constructors

__END__

=pod

=head1 SYNOPSIS

  use Moose::Meta::Method::Constructor;

  my $constructor = Moose::Meta::Method::Constructor->new(
      metaclass => $metaclass,
      options   => {
          debug => 1, # this is all for now
      },
  );

  # calling the constructor ...
  $constructor->body->execute($metaclass->name, %params);

=head1 DESCRIPTION

This is a subclass of L<Moose::Meta::Method> which generates constructor
methods.

=head1 INHERITANCE

C<Moose::Meta::Method::Constructor> is a subclass of L<Moose::Meta::Method>
I<and> C<Class::MOP::Method::Constructor>. All of the methods for
C<Moose::Meta::Method::Constructor> and C<Class::MOP::Method::Constructor> are
documented here.

=head1 METHODS

This class provides the following methods.

=head2 Moose::Meta::Method::Constructor->new(%options)

This creates a new constructor object. It accepts a hash reference of
options.

=over 4

=item * metaclass

This should be a L<Moose::Meta::Class> object. It is required.

=item * name

The method name (without a package name). This is required.

=item * package_name

The package name for the method. This is required.

=item * is_inline

This indicates whether or not the constructor should be inlined. This
defaults to false.

=back

=head2 $metamethod->is_inline

Returns a boolean indicating whether or not the constructor is
inlined.

=head2 $metamethod->associated_metaclass

This returns the L<Moose::Meta::Class> object for the method.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=cut
