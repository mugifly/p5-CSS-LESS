use Test::More;
use strict;
use warnings;

use CSS::Less;
use File::Slurp;
use FindBin;

my $less = CSS::Less->new( include_paths => [ $FindBin::Bin.'/data/', $FindBin::Bin.'/data_sub/' ], );
unless ( $less->is_lessc_installed() ){
	plan(skip_all => 'Not installed lessc');
}

my $css = $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_test.less")."" );
cmp_ok($css, 'eq', File::Slurp::read_file("$FindBin::Bin/data/90_test.css")."", 'LESS compile test');

done_testing();