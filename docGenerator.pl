#!/usr/bin/env perl

use strict;
use warnings;

use Moose;
use Class::Load 0.07 qw(load_class);

my $dir;
my $path = 'lib/Moose/Exception/';

opendir( $dir, $path) or die $!;

my $number = 0;

print "package Moose::Manual::Exceptions::Manifest;\n";

my $exceptionsToMsgHashRef = getExceptionsToMessages();

while( my $file = readdir($dir) )
{
    my %exceptions = %$exceptionsToMsgHashRef;

    my ($exception, $description, $attributesText, $superclasses, $consumedRoles, $exceptionMessages);
    my (@attributes, @roles, @superClasses, @rolesNames, @superClassNames);
    if( !(-d 'lib/Moose/Exception/'.$file) )
    {
        $file =~ s/\.pm//i;

        $exception = "Moose::Exception::".$file;

	load_class( $exception );
        my $metaClass = Class::MOP::class_of( $exception );

        my @superClasses = $metaClass->superclasses;
        my @roles = $metaClass->calculate_all_roles;
        my @attributes = $metaClass->get_all_attributes;

        my $fileHandle;

        @rolesNames = map {
            my $name = $_->name;
            if( $name =~ /\|/ ) {
                undef;
            } else {
                $name;
            }
        } @roles;

        $superclasses = placeCommasAndAnd( @superClasses );
        $consumedRoles = placeCommasAndAnd( @rolesNames );

        foreach( @attributes )
        {
            my $attribute = $_;
            my $name = $attribute->name;
            my $traits;

            if( $attribute->has_applied_traits ) {
                my @traitsArray = @{$attribute->applied_traits};

                $traits = "has traits of ";
                my $traitsStr = placeCommasAndAnd( @traitsArray );
                $traits .= $traitsStr;
            }

            my ( $tc, $type_constraint ) = ( $attribute->type_constraint->name, "isa " );
            if( $tc =~ /::/ && !(defined $traits) ) {
                $type_constraint .= "L<".$tc.">";
            } else {
                $type_constraint .= $tc;
	    }
            my $readOrWrite = ( $attribute->has_writer ? 'is read-write' : 'is read-only' );
            my $required = ( $attribute->is_required ? 'is required' : 'is optional' );
            my $predicate = ( $attribute->has_predicate ? 'has a predicate C<'.$attribute->predicate.'>': undef );

            my $default;
            if( $attribute->has_default ) {
                if( $tc eq "Str" ) {
                    $default = 'has a default value "'.$attribute->default.'"';
                }
                else {
                    $default = 'has a default value '.$attribute->default;
                }
            }

            my $handlesText;
            if( $attribute->has_handles ) {
                my %handles = %{$attribute->handles};
                my @keys = keys( %handles );
                $handlesText = "This attribute has handles as follows:";
                for( my $i = 0; $i <= $#keys; $i++ ) {
                    next
                        if( $keys[$i] =~ /^_/  );
                    my $strText = sprintf("\n    %-25s=> %s", $keys[$i], $handles{$keys[$i]});
                    $handlesText .= $strText;
                }
            }

            $exceptionMessages = "=back\n\n=head4 Sample Error Message";

            my $msgOrMsgRef = $exceptions{$file};
            if( ref $msgOrMsgRef eq "ARRAY" ) {
                $exceptionMessages .= "s:\n\n";
                my @array = @$msgOrMsgRef;
                foreach( @array ) {
                    $exceptionMessages .= "    $_";
		}
            } else {
                $exceptionMessages .= ":\n\n";
                if( $exceptions{$file} ) {
                    $exceptionMessages .= "    ".$exceptions{$file};
                }
            }

            $exceptionMessages .= "\n";

            $attributesText .= "=item B<< \$exception->$name >>\n\n";
            if( $attribute->has_documentation ) {
                $attributesText .= $attribute->documentation."\n\n";
            } else {
                $attributesText .= "This attribute $readOrWrite, $type_constraint".
                    ( defined $predicate ? ", $predicate" : '' ).
                    ( defined $default ? ", $default" : '').
                    " and $required.".
                    ( defined $handlesText &&  ( $handlesText ne "This attribute has handles as follows:\n" ) ? "\n\n$handlesText" : '' )."\n\n";
            }
        }
        my $roleVerb = "consume".( $#roles == 0 ? 's role' : ' roles' );

        my $text = "=head1 Moose::Exception::$file

This class is a subclass of $superclasses".
( defined $consumedRoles ? " and $roleVerb $consumedRoles.": '.' ).
"\n\n=over 4\n\n=back\n\n=head2 ATTRIBUTES\n\n=over 4\n\n".
( defined $attributesText ? "$attributesText" : '' );

    $text = fixLineLength( $text );
    $text .= $exceptionMessages;
    $number++;
    $text =~ s/\s+$//;
    print "\n$text\n";
    }
}

print "\n=cut\n";

sub fixLineLength {
    my $doc = shift;

    my @tokens = split /\n/, $doc;

    my $str;
    foreach( @tokens ) {
        my $string = shortenToEighty($_);
        $str .= ($string."\n");
    }
    return $str."\n";
}

sub shortenToEighty {
    my ($str) = @_;
    if( length $str > 80 && length $str != 81 ) {
        my $s1 = substr($str, 0, 80);
        my $s2 = substr($str, 80);
        my $substr1 = substr($s1, length($s1) - 1 );
        my $substr2 = substr($s2, 0, 1);
        $s1 =~ s/[\s]+$//g;
        $s2 =~ s/[\s]+$//g;
        if( ( $substr1 =~ /[\(\)\[\w:,'"<>\]\$]/ ) && ( $substr2 =~ /[\$'"\(\)\[<>\w:,\]]/ ) ) {
            if( $s1 =~ s/\s([\(\)\[<:\w+>,"'\]\$]+)$// ) {
		$s1 =~ s/[\s]+$//g;
                $s2 = $1.$s2;
		$s2 =~ s/[\s]+$//g;
                my $s3 = shortenToEighty( $s2 );
		$s3 =~ s/[\s]+$//g;
		$s2 =~ s/[\s]+$//g;
                if( $s2 ne $s3 ) {
                    return "$s1\n$s3";
                } else {
                    return "$s1\n$s2";
                }
            }
        }
        return "$s1\n$s2";
    }
    else
    {
        return $str;
    }
}

sub placeCommasAndAnd {
    my @array = @_;
    my ($str, $lastUndef);

    for( my $i = 0; $i <= $#array; $i++ ) {
        my $element = $array[$i];
        if( !(defined $element ) ) {
            $lastUndef = 1;
            next;
        }
        if ( $i == 0 || ( $lastUndef && $i == 1 ) ) {
            $str .= "L<$element>";
        } elsif( $i == $#array ) {
            $str .= " and L<$element>";
        } else {
            $str .= ", L<$element>";
        }
        $lastUndef = 0;
    }
    return $str;
}

sub getExceptionsToMessages {
    my $testDir;
    my $testPath = 't/exceptions/';

    my %hash;

    opendir( $testDir, $testPath ) or die $!;

    my $file;
    while( $file = readdir( $testDir ) ) {
        my $fileHandle;

        open( $fileHandle, "t/exceptions/$file" ) or die $!;
        my ($message, $exception);
        while( <$fileHandle> ) {
            if( /like\($/ ) {
                my $exceptionVar = <$fileHandle>;
                if( $exceptionVar =~ /\$exception,$/ ) {
                    $message = <$fileHandle>;
                    if( $message =~ q/\$\w+/ || ( $message =~ /\\\(\w+\\\)/) ) {
                        my $garbage = <$fileHandle>;
                        $message = <$fileHandle>;
                        $message =~ s/^\s+#//;
                    }
                    $message =~ s!^\s*qr(/|\!)(\^)?(\\Q)?!!;
                    $message =~ s!(/|\!),$!!;
                }
            } elsif( /isa_ok\($/ ) {
                my $exceptionVar = <$fileHandle>;
                if( $exceptionVar =~ /\$exception(->error)?,$/ ) {
                    $exception = <$fileHandle>;
                    if( $exception =~ /Moose::Exception::(\w+)/ ) {
                        $exception = $1;
                    }
                }
            }

            if( ( defined $exception ) && ( defined $message ) ) {
                if( exists $hash{$exception} &&
                    ( ref $hash{$exception} eq "ARRAY" ) ) {
                    my @array = @{$hash{$exception}};
                    push @array, $message;
                    $hash{$exception} = \@array;
                } elsif( exists $hash{$exception} &&
                         ( $hash{$exception} ne $message ) ) {
                    my $msg = $hash{$exception};
                    my $arrayRef = [ $msg, $message ];
                    $hash{$exception} = $arrayRef;
                } else {
                    $hash{$exception} = $message;
                }
                $exception = undef;
                $message = undef;
            }
        }
        close $fileHandle;
    }

    return \%hash;
}
