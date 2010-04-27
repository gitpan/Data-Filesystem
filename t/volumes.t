#!perl -T

use Data::Filesystem;
use Test::More tests => 8;
use Test::Exception;

# addvol, rmvol, cvol

my $dfs;

$dfs = Data::Filesystem->new(data=>[]);
is($dfs->active_volume, '', "default active volume is ''");

$dfs = Data::Filesystem->new(data=>[], vol => 'foo');
is($dfs->active_volume, 'foo', "create default volume 'foo'");

$dfs = Data::Filesystem->new(data=>{a => {b => {}}}, vol => 'foo');
$dfs->addvol('bar', {a => {b2 => {}}});
is($dfs->active_volume, 'foo', "addvol() doesn't change active_volume");
$dfs->cd('bar:/a/b2');
is($dfs->active_volume, 'foo', "cd() doesn't change active volume");
is($dfs->cwd('foo'), '/', "cd() changes cwd of appropriate volume (1)");
is($dfs->cwd('bar'), '/a/b2', "cd() changes cwd of appropriate volume (2)");

is($dfs->cvol('bar')->active_volume, 'bar', "cvol()");
is($dfs->cwd(), '/a/b2', "cwd() reports active volume's cwd");
