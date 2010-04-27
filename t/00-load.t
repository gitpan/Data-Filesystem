#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Data::Filesystem' );
    use_ok( 'Data::Filesystem::Options' );
}

diag( "Testing Data::Filesystem $Data::Filesystem::VERSION, Perl $], $^X" );
