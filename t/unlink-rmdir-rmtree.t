#!perl -T

use Data::Filesystem;
use Test::More tests => 12;
use Test::Exception;

my $dfs;

$dfs = Data::Filesystem->new(data => {a=>1, b=>{}, c=>[], d=>{e=>1}});
is_deeply($dfs->unlink("a")->ls, [qw/c b d/], "unlink: file");
throws_ok { $dfs->unlink("b") } qr//, "unlink: empty dir 1";
throws_ok { $dfs->unlink("c") } qr//, "unlink: empty dir 2";
throws_ok { $dfs->unlink("c") } qr//, "unlink: nonempty dir";

$dfs = Data::Filesystem->new(data => {a=>1, b=>{}, c=>[], d=>{e=>1}});
throws_ok { $dfs->rmdir("a") } qr//, "rmdir: file";
is_deeply($dfs->rmdir("b")->ls, [qw/c a d/], "rmdir: empty dir 1");
is_deeply($dfs->rmdir("c")->ls, [qw/a d/], "rmdir: empty dir 2");
throws_ok { $dfs->rmdir("c") } qr//, "rmdir: nonempty dir";

$dfs = Data::Filesystem->new(data => {a=>1, b=>{}, c=>[], d=>{e=>1}});
is_deeply($dfs->rmtree("a")->ls, [qw/c b d/], "rmtree: file");
is_deeply($dfs->rmtree("b")->ls, [qw/c d/], "rmtree: empty dir 1");
is_deeply($dfs->rmtree("c")->ls, [qw/d/], "rmtree: empty dir 2");
is_deeply($dfs->rmtree("d")->ls, [qw//], "rmtree: nonempty dir");
