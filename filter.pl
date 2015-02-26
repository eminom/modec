use 5.008;
use warnings;
use strict;

while(<>){
	next if /^\#.*/imxs;
	next if /^(usemtl|mtllib).*/imxs;
	print $_;

}
