use Test::More;
use strict;
use warnings;

use CSS::Less;
use File::Slurp;
use FindBin;

my $less = CSS::Less->new(
	include_paths => [ $FindBin::Bin.'/foo/', '/bar/' ],
	dry_run => 1,
);

# Execute compile as dry-run
my $cmd = $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_test.less")."" );
my $exp_include_paths = "${FindBin::Bin}/foo/:/bar/";
like($cmd, qr/lessc \/tmp\/\w+ --include-path=$exp_include_paths/, '(Dry-run) Generate command for lessc');
# 2>&1 \|
done_testing();