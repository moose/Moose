package Moose::Exporter;

use strict;
use warnings;

use Class::MOP;
use namespace::clean 0.08 ();
use Sub::Exporter;


my %EXPORT_SPEC;

sub build_import_methods {
    my $class = shift;
    my %args  = @_;

    my $exporting_package = caller();

    $EXPORT_SPEC{$exporting_package} = \%args;

    my ( $exporter, $exported ) = $class->_build_exporter(
        exporting_package => $exporting_package,
        %args
    );

    my $import = $class->_make_import_sub(
        $exporting_package,
        $args{init_meta_args},
        $exporter
    );

    my $unimport = $class->_make_unimport_sub($exported);

    no strict 'refs';
    *{ $exporting_package . '::import' }   = $import;
    *{ $exporting_package . '::unimport' } = $unimport;
}

my %EXPORTED;
sub _build_exporter {
    my $class = shift;
    my %args  = @_;

    my $exporting_package = $args{exporting_package};

    my @exported_names;
    my %exports;
    for my $name ( @{ $args{export} } ) {
        my $sub;
        if ( ref $name ) {
            $sub  = $name;
            $name = ( Class::MOP::get_code_info($name) )[1];
        }
        else {
            $sub = do { no strict 'refs'; \&{ $exporting_package . '::' . $name } };

            push @exported_names, $name;
        }

        $exports{$name} = sub { $sub };

        push @exported_names, $name;
    }

    my $exporter = Sub::Exporter::build_exporter(
        {
            exports => \%exports,
            groups  => { default => [':all'] }
        }
    );

    return $exporter, \@exported_names;
}

sub _make_import_sub {
    my $class             = shift;
    my $exporting_package = shift;
    my $init_meta_args    = shift;
    my $exporter          = shift;

    return sub {
        my $caller = Moose::Exporter->_get_caller(@_);

        # this works because both pragmas set $^H (see perldoc perlvar)
        # which affects the current compilation - i.e. the file who use'd
        # us - which is why we don't need to do anything special to make
        # it affect that file rather than this one (which is already compiled)

        strict->import;
        warnings->import;

        # we should never export to main
        if ( $caller eq 'main' ) {
            warn
                qq{$exporting_package does not export its sugar to the 'main' package.\n};
            return;
        }

        if ( $exporting_package->can('_init_meta') ) {
            $exporting_package->_init_meta(
                %{ $init_meta_args || {} },
                for_class => $caller,
            );
        }

        goto $exporter;
    };
}

sub _get_caller {
    # 1 extra level because it's called by import so there's a layer
    # of indirection
    my $offset = 1;

    return
          ( ref $_[1] && defined $_[1]->{into} ) ? $_[1]->{into}
        : ( ref $_[1] && defined $_[1]->{into_level} )
        ? caller( $offset + $_[1]->{into_level} )
        : caller($offset);
}

sub _make_unimport_sub {
    my $class    = shift;
    my $exported = shift;

    # [12:24]  <mst> yes. that's horrible. I know. but it should work.
    #
    # This will hopefully be replaced in the future once
    # namespace::clean has an API for it.
    return sub {
        @_ = ( 'namespace::clean', @{$exported} );

        goto &namespace::clean::import;
    };
}

1;

__END__

=head1 NAME

Moose::Exporter - make an import() and unimport() just like Moose.pm

=head1 SYNOPSIS

  package MyApp::Moose;

  use strict;
  use warnings;

  use Moose ();
  use Moose::Exporter;

  Moose::Exporter->build_export_methods(
      export         => [ 'sugar1', 'sugar2', \&Some::Random::thing ],
      init_meta_args => { metaclass_class => 'MyApp::Meta::Class' ],
  );

  # then later ...
  package MyApp::User;

  use MyApp::Moose;

  has 'name';
  sugar1 'do your thing';
  thing;

  no MyApp::Moose;

=head1 DESCRIPTION

This module encapsulates the logic to export sugar functions like
C<Moose.pm>. It does this by building custom C<import> and C<unimport>
methods for your module, based on a spec your provide.

It also lets your "stack" Moose-alike modules so you can export
Moose's sugar as well as your own, along with sugar from any random
C<MooseX> module, as long as they all use C<Moose::Exporter>.

=head1 METHODS

This module provides exactly one public method:

=head2 Moose::Exporter->build_import_methods(...)

When you call this method, C<Moose::Exporter> build custom C<import>
and C<unimport> methods for your module. The import method will export
the functions you specify, and you can also tell it to export
functions exported by some other module (like C<Moose.pm>).

The C<unimport> method cleans the callers namespace of all the
exported functions.

This method accepts the following parameters:

=over 4

=item * export => [ ... ]

This a list of function names or sub references to be exported
as-is. You can identify a subroutine by reference, which is handy to
re-export some other module's functions directly by reference
(C<\&Some::Package::function>).

=item * init_meta_args

...

=back

=head1 AUTHOR

Dave Rolsky E<lt>autarch@urth.orgE<gt>

This is largely a reworking of code in Moose.pm originally written by
Stevan Little and others.

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
