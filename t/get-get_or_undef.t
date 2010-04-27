#!perl -T

use Data::Filesystem;
use Test::More tests => 12;
use Test::Exception;

my $dfs = Data::Filesystem->new();
$dfs->addvol('foo', {a=>{b =>{c=> 1}}});
$dfs->addvol('bar', {a=>{b2=>{c=>-1}}});

is_deeply($dfs->get("/"), {a=>{b=>{c=>1}}}, "get 1");
is_deeply($dfs->get("/a"), {b=>{c=>1}}, "get 2");
is_deeply($dfs->get("/a/b"), {c=>1}, "get 3");
is_deeply($dfs->get("/a/b/c"), 1, "get 4");
is_deeply($dfs->get("bar:/a/b2/c"), -1, "get 5");
throws_ok { $dfs->get("/a2") } qr/no such file/i, "get nonexistant path";

is_deeply($dfs->get_or_undef("/"), {a=>{b=>{c=>1}}}, "get_or_undef 1");
is_deeply($dfs->get_or_undef("/a"), {b=>{c=>1}}, "get_or_undef 2");
is_deeply($dfs->get_or_undef("/a/b"), {c=>1}, "get_or_undef 3");
is_deeply($dfs->get_or_undef("/a/b/c"), 1, "get_or_undef 4");
is_deeply($dfs->get_or_undef("bar:/a/b2/c"), -1, "get_or_undef 5");
is_deeply($dfs->get_or_undef("/a2"), undef, "get_or_undef nonexistant path");
