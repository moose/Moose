package StackTrace::Auto;
use Moose::Role 0.87;
# ABSTRACT: a role for generating stack traces during instantiation

=head1 SYNOPSIS

First, include StackTrace::Auto in a Moose class...

  package Some::Class;
  use Moose;
  with 'StackTrace::Auto';

...then create an object of that class...

  my $obj = Some::Class->new;

...and now you have a stack trace for the object's creation.

  print $obj->stack_trace->as_string;

=attr stack_trace

This attribute will contain an object representing the stack at the point when
the error was generated and thrown.  It must be an object performing the
C<as_string> method.

=attr stack_trace_class

This attribute may be provided to use an alternate class for stack traces.  The
default is L<Devel::StackTrace|Devel::StackTrace>.

In general, you will not need to think about this attribute.

=cut

{
  use Moose::Util::TypeConstraints;

  has stack_trace => (
    is       => 'ro',
    isa      => duck_type([ qw(as_string) ]),
    builder  => '_build_stack_trace',
    init_arg => undef,
  );

  my $tc = subtype as 'ClassName';
  coerce $tc, from 'Str', via { Class::MOP::load_class($_); $_ };

  has stack_trace_class => (
    is      => 'ro',
    isa     => $tc,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_stack_trace_class',
  );

  no Moose::Util::TypeConstraints;
}

=attr stack_trace_args

This attribute is an arrayref of arguments to pass when building the stack
trace.  In general, you will not need to think about it.

=cut

has stack_trace_args => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  builder => '_build_stack_trace_args',
);

sub _build_stack_trace_class {
  return 'Devel::StackTrace';
}

sub _build_stack_trace_args {
  my ($self) = @_;
  my $found_mark = 0;
  my $uplevel = 3; # number of *raw* frames to go up after we found the marker
  return [
    frame_filter => sub {
      my ($raw) = @_;
      if ($found_mark) {
          return 1 unless $uplevel;
          return !$uplevel--;
      }
      else {
        $found_mark = scalar $raw->{caller}->[3] =~ /__stack_marker$/;
        return 0;
    }
    },
  ];
}

sub _build_stack_trace {
  my ($self) = @_;
  return $self->stack_trace_class->new(
    @{ $self->stack_trace_args },
  );
}

around new => sub {
  my $next = shift;
  my $self = shift;
  return $self->__stack_marker($next, @_);
};

sub __stack_marker {
  my $self = shift;
  my $next = shift;
  return $self->$next(@_);
}

no Moose::Role;
1;
