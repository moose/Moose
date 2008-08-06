package Moose::Exporter;

use strict;
use warnings;

use Class::MOP;
use Sub::Exporter;


sub get_caller{
    # 1 extra level because it's called by import so there's a layer of indirection
    my $offset = 1;

    return
        (ref $_[1] && defined $_[1]->{into})
            ? $_[1]->{into}
                : (ref $_[1] && defined $_[1]->{into_level})
                    ? caller($offset + $_[1]->{into_level})
                    : caller($offset);
}

sub build_import_methods {
    my $class = shift;
    my %args  = @_;

    my $exporting_package = caller();

    my $exporter = $class->_build_exporter( exporting_package => $exporting_package, %args );

    my $also = $args{also};

    my $import = sub {
        my $caller = Moose::Exporter->get_caller(@_);

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

        $also->($caller) if $also;

        goto $exporter;
    };

    my $unimport = sub {
        my $caller = Moose::Exporter->get_caller(@_);

        Moose::Exporter->remove_keywords(
            source => $exporting_package,
            from   => $caller,
        );
    };

    no strict 'refs';
    *{ $exporting_package . '::import' } = $import;
    *{ $exporting_package . '::unimport' } = $unimport;
}

my %EXPORTED;
sub _build_exporter {
    my $class = shift;
    my %args  = @_;

    my $exporting_package = $args{exporting_package};

    my %exports;
    for my $name ( @{ $args{with_caller} } ) {
        my $sub = do { no strict 'refs'; \&{ $exporting_package . '::' . $name } };

        my $wrapped = Class::MOP::subname(
            $exporting_package . '::' . $name => sub { $sub->( scalar caller(), @_ ) } );

        $exports{$name} = sub { $wrapped };

        push @{ $EXPORTED{$exporting_package} }, $name;
    }

    for my $name ( @{ $args{as_is} } ) {
        my $sub;

        if ( ref $name ) {
            $sub  = $name;
            $name = ( Class::MOP::get_code_info($name) )[1];
        }
        else {
            $sub = do { no strict 'refs'; \&{ $exporting_package . '::' . $name } };

            push @{ $EXPORTED{$exporting_package} }, $name;
        }

        $exports{$name} = sub { $sub };
    }

    return Sub::Exporter::build_exporter(
        {
            exports => \%exports,
            groups  => { default => [':all'] }
        }
    );
}

sub remove_keywords {
    my $class = shift;
    my %args  = @_;

    no strict 'refs';

    for my $name ( @{ $EXPORTED{ $args{source} } } ) {
        if ( defined &{ $args{from} . '::' . $name } ) {
            my $keyword = \&{ $args{from} . '::' . $name };

            # make sure it is from us
            my ($pkg_name) = Class::MOP::get_code_info($keyword);
            next if $pkg_name ne $args{source};

            # and if it is from us, then undef the slot
            delete ${ $args{from} . '::' }{$name};
        }
    }
}

1;
