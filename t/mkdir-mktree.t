#!perl -T

use Data::Filesystem;
use Test::More tests => 7;
use Test::Exception;

my $dfs;

$dfs = Data::Filesystem->new(data => {});

is_deeply($dfs->mkdir("/a")->get("/a"), {}, "mkdir 1");
throws_ok {$dfs->mkdir("/a/b/c")} qr//, "mkdir can't create intermediate dirs";
$dfs->set("/a/b", 1);
throws_ok {$dfs->mkdir("/a/b")} qr//, "mkdir can't change file into directory";
throws_ok {$dfs->mkdir("/a/b/c")} qr//, "mkdir can't create under file";

$dfs = Data::Filesystem->new(data => {});

is_deeply($dfs->mktree("/a/b/c")->get("/a/b/c"), {}, "mktree 1");
$dfs->set("/a/b", 1);
throws_ok {$dfs->mktree("/a/b")} qr//, "mktree can't change file into directory";
throws_ok {$dfs->mktree("/a/b/c")} qr//, "mktree can't create under file";
