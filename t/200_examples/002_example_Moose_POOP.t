#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use DBM::Deep 1.0003;";
    plan skip_all => "DBM::Deep 1.0003 (or greater) is required for this test" if $@;              
    eval "use DateTime::Format::MySQL;";
    plan skip_all => "DateTime::Format::MySQL is required for this test" if $@;            
    plan tests => 89;    
}

use Test::Exception;

BEGIN {
    # in case there are leftovers
    unlink('newswriter.db') if -e 'newswriter.db';
}

END {
    unlink('newswriter.db') if -e 'newswriter.db';
}

BEGIN {
    use_ok('Moose');           
}

=pod

This example creates a very basic Object Database which 
links in the instances created with a backend store 
(a DBM::Deep hash). It is by no means to be taken seriously
as a real-world ODB, but is a proof of concept of the flexibility 
of the ::Instance protocol. 

=cut

BEGIN {
    
    package Moose::POOP::Meta::Instance;
    use Moose;
    
    use DBM::Deep;
    
    extends 'Moose::Meta::Instance';
    
    {
        my %INSTANCE_COUNTERS;

        my $db = DBM::Deep->new({
            file      => "newswriter.db",
            autobless => 1,
            locking   => 1,
        });
        
        sub _reload_db {
            #use Data::Dumper;
            #warn Dumper $db;            
            $db = undef;
            $db = DBM::Deep->new({
                file      => "newswriter.db",
                autobless => 1,
                locking   => 1,
            }); 
        }
        
        sub create_instance {
            my $self  = shift;
            my $class = $self->associated_metaclass->name;
            my $oid   = ++$INSTANCE_COUNTERS{$class};
            
            $db->{$class}->[($oid - 1)] = {};
            
            $self->bless_instance_structure({
                oid      => $oid,
                instance => $db->{$class}->[($oid - 1)]
            });
        }
        
        sub find_instance {
            my ($self, $oid) = @_;
            my $instance = $db->{$self->associated_metaclass->name}->[($oid - 1)];  
            $self->bless_instance_structure({
                oid      => $oid,
                instance => $instance
            });                  
        } 
        
        sub clone_instance {
            my ($self, $instance) = @_;
            
            my $class = $self->{meta}->name;
            my $oid   = ++$INSTANCE_COUNTERS{$class};
                        
            my $clone = tied($instance)->clone;
            
            $self->bless_instance_structure({
                oid      => $oid,
                instance => $clone
            });        
        }               
    }
    
    sub get_instance_oid {
        my ($self, $instance) = @_;
        $instance->{oid};
    }

    sub get_slot_value {
        my ($self, $instance, $slot_name) = @_;
        return $instance->{instance}->{$slot_name};
    }

    sub set_slot_value {
        my ($self, $instance, $slot_name, $value) = @_;
        $instance->{instance}->{$slot_name} = $value;
    }

    sub is_slot_initialized {
        my ($self, $instance, $slot_name, $value) = @_;
        exists $instance->{instance}->{$slot_name} ? 1 : 0;
    }

    sub weaken_slot_value {
        confess "Not sure how well DBM::Deep plays with weak refs, Rob says 'Write a test'";
    }  
    
    sub inline_slot_access {
        my ($self, $instance, $slot_name) = @_;
        sprintf "%s->{instance}->{%s}", $instance, $slot_name;
    }
    
    package Moose::POOP::Meta::Class;
    use Moose;  
    
    extends 'Moose::Meta::Class';    
    
    override 'construct_instance' => sub {
        my ($class, %params) = @_;
        return $class->get_meta_instance->find_instance($params{oid}) 
            if $params{oid};
        super();
    };

}
{   
    package Moose::POOP::Object;
    use metaclass 'Moose::POOP::Meta::Class' => (
        instance_metaclass => 'Moose::POOP::Meta::Instance'
    );      
    use Moose;
    
    sub oid {
        my $self = shift;
        $self->meta
             ->get_meta_instance
             ->get_instance_oid($self);
    }

}
{    
    package Newswriter::Author;
    use Moose;
    
    extends 'Moose::POOP::Object';
    
    has 'first_name' => (is => 'rw', isa => 'Str');
    has 'last_name'  => (is => 'rw', isa => 'Str');    
    
    package Newswriter::Article;    
    use Moose;
    use Moose::Util::TypeConstraints;  
      
    use DateTime::Format::MySQL;
    
    extends 'Moose::POOP::Object';    

    subtype 'Headline'
        => as 'Str'
        => where { length($_) < 100 };
    
    subtype 'Summary'
        => as 'Str'
        => where { length($_) < 255 };
        
    subtype 'DateTimeFormatString'
        => as 'Str'
        => where { DateTime::Format::MySQL->parse_datetime($_) };
    
    enum 'Status' => qw(draft posted pending archive);
    
    has 'headline' => (is => 'rw', isa => 'Headline');
    has 'summary'  => (is => 'rw', isa => 'Summary');    
    has 'article'  => (is => 'rw', isa => 'Str');    
    
    has 'start_date' => (is => 'rw', isa => 'DateTimeFormatString');
    has 'end_date'   => (is => 'rw', isa => 'DateTimeFormatString');    
    
    has 'author' => (is => 'rw', isa => 'Newswriter::Author'); 
    
    has 'status' => (is => 'rw', isa => 'Status');
    
    around 'start_date', 'end_date' => sub {
        my $c    = shift;
        my $self = shift;
        $c->($self, DateTime::Format::MySQL->format_datetime($_[0])) if @_;        
        DateTime::Format::MySQL->parse_datetime($c->($self) || return undef);
    };  
}

