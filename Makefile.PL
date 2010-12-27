use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;

warn <<'EOF';

  ********************************* WARNING **********************************

  This module uses Dist::Zilla for development. This Build.PL will let you run
  the tests, but you are encouraged to install Dist::Zilla and the needed
  plugins if you intend on doing any serious hacking.

  ****************************************************************************

EOF

my $ccflags = ( $Config::Config{ccflags} || '' ) . ' -I.';
$ccflags .= ' -Wall -Wdeclaration-after-statement';

my %mm = ( CCFLAGS => $ccflags );

{
    my (@OBJECT, %XS);

    for my $xs (<xs/*.xs>) {
        (my $c = $xs) =~ s/\.xs$/.c/i;
        (my $o = $xs) =~ s/\.xs$/\$(OBJ_EXT)/i;

        $XS{$xs} = $c;
        push @OBJECT, $o;
    }

    for my $c (<*.c>) {
        (my $o = $c) =~ s/\.c$/\$(OBJ_EXT)/i;
        push @OBJECT, $o;
    }

    %mm = (
        %mm,
        clean => { FILES => join( q{ }, @OBJECT ) },
        OBJECT => join( q{ }, @OBJECT ),
        XS     => \%XS,
    );
}

WriteMakefile(
    NAME => 'Moose',
    %mm,
);

package MY;

use Config;

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
