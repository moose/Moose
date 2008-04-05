#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Test::Exception;
use Test::Deep;

use Data::Dumper;

BEGIN
{
	use_ok('Moose');
}

{
	use Moose::Util::TypeConstraints;

	subtype 'FilePath'
		=> as 'Str'
		=> where { $_ =~ m#^(/[a-zA-Z0-9_.-]+)+$#;		};			#	'/' (root) forbidden!
}

{
	package Baz;
	use Moose;
	use Moose::Util::TypeConstraints;

	has 'path' =>
	(
		is			=> 'ro',
		isa		=> 'FilePath',
		required	=> 1,
	);

	sub BUILD
	{
		my ( $self, $params )	= @_;

		confess $params->{path} . " does not exist"		unless -e $params->{path};

		#	open files etc.
	}

	#	Defining this causes the FIRST call to Baz->new w/o param to fail,
	#	if no call to ANY Moose::Object->new was done before.
	#
	sub DEMOLISH
	{
		my ( $self )	= @_;

		#	cleanup files etc.
	}
}

{
	package Qee;
	use Moose;
	use Moose::Util::TypeConstraints;

	has 'path' =>
	(
		is			=> 'ro',
		isa		=> 'FilePath',
		required	=> 1,
	);

	sub BUILD
	{
		my ( $self, $params )	= @_;

		confess $params->{path} . " does not exist"		unless -e $params->{path};

		#	open files etc.
	}

	#	Defining this causes the FIRST call to Qee->new w/o param to fail...
	#	if no call to ANY Moose::Object->new was done before.
	#
	sub DEMOLISH
	{
		my ( $self )	= @_;

		#	cleanup files etc.
	}
}

{
	package Foo;
	use Moose;
	use Moose::Util::TypeConstraints;

	has 'path' =>
	(
		is			=> 'ro',
		isa		=> 'FilePath',
		required	=> 1,
	);

	sub BUILD
	{
		my ( $self, $params )	= @_;

		confess $params->{path} . " does not exist"		unless -e $params->{path};

		#	open files etc.
	}

	#	Having no DEMOLISH, everything works as expected...
	#
}

#	Uncomment only one block per test run:
#

#=pod
check_em ( 'Baz' );	#	'Baz plain' will fail, aka NO error
check_em ( 'Qee' );	#	ok
check_em ( 'Foo' );	#	ok
#=cut

#=pod
check_em ( 'Qee' );	#	'Qee plain' will fail, aka NO error
check_em ( 'Baz' );	#	ok
check_em ( 'Foo' );	#	ok
#=cut

#=pod
check_em ( 'Foo' );	#	ok
check_em ( 'Baz' );	#	ok !
check_em ( 'Qee' );	#	ok
#=cut


sub check_em
{
	my ( $pkg )	= @_;

	my ( %param, $obj );

#	Uncomment to see, that it is really any first call.
#	Subsequents calls will not fail, aka giving the correct error.
    #
    #=pod
    {
        local $@;
    	my $obj	= eval { $pkg->new; };
    	::like	( $@,				qr/is required/,		"... $pkg plain" );
    	::is		( $obj,			undef,					"" );
    }
    {
        local $@;
    	my $obj	= eval { $pkg->new(); };
    	::like	( $@,				qr/is required/,		"... $pkg empty" );
    	::is		( $obj,			undef,					"" );
    }
    {
        local $@;        
    	my $obj	= eval { $pkg->new ( undef ); };
    	::like	( $@,				qr/is required/,		"... $pkg undef" );
    	::is		( $obj,			undef,					"" );
    }
    #=cut
    {
        local $@;        
    	my $obj	= eval { $pkg->new ( %param ); };
    	::like	( $@,				qr/is required/,		"... $pkg undef param" );
    	::is		( $obj,			undef,					"" );
    }
    {
        local $@;        
    	my $obj	= eval { $pkg->new ( path => '/' ); };
    	::like	( $@,				qr/does not pass the type constraint/,	"... $pkg root path forbidden" );
    	::is		( $obj,			undef,					"" );
    }
    {
        local $@;        
    	my $obj	= eval { $pkg->new ( path => '/this_path/does/not_exist' ); };
    	::like	( $@,				qr/does not exist/,	"... $pkg non existing path" );
    	::is		( $obj,			undef,					"" );
    }
    {
        local $@;        
    	my $obj	= eval { $pkg->new ( path => '/tmp' ); };
    	::is		( $@,				'',						"... $pkg no error" );
    	::isa_ok	( $obj,			$pkg );
    	::isa_ok	( $obj,			'Moose::Object' );
    	::is		( $obj->path,	'/tmp',					"... $pkg got the right value" );
    }
}