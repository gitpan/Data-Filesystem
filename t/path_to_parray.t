#!perl -T

use Data::Filesystem;
use Test::More tests => 279;

my @path_tests = (
    ['' => undef],

    [' / ' => ['.', ' ', ' ']],
    [' /' => ['.', ' ']],
    [' ' => ['.', ' ']],
    ['/ /' => [' ']],
    ['/ ' => [' ']],
    ['//' => []],
    ['/././' => []],
    ['/./.' => []],
    ['/./' => []],
    ['/../../././../..' => []],
    ['/../../' => []],
    ['/../..' => []],
    ['/../' => []],
    ['/../' => []],
    ['/..' => []],
    ['/.' => []],
    ['/' => []],
    ['./' => ['.']],
    ['../' => ['..']],
    ['..' => ['..']],
    ['.' => ['.']],
    ['//a' => ['a']],
    ['/./a' => ['a']],
    ['/../a' => ['a']],
    ['/a//' => ['a']],
    ['/a/' => ['a']],
    ['/a' => ['a']],
    ['./a/' => ['.', 'a']],
    ['./a' => ['.', 'a']],
    ['../a/' => ['..', 'a']],
    ['../a' => ['..', 'a']],
    ['a/' => ['.', 'a']],
    ['a' => ['.', 'a']],
    ['/a//b/' => ['a', 'b']],
    ['/a//b' => ['a', 'b']],
    ['/a/b/c' => ['a', 'b', 'c']],
    ['a/./b/././c' => ['.', 'a', 'b', 'c']],
    ['a/b/c' => ['.', 'a', 'b', 'c']],
    ['a/../b/c' => ['.', 'a', '..', 'b', 'c']],
    ['/a/./b/../../c' => ['a', 'b', '..', '..', 'c']],
    ['a/./b/../../c' => ['.', 'a', 'b', '..', '..', 'c']],
    ['a/./../../../c/..' => ['.', 'a', '..', '..', '..', 'c', '..']],
    ['a/./../../../c' => ['.', 'a', '..', '..', '..', 'c']],
    ['../b/c' => ['..', 'b', 'c']],
);

my @novol_tests = (
    ['vol:' => [".", "vol:"]],
    ['vol://a' => ['.', 'vol:', 'a']],
    ['vol:/a/' => ['.', 'vol:', 'a']],
    ['vol:a/b/c' => ['.', 'vol:a', 'b', 'c']],
    ['vol:../b/c' => ['.', 'vol:..', 'b', 'c']],
);

my $dfs = Data::Filesystem->new(data => []);

my $dfs_novol = Data::Filesystem->new(data => []);
$dfs_novol->options->parse_volume(0);

my $dfs_sep = Data::Filesystem->new(data => []);
$dfs_sep->options->volume_separator("|");
$dfs_sep->options->path_separator(":");
$dfs_sep->options->curdir_name("CUR");
$dfs_sep->options->parentdir_name("PAR");

my $ch_curpar = sub {$_ eq '.' ? 'CUR' : $_ eq '..' ? 'PAR' : $_};

my $i = 0;
for ([], ["foo"], [""], ["/"]) {
    $i++;
    is_deeply($dfs->path_to_parray($_), $_, "array returned as is ($i)");
}

for (@path_tests) {
    my ($res, $res_v1, $res_v2);
    if (defined($_->[1])) {
        $res    = [undef, @{ $_->[1] }];
        $res_v1 = [''   , @{ $_->[1] }];
        $res_v2 = ['vol', @{ $_->[1] }];
    } else {
        $res = $res_v1 = $res_v2 = undef;
    }

    is_deeply($dfs->path_to_parray($_->[0])      , $res   , "path '$_->[0]'");
    is_deeply($dfs->path_to_parray(":$_->[0]")   , $res_v1, "path '$_->[0]' (vol='')");
    is_deeply($dfs->path_to_parray("vol:$_->[0]"), $res_v2, "path '$_->[0]' (vol='vol')");

    $_->[0] =~ s/\//:/g;
    $_->[0] =~ s/\.\./PAR/g;
    $_->[0] =~ s/\./CUR/g;

    if (defined($_->[1])) {
        $res    = [undef, map { $ch_curpar->() } @{ $_->[1] }];
        $res_v1 = [''   , map { $ch_curpar->() } @{ $_->[1] }];
        $res_v2 = ['vol', map { $ch_curpar->() } @{ $_->[1] }];
    } else {
        $res = $res_v1 = $res_v2 = undef;
    }

    is_deeply($dfs_sep->path_to_parray($_->[0]),       $res   , "path '$_->[0]' (diff sep)");
    is_deeply($dfs_sep->path_to_parray("|$_->[0]"),    $res_v1, "path '$_->[0]' (diff sep, vol='')");
    is_deeply($dfs_sep->path_to_parray("vol|$_->[0]"), $res_v2, "path '$_->[0]' (diff sep, vol='vol')");

}

for (@novol_tests) {
    is_deeply($dfs_novol->path_to_parray($_->[0]), [undef, @{$_->[1]}], "path '$_->[0]' (novol)");
}
