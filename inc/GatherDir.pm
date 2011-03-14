package inc::GatherDir;

use Moose;

extends 'Dist::Zilla::Plugin::GatherDir';

around _file_from_filename => sub {
    my $orig = shift;
    my $self = shift;
    my $file = $self->$orig(@_);
    return $file if $file->name =~ m+^t/recipes/basics_recipe10\.t+;
    return ()    if $file->name =~ m+^t/recipes+;
    return $file;
};

1;
