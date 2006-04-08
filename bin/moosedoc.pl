#!/usr/bin/perl

use strict;
use warnings;

use lib './lib';

use Moose;

=pod

=head1 ROADMAP

This is the roadmap for the moosedoc utility. It is just a rough 
sketch of what I am thinking for this.

First question, should it be source-file oriented? or class oriented?

In other words, should I have to do this:

  > moosedoc --target ./my_project/lib/

And have moosedoc traverse the ./my_project/lib/ directory looking for 
.pm files, loading each one and then creating a .pod for it based on the 
moose introspection?

Or should it do this:

  > moosedoc --target ./my_project/script.pl

And have moosedoc then ask Moose what classes/types/subtypes/etc. I 
loaded, and create some kind of .pod for them?

Second question, should I create a large source repository like javadoc? 
or should it just be a file-per-file thing?

If I do it like javadoc, then I would need an index file, a frameset, a 
file for all types/subtypes made, one for all classes, one for all roles, 
etc. At that point, POD may not make sense, and we are into pure HTML 
(for the hyperlinking of course). This then restricts the type of output.

Hmmm,.. gotta do some thinking.

=cut