{ # check the meta stuff first
    isa_ok(Moose::POOP::Object->meta, 'Moose::POOP::Meta::Class');
    isa_ok(Moose::POOP::Object->meta, 'Moose::Meta::Class');    
    isa_ok(Moose::POOP::Object->meta, 'Class::MOP::Class');    
    
    is(Moose::POOP::Object->meta->instance_metaclass, 
      'Moose::POOP::Meta::Instance', 
      '... got the right instance metaclass name');
      
    isa_ok(Moose::POOP::Object->meta->get_meta_instance, 'Moose::POOP::Meta::Instance');  
    
    my $base = Moose::POOP::Object->new;
    isa_ok($base, 'Moose::POOP::Object');    
    isa_ok($base, 'Moose::Object');    
    
    isa_ok($base->meta, 'Moose::POOP::Meta::Class');
    isa_ok($base->meta, 'Moose::Meta::Class');    
    isa_ok($base->meta, 'Class::MOP::Class');    
    
    is($base->meta->instance_metaclass, 
      'Moose::POOP::Meta::Instance', 
      '... got the right instance metaclass name');
      
    isa_ok($base->meta->get_meta_instance, 'Moose::POOP::Meta::Instance');    
}

my $article_oid;
my $article_ref;
{
    my $article;
    lives_ok {
        $article = Newswriter::Article->new(
            headline => 'Home Office Redecorated',
            summary  => 'The home office was recently redecorated to match the new company colors',
            article  => '...',
    
            author => Newswriter::Author->new(
                first_name => 'Truman',
                last_name  => 'Capote'
            ),
    
            status => 'pending'
        );
    } '... created my article successfully';
    isa_ok($article, 'Newswriter::Article');
    isa_ok($article, 'Moose::POOP::Object');   
    
    lives_ok {
        $article->start_date(DateTime->new(year => 2006, month => 6, day => 10));
        $article->end_date(DateTime->new(year => 2006, month => 6, day => 17));
    } '... add the article date-time stuff';
    
    ## check some meta stuff
    
    isa_ok($article->meta, 'Moose::POOP::Meta::Class');
    isa_ok($article->meta, 'Moose::Meta::Class');    
    isa_ok($article->meta, 'Class::MOP::Class');    
    
    is($article->meta->instance_metaclass, 
      'Moose::POOP::Meta::Instance', 
      '... got the right instance metaclass name');
      
    isa_ok($article->meta->get_meta_instance, 'Moose::POOP::Meta::Instance');    
    
    ok($article->oid, '... got a oid for the article');

    $article_oid = $article->oid;
    $article_ref = "$article";

    is($article->headline,
       'Home Office Redecorated',
       '... got the right headline');
    is($article->summary,
       'The home office was recently redecorated to match the new company colors',
       '... got the right summary');
    is($article->article, '...', '... got the right article');   
    
    isa_ok($article->start_date, 'DateTime');
    isa_ok($article->end_date,   'DateTime');

    isa_ok($article->author, 'Newswriter::Author');
    is($article->author->first_name, 'Truman', '... got the right author first name');
    is($article->author->last_name, 'Capote', '... got the right author last name');

    is($article->status, 'pending', '... got the right status');
}

Moose::POOP::Meta::Instance->_reload_db();

