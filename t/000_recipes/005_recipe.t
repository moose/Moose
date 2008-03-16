#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use HTTP::Headers; use Params::Coerce; use URI;";
    plan skip_all => "HTTP::Headers & Params::Coerce & URI required for this test" if $@;        
    plan tests => 18;    
}

use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

{
	package Request;
	use Moose;
    use Moose::Util::TypeConstraints;
	
	use HTTP::Headers  ();
	use Params::Coerce ();
	use URI            ();

	subtype Header
	    => as Object
	    => where { $_->isa('HTTP::Headers') };

	coerce Header
	    => from ArrayRef
	        => via { HTTP::Headers->new( @{ $_ } ) }
	    => from HashRef
	        => via { HTTP::Headers->new( %{ $_ } ) };

	subtype Uri
	    => as Object
	    => where { $_->isa('URI') };

	coerce Uri
	    => from Object
	        => via { $_->isa('URI') ? $_ : Params::Coerce::coerce( 'URI', $_ ) }
	    => from Str
	        => via { URI->new( $_, 'http' ) };

	subtype Protocol
	    => as Str
	    => where { /^HTTP\/[0-9]\.[0-9]$/ };


	has 'base'     => (is => 'rw', isa => 'Uri', coerce  => 1);
	has 'url'      => (is => 'rw', isa => 'Uri', coerce  => 1);	
	has 'method'   => (is => 'rw', isa => 'Str');	
	has 'protocol' => (is => 'rw', isa => 'Protocol');		
	has 'headers'  => (
	    is      => 'rw',
	    isa     => 'Header',
	    coerce  => 1,
	    default => sub { HTTP::Headers->new } 
    );
    
    __PACKAGE__->meta->make_immutable(debug => 0);
}

my $r = Request->new;
isa_ok($r, 'Request');

{
    my $header = $r->headers;
    isa_ok($header, 'HTTP::Headers');

    is($r->headers->content_type, '', '... got no content type in the header');

    $r->headers( { content_type => 'text/plain' } );

    my $header2 = $r->headers;
    isa_ok($header2, 'HTTP::Headers');
    isnt($header, $header2, '... created a new HTTP::Header object');

    is($header2->content_type, 'text/plain', '... got the right content type in the header');

    $r->headers( [ content_type => 'text/html' ] );

    my $header3 = $r->headers;
    isa_ok($header3, 'HTTP::Headers');
    isnt($header2, $header3, '... created a new HTTP::Header object');

    is($header3->content_type, 'text/html', '... got the right content type in the header');
    
    $r->headers( HTTP::Headers->new(content_type => 'application/pdf') );
    
    my $header4 = $r->headers;    
    isa_ok($header4, 'HTTP::Headers');
    isnt($header3, $header4, '... created a new HTTP::Header object');

    is($header4->content_type, 'application/pdf', '... got the right content type in the header');    
    
    dies_ok {
        $r->headers('Foo')
    } '... dies when it gets bad params';
}

{
    is($r->protocol, undef, '... got nothing by default');

    lives_ok {
        $r->protocol('HTTP/1.0');
    } '... set the protocol correctly';
    is($r->protocol, 'HTTP/1.0', '... got nothing by default');
            
    dies_ok {
        $r->protocol('http/1.0');
    } '... the protocol died with bar params correctly';            
}

