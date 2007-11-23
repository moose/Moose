#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

## Augment/Inner

{
    package Document::Page;
    use Moose;

    has 'body' => (is => 'rw', isa => 'Str', default => sub {''});

    sub create {
        my $self = shift;
        $self->open_page;
        inner();
        $self->close_page;
    }

    sub append_body { 
        my ($self, $appendage) = @_;
        $self->body($self->body . $appendage);
    }

    sub open_page  { (shift)->append_body('<page>') }
    sub close_page { (shift)->append_body('</page>') }  

    package Document::PageWithHeadersAndFooters;
    use Moose;

    extends 'Document::Page';

    augment 'create' => sub {
        my $self = shift;
        $self->create_header;
        inner();
        $self->create_footer;
    };

    sub create_header { (shift)->append_body('<header/>') }
    sub create_footer { (shift)->append_body('<footer/>') }  

    package TPSReport;
    use Moose;

    extends 'Document::PageWithHeadersAndFooters';

    augment 'create' => sub {
        my $self = shift;
        $self->create_tps_report;
    };

    sub create_tps_report {
       (shift)->append_body('<report type="tps"/>') 
    }    
}

my $tps_report = TPSReport->new;
isa_ok($tps_report, 'TPSReport');

is(
$tps_report->create, 
q{<page><header/><report type="tps"/><footer/></page>},
'... got the right TPS report');




