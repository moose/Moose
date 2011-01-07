package MMHelper;

use strict;
use warnings;

use Config;
use Cwd qw( abs_path );
use File::Basename qw( dirname );

sub ccflags_dyn {
    my $is_dev = shift;

    my $ccflags = q<( $Config::Config{ccflags} || '' ) . ' -I.'>;
    $ccflags .= q< . ' -Wall -Wdeclaration-after-statement'>
        if $is_dev;

    return $ccflags;
}

sub ccflags_static {
    my $is_dev = shift;

    return eval(ccflags_dyn($is_dev));
}

sub mm_args {
    my ( @object, %xs );

    for my $xs ( glob "xs/*.xs" ) {
        ( my $c = $xs ) =~ s/\.xs$/.c/i;
        ( my $o = $xs ) =~ s/\.xs$/\$(OBJ_EXT)/i;

        $xs{$xs} = $c;
        push @object, $o;
    }

    for my $c ( glob "*.c" ) {
        ( my $o = $c ) =~ s/\.c$/\$(OBJ_EXT)/i;
        push @object, $o;
    }

    return (
        clean   => { FILES => join( q{ }, @object ) },
        OBJECT => join( q{ }, @object ),
        XS     => \%xs,
    );
}

sub my_package_subs {
    return <<'EOP';
{
package MY;

use Config;

my $message;
BEGIN {
$message = <<'MESSAGE';

  ********************************* ERROR ************************************

  This module uses Dist::Zilla for development. This Makefile.PL will let you
  run the tests, but should not be used for installation or building dists.
  Building a dist should be done with 'dzil build', installation should be
  done with 'dzil install', and releasing should be done with 'dzil release'.

  ****************************************************************************

MESSAGE
$message =~ s/^(.*)$/\t\$(NOECHO) echo "$1";/mg;
}

sub const_cccmd {
    my $ret = shift->SUPER::const_cccmd(@_);
    return q{} unless $ret;

    if ($Config{cc} =~ /^cl\b/i) {
        warn 'you are using MSVC... my condolences.';
        $ret .= ' /Fo$@';
    }
    else {
        $ret .= ' -o $@';
    }

    return $ret;
}

sub postamble {
    return <<'EOF';
$(OBJECT) : mop.h
EOF
}

sub install {
    return <<EOF;
install:
$message
	\$(NOECHO) echo "Running dzil install for you...";
	\$(NOECHO) dzil install
EOF
}

sub dist_core {
    return <<EOF;
dist:
$message
	\$(NOECHO) echo "Running dzil build for you...";
	\$(NOECHO) dzil build
EOF
}
EOP
}

1;
