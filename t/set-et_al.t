#!perl -T

use Data::Filesystem;
use Test::More tests => 19;
use Test::Exception;

my $dfs;

$dfs = Data::Filesystem->new(data => {a=>{b=>{c=>[0, 10, 20]}}});

$dfs->set("/a/b/c/3", 30);
is_deeply($dfs->get("/a/b/c/3"), 30, "set: create new");
$dfs->cd("/a/b/c")->set("3", 300);
is_deeply($dfs->get("3"), 300, "set: replace");
$dfs->set("/a", {b=>2});
is_deeply($dfs->get("/a"), {b=>2}, "set: branch");
throws_ok { $dfs->set("/a2/b", 1) } qr/no such file/i, "set: nonexistant path";

$dfs = Data::Filesystem->new(data => {a=>{b=>{c=>[0, 10, 20]}}});

$dfs->set_file("/a/b/c/3", 30);
is_deeply($dfs->get("/a/b/c/3"), 30, "set_file: create new");
$dfs->cd("/a/b/c")->set_file("3", 300);
is_deeply($dfs->get("3"), 300, "set_file: replace");
throws_ok { $dfs->set_file("/a/b/c/3"), [300] } qr//i, "set_file: arg hashref/arrayref";
throws_ok { $dfs->set_file("/a", {}) } qr//i, "set_file: on nonleaf";
throws_ok { $dfs->set_file("/a2/b", 1) } qr//i, "set_file: nonexistant path";

$dfs = Data::Filesystem->new(data => {a=>{b=>{c=>[0, 10, 20]}}});

$dfs->create_file("/a/b/c/3", 30);
is_deeply($dfs->get("/a/b/c/3"), 30, "create_file: create new");
throws_ok { $dfs->cd("/a/b/c")->create_file("3", 300) } qr//i, "create_file: replace";
throws_ok { $dfs->create_file("/a/b/c/3"), [300] } qr//i, "create_file: arg hashref/arrayref";
throws_ok { $dfs->create_file("/a", {}) } qr//i, "create_file: on nonleaf";
throws_ok { $dfs->create_file("/a2/b", 1) } qr//i, "create_file: nonexistant path";

$dfs = Data::Filesystem->new(data => {a=>{b=>{c=>[0, 10, 20]}}});

throws_ok { $dfs->replace_file("/a/b/c/3", 30) } qr//i, "replace_file: create new";
$dfs->cd("/a/b/c")->replace_file("2", 200);
is_deeply($dfs->get("2"), 200, "replace_file: replace");
throws_ok { $dfs->replace_file("/a/b/c/3"), [300] } qr//i, "replace_file: arg hashref/arrayref";
throws_ok { $dfs->replace_file("/a", {}) } qr//i, "replace_file: on nonleaf";
throws_ok { $dfs->replace_file("/a2/b", 1) } qr//i, "replace_file: nonexistant path";

