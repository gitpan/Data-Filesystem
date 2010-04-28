#!perl -T

use Data::Filesystem;
use Test::More tests => 8;
use Test::Exception;

my $dfs = Data::Filesystem->new();

is_deeply($dfs->path_to_parray("/a/b/c"),     [undef, qw/a b c/],   "parse_volume on 1");
is_deeply($dfs->path_to_parray("a/b/c"),      [undef, qw/. a b c/], "parse_volume on 2");
is_deeply($dfs->path_to_parray("vol:/a/b/c"), [qw/vol a b c/],      "parse_volume on 3");
is_deeply($dfs->path_to_parray("vol:a/b/c"),  [qw/vol . a b c/],    "parse_volume on 4");

$dfs->options->parse_volume(0);

is_deeply($dfs->path_to_parray("/a/b/c"),     [undef, qw/a b c/],        "parse_volume off 1");
is_deeply($dfs->path_to_parray("a/b/c"),      [undef, qw/. a b c/],      "parse_volume off 2");
is_deeply($dfs->path_to_parray("vol:/a/b/c"), [undef, qw/. vol: a b c/], "parse_volume off 3");
is_deeply($dfs->path_to_parray("vol:a/b/c"),  [undef, qw/. vol:a b c/],  "parse_volume off 4");


