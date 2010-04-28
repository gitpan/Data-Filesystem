#!perl -T

use Data::Filesystem;
use Test::More tests => 14;
use Test::Exception;

my $dfs;

$dfs = Data::Filesystem->new(data => {b=>2, c=>[]});

$dfs->set("/0", 1); # write still works

$dfs->options->ro(1);

$dfs->get("/0"); # read still works

throws_ok { $dfs->set("/a", 2) } qr/read.*only/i, "set on ro filesystem fails";
is_deeply($dfs->get_or_undef("/a"), undef, "set didn't change filesystem");

throws_ok { $dfs->set_file("/a", 2) } qr/read.*only/i, "set_file on ro filesystem fails";
is_deeply($dfs->get_or_undef("/a"), undef, "set_file didn't change filesystem");

throws_ok { $dfs->create_file("/a", 2) } qr/read.*only/i, "create_file on ro filesystem fails";
is_deeply($dfs->get_or_undef("/a"), undef, "create_file didn't change filesystem");

throws_ok { $dfs->replace_file("/b", 3) } qr/read.*only/i, "replace_file on ro filesystem fails";
is_deeply($dfs->get_or_undef("/b"), 2, "replace_file didn't change filesystem");

throws_ok { $dfs->unlink("/b") } qr/read.*only/i, "unlink on ro filesystem fails";
is_deeply($dfs->get_or_undef("/b"), 2, "unlink didn't change filesystem");

throws_ok { $dfs->rmdir("/c", 2) } qr/read.*only/i, "rmdir on ro filesystem fails";
is_deeply($dfs->get_or_undef("/c"), [], "rmdir didn't change filesystem");

throws_ok { $dfs->rmtree("/c", 2) } qr/read.*only/i, "rmtree on ro filesystem fails";
is_deeply($dfs->get_or_undef("/c"), [], "rmtree didn't change filesystem");
