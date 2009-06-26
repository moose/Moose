
package Moose::AttributeHelpers::Trait::Counter;
use Moose::Role;

our $VERSION   = '0.83';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose::AttributeHelpers::MethodProvider::Counter;

with 'Moose::AttributeHelpers::Trait::Base';

has 'method_provider' => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'Moose::AttributeHelpers::MethodProvider::Counter',
);

sub helper_type { 'Num' }

before 'process_options_for_handles' => sub {
    my ($self, $options, $name) = @_;

    # Set some default attribute options here unless already defined
    if ((my $type = $self->helper_type) && !exists $options->{isa}){
        $options->{isa} = $type;
    }

    $options->{is}      = 'ro' unless exists $options->{is};
    $options->{default} = 0    unless exists $options->{default};
};

after 'check_handles_values' => sub {
    my $self     = shift;
    my $handles = $self->handles;

    unless (scalar keys %$handles) {
        my $method_constructors = $self->method_constructors;
        my $attr_name           = $self->name;

        foreach my $method (keys %$method_constructors) {
            $handles->{$method . '_' . $attr_name} = $method;
        }

        $self->_set_handles($handles);
    }
};

no Moose::Role;

# register the alias ...
package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::Trait::Counter;
sub register_implementation { 'Moose::AttributeHelpers::Trait::Counter' }

1;

__END__

=pod

=head1 NAME

Moose::AttributeHelpers::Counter

=head1 SYNOPSIS

  package MyHomePage;
  use Moose;
  use Moose::AttributeHelpers;

  has 'counter' => (
      metaclass => 'Counter',
      is        => 'ro',
      isa       => 'Num',
      default   => sub { 0 },
      handles   => {
          inc_counter   => 'inc',
          dec_counter   => 'dec',
          reset_counter => 'reset',
      }
  );

  my $page = MyHomePage->new();
  $page->inc_counter; # same as $page->counter($page->counter + 1);
  $page->dec_counter; # same as $page->counter($page->counter - 1);

=head1 DESCRIPTION

This module provides a simple counter attribute, which can be
incremented and decremented.

If your attribute definition does not include any of I<is>, I<isa>,
I<default> or I<handles> but does use the C<Counter> metaclass,
then this module applies defaults as in the L</SYNOPSIS>
above. This allows for a very basic counter definition:

  has 'foo' => (metaclass => 'Counter');
  $obj->inc_foo;

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider>

=item B<has_method_provider>

=item B<helper_type>

=item B<process_options_for_handles>

Run before its superclass method.

=item B<check_handles_values>

Run after its superclass method.

=back

=head1 PROVIDED METHODS

It is important to note that all those methods do in place
modification of the value stored in the attribute.

=over 4

=item I<set>

Set the counter to the specified value.

=item I<inc>

Increments the value stored in this slot by 1. Providing an argument will
cause the counter to be increased by specified amount.

=item I<dec>

Decrements the value stored in this slot by 1. Providing an argument will
cause the counter to be increased by specified amount.

=item I<reset>

Resets the value stored in this slot to it's default value.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
