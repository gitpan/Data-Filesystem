#!perl -T

use Data::Filesystem;
use Test::More tests => 5;
use Test::Exception;

my $dfs = Data::Filesystem->new(data=>{a=>{b=>{c=>[0, 10, 20]},
                                           b2=>{c=>[0, -10, -20]}}});

is($dfs->cwd(), '/', "default cwd is '/'");
is($dfs->cd("/a")->cwd(), "/a", 'cd /a');
is($dfs->cd("b/c")->cwd(), "/a/b/c", 'cd b/c');
is($dfs->cd("../../b2/c")->cwd(), "/a/b2/c", 'cd ../../b2/c');
is($dfs->cd(".")->cwd(), "/a/b2/c", 'cd .');
