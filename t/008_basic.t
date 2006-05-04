#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use DBM::Deep;";
    plan skip_all => "DBM::Deep required for this test" if $@;        
    plan tests => 63;    
}

use Test::Exception;

BEGIN {
    use_ok('Moose');           
}

BEGIN {
    
    package Newswriter::Meta::Instance;
    use strict;
    use warnings;
    use Moose;
    
    use DBM::Deep;
    
    extends 'Moose::Meta::Instance';
    
    {
        my $instance_counter = -1;

        my $db = DBM::Deep->new({
            file      => "newswriter.db",
            autobless => 1,
            locking   => 1,
        });
        $db->{root} = [] unless exists $db->{root};
        
        sub _reload_db {
            $db = undef;
            $db = DBM::Deep->new({
                file      => "newswriter.db",
                autobless => 1,
                locking   => 1,
            }); 
        }
        
        sub create_instance {
            my $self = shift;
            $instance_counter++;
            $db->{root}->[$instance_counter] = {};
            
            $self->bless_instance_structure({
                oid      => $instance_counter,
                instance => $db->{root}->[$instance_counter]
            });
        }
        
        sub find_instance {
            my ($self, $oid) = @_;
            my $instance_struct = $db->{root}->[$oid];
            
            $self->bless_instance_structure({
                oid      => $oid,
                instance => $instance_struct
            });            
        }        
    }
    
    sub get_instance_oid {
        my ($self, $instance) = @_;
        $instance->{oid};
    }

    sub clone_instance {
        confess "&clone_instance is left as an exercise for the user";
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
        confess "Not sure how well DBM::Deep plays with weak refs, Rob says 'Writer a test'";
    }  
    
    sub inline_slot_access {
        my ($self, $instance, $slot_name) = @_;
        sprintf "%s->{instance}->{%s}", $instance, $slot_name;
    }
    
    package Newswriter::Meta::Class;
    use strict;
    use warnings;
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
    package Newswriter::Base;
    use strict;
    use warnings;
    use metaclass 'Newswriter::Meta::Class' => (
        ':instance_metaclass' => 'Newswriter::Meta::Instance'
    );      
    use Moose;
    
    sub oid {
        my $self = shift;
        $self->meta
             ->get_meta_instance
             ->get_instance_oid($self);
    }
    
    package Newswriter::Author;
    use strict;
    use warnings;
    use metaclass 'Newswriter::Meta::Class' => (
        ':instance_metaclass' => 'Newswriter::Meta::Instance'
    );    
    use Moose;
    
    extends 'Newswriter::Base';
    
    has 'first_name' => (is => 'rw', isa => 'Str');
    has 'last_name'  => (is => 'rw', isa => 'Str');    
    
    package Newswriter::Article;    
    use strict;
    use warnings;
    use metaclass 'Newswriter::Meta::Class' => (
        ':instance_metaclass' => 'Newswriter::Meta::Instance'
    );    
    use Moose;
    use Moose::Util::TypeConstraints;  
      
    use DateTime::Format::MySQL;
    
    extends 'Newswriter::Base';    

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
        DateTime::Format::MySQL->parse_datetime($c->($self));
    };  
}

{ # check the meta stuff first
    isa_ok(Newswriter::Base->meta, 'Newswriter::Meta::Class');
    isa_ok(Newswriter::Base->meta, 'Moose::Meta::Class');    
    isa_ok(Newswriter::Base->meta, 'Class::MOP::Class');    
    
    is(Newswriter::Base->meta->instance_metaclass, 
      'Newswriter::Meta::Instance', 
      '... got the right instance metaclass name');
      
    isa_ok(Newswriter::Base->meta->get_meta_instance, 'Newswriter::Meta::Instance');  
    
    my $base = Newswriter::Base->new;
    isa_ok($base, 'Newswriter::Base');    
    isa_ok($base, 'Moose::Object');    
    
    isa_ok($base->meta, 'Newswriter::Meta::Class');
    isa_ok($base->meta, 'Moose::Meta::Class');    
    isa_ok($base->meta, 'Class::MOP::Class');    
    
    is($base->meta->instance_metaclass, 
      'Newswriter::Meta::Instance', 
      '... got the right instance metaclass name');
      
    isa_ok($base->meta->get_meta_instance, 'Newswriter::Meta::Instance');    
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
    isa_ok($article, 'Newswriter::Base');   
    
    lives_ok {
        $article->start_date(DateTime->new(year => 2006, month => 6, day => 10));
        $article->end_date(DateTime->new(year => 2006, month => 6, day => 17));
    } '... add the article date-time stuff';
    
    ## check some meta stuff
    
    isa_ok($article->meta, 'Newswriter::Meta::Class');
    isa_ok($article->meta, 'Moose::Meta::Class');    
    isa_ok($article->meta, 'Class::MOP::Class');    
    
    is($article->meta->instance_metaclass, 
      'Newswriter::Meta::Instance', 
      '... got the right instance metaclass name');
      
    isa_ok($article->meta->get_meta_instance, 'Newswriter::Meta::Instance');    
    
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

Newswriter::Meta::Instance->_reload_db();

{
    my $article;
    lives_ok {
        $article = Newswriter::Article->new(oid => $article_oid);
    } '... (re)-created my article successfully';
    isa_ok($article, 'Newswriter::Article');
    isa_ok($article, 'Newswriter::Base');    
    
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

Newswriter::Meta::Instance->_reload_db();

{
    my $article;
    lives_ok {
        $article = Newswriter::Article->new(oid => $article_oid);
    } '... (re)-created my article successfully';
    isa_ok($article, 'Newswriter::Article');
    isa_ok($article, 'Newswriter::Base');    
    
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
}

unlink('newswriter.db') if -e 'newswriter.db';