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

my %EXPORTED;
sub build_exporter {
    my $class = shift;
    my %args  = @_;

    my $exporting_pkg = caller();

    my %exports;
    for my $name ( @{ $args{with_caller} } ) {
        my $sub = do { no strict 'refs'; \&{ $exporting_pkg . '::' . $name } };

        my $wrapped = Class::MOP::subname(
            $exporting_pkg . '::' . $name => sub { $sub->( scalar caller(), @_ ) } );

        $exports{$name} = sub { $wrapped };

        push @{ $EXPORTED{$exporting_pkg} }, $name;
    }

    for my $name ( @{ $args{as_is} } ) {
        my $sub;

        if ( ref $name ) {
            $sub  = $name;
            $name = ( Class::MOP::get_code_info($name) )[1];
        }
        else {
            $sub = do { no strict 'refs'; \&{ $exporting_pkg . '::' . $name } };

            push @{ $EXPORTED{$exporting_pkg} }, $name;
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
