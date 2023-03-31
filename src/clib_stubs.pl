#!/usr/bin/perl

# extracts map information for the rom to a set of assembler defines to be
# exported in the library module

use strict;

my %symbols=();


sub usage($) {
	my ($msg) = @_;

	print STDERR "$0 <rom map.map> <output.s>\n\n";

	die $msg;
}

sub defsym($$$) {
	my ($sym, $addr, $type) =@_;


	$type =~ s/.*([ZAFL])/\1/;

	my %si = (
		sym => $sym,
		addr => $addr, 
		type => $type
	);

	$symbols{$sym} = \%si;
}

my $infn = shift or usage "no input filename";
open(my $fh_in, "<", $infn) or usage "Cannot open $infn for input";

my $outfn = shift or usage "no output filename";
open(my $fh_out, ">", $outfn) or usage "Cannot open $outfn for output";


my $wait=0;


while(<$fh_in>) {

	chomp;
	s/\r//;

	my $l = $_;

	if (!$wait && $l =~ /^Exports list by value:/)
	{	
		$wait = 1;
	} elsif ($wait == 2 && ($l =~ /^(\w+)\s+([0-9A-F]{6})\s+([A-Z]+)\s+((\w+)\s+([0-9A-F]{6})\s+([A-Z]+))?/)) {
		defsym($1,$2,$3);
		if ($5) {
			defsym($5,$6,$7);
		}
	} elsif ($l =~ /^---/ && $wait) {
		$wait++;
		if ($wait > 2)
		{
			last;
		}
	}

}

for my $s (sort keys %symbols) {

	my $syminfo = ${symbols{$s}};
	if ($syminfo->{sym} =~ /^__/)
	{
		print $fh_out "\t\t; skipping symbol $syminfo->{sym}\n";
	} elsif ($syminfo->{type} eq "Z") {
		print $fh_out "\t\t.exportZP\t$s\n";
		print $fh_out "\t\t$s\t\t:=\t\$$syminfo->{addr}\n";
	} elsif ($syminfo->{type} eq "A") {
		print $fh_out "\t\t.export\t$s\n";
		print $fh_out "$s\t\t:=\t\$$syminfo->{addr}\n";
	} else {
		die "Unsupported symbol type \"$syminfo->{type}\" for symbol \"$s\"";	
	}
}


close ($fh_in);
close ($fh_out);