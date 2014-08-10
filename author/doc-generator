use blib;
use Moose;
use Class::Load 0.07 qw(load_class);

my $text = generate_docs();
print $text;

sub generate_docs {
    my $dir;
    my $path = 'lib/Moose/Exception/';
    my $pod_file;

    opendir( $dir, $path) or die $!;

    my $version = $ARGV[0];

    my $number = 0;
    my $text = '';

    my $exceptions_to_msg_hashref = get_exceptions_to_messages();

    while( my $file = readdir($dir) )
    {
        my %exceptions = %$exceptions_to_msg_hashref;

        my ($exception, $description, $attributes_text, $superclasses, $consumed_roles, $exception_messages);
        my (@attributes, @roles, @super_classes, @roles_names, @super_class_names);
        if( !(-d 'lib/Moose/Exception/'.$file) )
        {
            $file =~ s/\.pm//i;

            $exception = "Moose::Exception::".$file;

            load_class( $exception );
            my $metaclass = Class::MOP::class_of( $exception )
                or die "No metaclass for $exception";

            my @super_classes = sort { $a->name cmp $b->name } $metaclass->superclasses;
            my @roles = sort { $a->name cmp $b->name } $metaclass->calculate_all_roles;
            my @attributes = sort { $a->name cmp $b->name } $metaclass->get_all_attributes;

            my $file_handle;

            @roles_names = map {
                my $name = $_->name;
                if( $name =~ /\|/ ) {
                    undef;
                } else {
                    $name;
                }
            } @roles;

            $superclasses = place_commas_and_and( @super_classes );
            $consumed_roles = place_commas_and_and( @roles_names );

            foreach my $attribute ( @attributes )
            {
                my $name = $attribute->name;
                my $traits;

                if( $attribute->has_applied_traits ) {
                    my @traits_array = @{$attribute->applied_traits};

                    $traits = "has traits of ";
                    my $traits_str = place_commas_and_and( @traits_array );
                    $traits .= $traits_str;
                }

                my ( $tc, $type_constraint ) = ( $attribute->type_constraint->name, "isa " );
                if( $tc =~ /::/ && !(defined $traits) ) {
                    $type_constraint .= "L<".$tc.">";
                } else {
                    $type_constraint .= $tc;
                }
                my $read_or_write = ( $attribute->has_writer ? 'is read-write' : 'is read-only' );
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

                my $handles_text;
                if( $attribute->has_handles ) {
                    my %handles = %{$attribute->handles};
                    my @keys = sort keys( %handles );
                    my $first_element_inserted = 1;
                    foreach my $key ( @keys ) {
                        next
                            if( $key =~ /^_/  );
                        my $str_text = sprintf("\n    %-25s=> %s", $key, $handles{$key});
                        if( $first_element_inserted == 1 ) {
                            $handles_text = "This attribute has handles as follows:";
                            $first_element_inserted = 0;
                        }
                        $handles_text .= $str_text;
                    }
                }

                $exception_messages = "=back\n\n=head4 Sample Error Message";

                my $msg_or_msg_ref = $exceptions{$file};
                if( ref $msg_or_msg_ref eq "ARRAY" ) {
                    $exception_messages .= "s:\n\n";
                    my @array = @$msg_or_msg_ref;
                    foreach( @array ) {
                        $exception_messages .= "    $_";
                    }
                } else {
                    $exception_messages .= ":\n\n";
                    if( $exceptions{$file} ) {
                        $exception_messages .= "    ".$exceptions{$file};
                    }
                }

                $exception_messages .= "\n";

                $attributes_text .= "=item B<< \$exception->$name >>\n\n";
                if( $attribute->has_documentation ) {
                    $attributes_text .= $attribute->documentation."\n\n";
                } else {
                    $attributes_text .= "This attribute $read_or_write, $type_constraint".
                        ( defined $predicate ? ", $predicate" : '' ).
                        ( defined $default ? ", $default" : '').
                        " and $required.".
                        ( defined $handles_text &&  ( $handles_text ne "This attribute has handles as follows:\n" ) ? "\n\n$handles_text" : '' )."\n\n";
                }
            }
            my $role_verb = "consume".( $#roles == 0 ? 's role' : ' roles' );

            $text .= "=head1 Moose::Exception::$file\n\nThis class is a subclass of $superclasses".
( defined $consumed_roles ? " and $role_verb $consumed_roles.": '.' ).
"\n\n=over 4\n\n=back\n\n=head2 ATTRIBUTES\n\n=over 4\n\n".
( defined $attributes_text ? "$attributes_text\n\n" : '' );

            $text = fix_line_length( $text );
            $text .= $exception_messages;
            $number++;
            $text =~ s/\s+$//;
            $text .= "\n\n";
        }
    }

    return $text;
}

sub fix_line_length {
    my $doc = shift;

    my @tokens = split /\n/, $doc;

    my $str;
    foreach( @tokens ) {
        my $string = shorten_to_eighty($_);
        $str .= ($string."\n");
    }
    return $str."\n";
}

sub shorten_to_eighty {
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
                my $s3 = shorten_to_eighty( $s2 );
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

sub place_commas_and_and {
    my @array = @_;
    my ($str, $last_undef);

    for( my $i = 0; $i <= $#array; $i++ ) {
        my $element = $array[$i];
        if( !(defined $element ) ) {
            $last_undef = 1;
            next;
        }
        if ( $i == 0 || ( $last_undef && $i == 1 ) ) {
            $str .= "L<$element>";
        } elsif( $i == $#array ) {
            $str .= " and L<$element>";
        } else {
            $str .= ", L<$element>";
        }
        $last_undef = 0;
    }
    return $str;
}

sub get_exceptions_to_messages {
    my $test_dir;
    my $test_path = 't/exceptions/';

    my %hash;

    opendir( $test_dir, $test_path ) or die $!;

    my $file;
    while( $file = readdir( $test_dir ) ) {
        my $file_handle;

        open( $file_handle, "t/exceptions/$file" ) or die $!;
        my ($message, $exception);
        while( <$file_handle> ) {
            if( /like\($/ ) {
                my $exception_var = <$file_handle>;
                if( $exception_var =~ /\$exception,$/ ) {
                    $message = <$file_handle>;
                    if( $message =~ q/\$\w+/ || ( $message =~ /\\\(\w+\\\)/) ) {
                        my $garbage = <$file_handle>;
                        $message = <$file_handle>;
                        $message =~ s/^\s+#//;
                    }
                    $message =~ s!^\s*qr(/|\!)(\^)?(\\Q)?!!;
                    $message =~ s!(/|\!),$!!;
                }
            } elsif( /isa_ok\($/ ) {
                my $exception_var = <$file_handle>;
                if( $exception_var =~ /\$exception(->error)?,$/ ) {
                    $exception = <$file_handle>;
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
                    my $array_ref = [ $msg, $message ];
                    $hash{$exception} = $array_ref;
                } else {
                    $hash{$exception} = $message;
                }
                $exception = undef;
                $message = undef;
            }
        }
        close $file_handle;
    }

    return \%hash;
}
