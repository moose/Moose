package Moose::Meta::Attribute::Native;

our $VERSION   = '0.93';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

my @trait_names = qw(Bool Counter Number String Array Hash Code);

for my $trait_name (@trait_names) {
    my $trait_class = "Moose::Meta::Attribute::Native::Trait::$trait_name";
    my $meta = Class::MOP::Class->initialize(
        "Moose::Meta::Attribute::Custom::Trait::$trait_name"
    );
    if ($meta->find_method_by_name('register_implementation')) {
        my $class = $meta->name->register_implementation;
        Moose->throw_error(
            "An implementation for $trait_name already exists " .
            "(found '$class' when trying to register '$trait_class')"
        );
    }
    $meta->add_method(register_implementation => sub {
        # resolve_metatrait_alias will load classes anyway, but throws away
        # their error message; we WANT to die if there's a problem
        Class::MOP::load_class($trait_class);
        return $trait_class;
    });
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native - Extend your attribute interfaces

=head1 SYNOPSIS

  package MyClass;
  use Moose;

  has 'mapping' => (
      traits    => [ 'Hash' ],
      is        => 'rw',
      isa       => 'HashRef[Str]',
      default   => sub { {} },
      handles   => {
          exists_in_mapping => 'exists',
          ids_in_mapping    => 'keys',
          get_mapping       => 'get',
          set_mapping       => 'set',
          set_quantity      => [ set => 'quantity' ],
      },
  );


  # ...

  my $obj = MyClass->new;
  $obj->set_quantity(10);      # quantity => 10
  $obj->set_mapping('foo', 4); # foo => 4
  $obj->set_mapping('bar', 5); # bar => 5
  $obj->set_mapping('baz', 6); # baz => 6


  # prints 5
  print $obj->get_mapping('bar') if $obj->exists_in_mapping('bar');

  # prints 'quantity, foo, bar, baz'
  print join ', ', $obj->ids_in_mapping;

=head1 DESCRIPTION

While L<Moose> attributes provide a way to name your accessors, readers,
writers, clearers and predicates, this set of traits provides commonly
used attribute helper methods for more specific types of data.

As seen in the L</SYNOPSIS>, you specify the data structure via the
C<trait> parameter. Available traits are below; see L</METHOD PROVIDERS>.

This module used to exist as the L<MooseX::AttributeHelpers> extension. It was
very commonly used, so we moved it into core Moose. Since this gave us a chance
to change the interface, you will have to change your code or continue using
the L<MooseX::AttributeHelpers> extension. L<MooseX::AttributeHelpers> should
continue to work.

=head1 PARAMETERS

=head2 handles

This is like C<< handles >> in L<Moose/has>, but only HASH references are
allowed.  Keys are method names that you want installed locally, and values are
methods from the method providers (below).  Currying with delegated methods
works normally for C<< handles >>.

=head1 METHOD PROVIDERS

=over

=item L<Number|Moose::Meta::Attribute::Native::Trait::Number>

Common numerical operations.

    has 'integer' => (
        traits    => ['Number'],
        is        => 'ro',
        isa       => 'Int',
        default   => 5,
        handles   => {
            set => 'set',
            add => 'add',
            sub => 'sub',
            mul => 'mul',
            div => 'div',
            mod => 'mod',
            abs => 'abs',
        }
    );

=item L<String|Moose::Meta::Attribute::Native::Trait::String>

Common methods for string operations.

    has 'text' => (
        traits    => ['String'],
        is        => 'rw',
        isa       => 'Str',
        default   => q{},
        handles   => {
            add_text     => 'append',
            replace_text => 'replace',
        }
    );

=item L<Counter|Moose::Meta::Attribute::Native::Trait::Counter>

Methods for incrementing and decrementing a counter attribute.

    has 'counter' => (
        traits    => ['Counter'],
        is        => 'ro',
        isa       => 'Num',
        default   => 0,
        handles   => {
            inc_counter   => 'inc',
            dec_counter   => 'dec',
            reset_counter => 'reset',
        }
    );

=item L<Bool|Moose::Meta::Attribute::Native::Trait::Bool>

Common methods for boolean values.

    has 'is_lit' => (
        traits    => ['Bool'],
        is        => 'rw',
        isa       => 'Bool',
        default   => 0,
        handles   => {
            illuminate  => 'set',
            darken      => 'unset',
            flip_switch => 'toggle',
            is_dark     => 'not',
        }
    );

=item L<Hash|Moose::Meta::Attribute::Native::Trait::Hash>

Common methods for hash references.

    has 'options' => (
        traits    => ['Hash'],
        is        => 'ro',
        isa       => 'HashRef[Str]',
        default   => sub { {} },
        handles   => {
            set_option => 'set',
            get_option => 'get',
            has_option => 'exists',
        }
    );

=item L<Array|Moose::Meta::Attribute::Native::Trait::Array>

Common methods for array references.

    has 'queue' => (
       traits     => ['Array'],
       is         => 'ro',
       isa        => 'ArrayRef[Str]',
       default    => sub { [] },
       handles    => {
           add_item  => 'push',
           next_item => 'shift',
       }
    );

=item L<Code|Moose::Meta::Attribute::Native::Trait::Code>

Common methods for code references.

    has 'callback' => (
       traits     => ['Code'],
       is         => 'ro',
       isa        => 'CodeRef',
       default    => sub { sub { 'called' } },
       handles    => {
           call => 'execute',
       }
    );

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

B<with contributions from:>

Robert (rlb3) Boone

Paul (frodwith) Driver

Shawn (Sartak) Moore

Chris (perigrin) Prather

Robert (phaylon) Sedlacek

Tom (dec) Lanyon

Yuval Kogman

Jason May

Cory (gphat) Watson

Florian (rafl) Ragwitz

Evan Carroll

Jesse (doy) Luehrs

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
