#!perl -T

use Data::Filesystem;
use Test::More tests => 9;
use Test::Exception;

my $dfs = Data::Filesystem->new();
$dfs->addvol('foo', {a=>{b =>{c=> 1}}});
$dfs->addvol('bar', {a=>{b2=>{c=>-1}}});

is_deeply($dfs->ls, ['a'], 'ls 1');
is_deeply($dfs->cd('a')->ls, ['b'], 'ls 2');
is_deeply($dfs->ls('b'), ['c'], 'ls 3');
is_deeply($dfs->ls('b/c'), ['c'], 'ls 4');
throws_ok { $dfs->ls('x') } qr/no such file/i, "ls to nonexistant path";

is_deeply($dfs->readdir('/'), ['a'], 'readdir 1');
is_deeply($dfs->readdir('/a'), ['b'], 'readdir 2');
is_deeply($dfs->readdir('../a/b'), ['c'], 'readdir 3');
throws_ok { $dfs->readdir('../a/b/c') } qr/not a dir/i, "readdir on a nondir";
