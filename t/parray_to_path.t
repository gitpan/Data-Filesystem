#!perl -T

use Data::Filesystem;
use Test::More tests => 12;

my @tests = (
    [[undef] => '/'],
    [[undef, "a"] => '/a'],
    [[undef, "."] => '.'],
    [[undef, ".."] => '..'],
    [[undef, "a", "b", "..", "c"] => '/a/b/../c'],
    [[undef, ".", "a", "b", "..", "c"] => './a/b/../c'],

    [["vol"] => 'vol:/'],
    [["vol", "a"] => 'vol:/a'],
    [["vol", "."] => 'vol:.'],
    [["vol", ".."] => 'vol:..'],
    [["vol", "a", "b", "..", "c"] => 'vol:/a/b/../c'],
    [["vol", ".", "a", "b", "..", "c"] => 'vol:./a/b/../c'],
);

my $dfs = Data::Filesystem->new(data=>[]);

for (@tests) {
    is($dfs->parray_to_path($_->[0]), $_->[1], "path '$_->[1]'");
}
