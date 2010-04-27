#!perl -T

use Data::Filesystem;
use Test::More tests => 6;
use Test::Exception;

my $dfs = Data::Filesystem->new(data=>{a=>{b=>1}});

ok(!$dfs->is_file('/')   , 'is_file 1');
ok(!$dfs->is_file('/a')  , 'is_file 2');
ok( $dfs->is_file('/a/b'), 'is_file 3');

ok( $dfs->is_dir ('/')   , 'is_dir 1');
ok( $dfs->is_dir ('/a')  , 'is_dir 2');
ok(!$dfs->is_dir ('/a/b'), 'is_dir 3');
