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
        $exporting_package, $args{init_meta_args},
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
    for my $name ( @{ $args{with_caller} } ) {
        my $sub = do { no strict 'refs'; \&{ $exporting_package . '::' . $name } };

        my $wrapped = Class::MOP::subname(
            $exporting_package . '::' . $name => sub { $sub->( scalar caller(), @_ ) } );

        $exports{$name} = sub { $wrapped };

        push @exported_names, $name;
    }

    for my $name ( @{ $args{as_is} } ) {
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
                for_class => $caller,
                %{ $init_meta_args || {} }
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
