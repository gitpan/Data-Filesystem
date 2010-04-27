#!perl -T

use Data::Filesystem;
use Test::More tests => 1;
use Test::Exception;

my $dfs;

$dfs = Data::Filesystem->new(data => {});

$dfs->set("/a", 1);
$dfs->options->ro(1);
throws_ok { $dfs->set("/a", 2) } qr/read.*only/i, "set on ro filesystem fails";