my $article2_oid;
my $article2_ref;
{
    my $article2;
    lives_ok {
        $article2 = Newswriter::Article->new(
            headline => 'Company wins Lottery',
            summary  => 'An email was received today that informed the company we have won the lottery',
            article  => 'WoW',
    
            author => Newswriter::Author->new(
                first_name => 'Katie',
                last_name  => 'Couric'
            ),
    
            status => 'posted'
        );
    } '... created my article successfully';
    isa_ok($article2, 'Newswriter::Article');
    isa_ok($article2, 'Moose::POOP::Object');
    
    $article2_oid = $article2->oid;
    $article2_ref = "$article2";
    
    is($article2->headline,
       'Company wins Lottery',
       '... got the right headline');
    is($article2->summary,
       'An email was received today that informed the company we have won the lottery',
       '... got the right summary');
    is($article2->article, 'WoW', '... got the right article');   
    
    ok(!$article2->start_date, '... these two dates are unassigned');
    ok(!$article2->end_date,   '... these two dates are unassigned');

    isa_ok($article2->author, 'Newswriter::Author');
    is($article2->author->first_name, 'Katie', '... got the right author first name');
    is($article2->author->last_name, 'Couric', '... got the right author last name');

    is($article2->status, 'posted', '... got the right status');
    
    ## orig-article
    
    my $article;
    lives_ok {
        $article = Newswriter::Article->new(oid => $article_oid);
    } '... (re)-created my article successfully';
    isa_ok($article, 'Newswriter::Article');
    isa_ok($article, 'Moose::POOP::Object');    
    
    is($article->oid, $article_oid, '... got a oid for the article');
    isnt($article_ref, "$article", '... got a new article instance');    

    is($article->headline,
       'Home Office Redecorated',
       '... got the right headline');
    is($article->summary,
       'The home office was recently redecorated to match the new company colors',
       '... got the right summary');
    is($article->article, '...', '... got the right article');   
    
    isa_ok($article->start_date, 'DateTime');
    isa_ok($article->end_date,   'DateTime');

    isa_ok($article->author, 'Newswriter::Author');
    is($article->author->first_name, 'Truman', '... got the right author first name');
    is($article->author->last_name, 'Capote', '... got the right author last name');
    
    lives_ok {
        $article->author->first_name('Dan');
        $article->author->last_name('Rather');        
    } '... changed the value ok';
    
    is($article->author->first_name, 'Dan', '... got the changed author first name');
    is($article->author->last_name, 'Rather', '... got the changed author last name');    

    is($article->status, 'pending', '... got the right status');
}

Moose::POOP::Meta::Instance->_reload_db();

{
    my $article;
    lives_ok {
        $article = Newswriter::Article->new(oid => $article_oid);
    } '... (re)-created my article successfully';
    isa_ok($article, 'Newswriter::Article');
    isa_ok($article, 'Moose::POOP::Object');    
    
    is($article->oid, $article_oid, '... got a oid for the article');
    isnt($article_ref, "$article", '... got a new article instance');    

    is($article->headline,
       'Home Office Redecorated',
       '... got the right headline');
    is($article->summary,
       'The home office was recently redecorated to match the new company colors',
       '... got the right summary');
    is($article->article, '...', '... got the right article');   
    
    isa_ok($article->start_date, 'DateTime');
    isa_ok($article->end_date,   'DateTime');

    isa_ok($article->author, 'Newswriter::Author');
    is($article->author->first_name, 'Dan', '... got the changed author first name');
    is($article->author->last_name, 'Rather', '... got the changed author last name');    

    is($article->status, 'pending', '... got the right status');
    
    my $article2;
    lives_ok {
        $article2 = Newswriter::Article->new(oid => $article2_oid);
    } '... (re)-created my article successfully';
    isa_ok($article2, 'Newswriter::Article');
    isa_ok($article2, 'Moose::POOP::Object');    
    
    is($article2->oid, $article2_oid, '... got a oid for the article');
    isnt($article2_ref, "$article2", '... got a new article instance');    

    is($article2->headline,
       'Company wins Lottery',
       '... got the right headline');
    is($article2->summary,
       'An email was received today that informed the company we have won the lottery',
       '... got the right summary');
    is($article2->article, 'WoW', '... got the right article');   
    
    ok(!$article2->start_date, '... these two dates are unassigned');
    ok(!$article2->end_date,   '... these two dates are unassigned');

    isa_ok($article2->author, 'Newswriter::Author');
    is($article2->author->first_name, 'Katie', '... got the right author first name');
    is($article2->author->last_name, 'Couric', '... got the right author last name');

    is($article2->status, 'posted', '... got the right status'); 
    
}

