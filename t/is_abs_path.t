#!perl -T

use Data::Filesystem;
use Test::More tests => 5;
use Test::Exception;

my @tests = (
    ['' => {dies => 1}],

    ['../a' => {res=>0}],
    ['./a' => {res=>0}],
    ['/a' => {res=>1}],
    ['a' => {res=>0}],
);

my $dfs = Data::Filesystem->new(data=>[]);

for (@tests) {
    if ($_->[1]{dies}) {
        throws_ok { $dfs->is_abs_path($_->[0]) } qr/invalid path/i, "path '$_->[0]' (invalid)";
    } elsif ($_->[1]{res}) {
        ok($dfs->is_abs_path($_->[0]), "path '$_->[0]' (abs)");
    } else {
        ok(!$dfs->is_abs_path($_->[0]), "path '$_->[0]' (not abs)");
    }
}
