#!/usr/bin/perl
use warnings;
use strict;
use DBI;
use Data::Dumper;
use 5.10.0;


my $driver = "Pg";
my $hostname = "borreliabase.org";
my $user = "";
my $database = "";
my $password = "------";
my $dbh = DBI->connect(
"DBI:$driver:dbname=$database; host=$hostname;",
    $user, $password,
    {
        RaiseError => 1,
	PrintError => 1,
        AutoCommit => 0,
    }
    ) or die $DBI::errstr;

my $sql = $dbh->prepare("select genome_id from genome2");
my $gcdhits = $dbh->prepare("select locus, start, stop, strand, cdhit_id from orf2 where genome_id = ? and cdhit_id is not NULL and cdhit_id > 0 order by start");
 
my @gids;
$sql->execute();
while (my ($gid) = $sql->fetchrow_array()) {
    push @gids, $gid;
}
#print Dumper(\@gids);
my %columns;
my %pairs_in_genomes;
my %seen_pairs;
foreach my $gid (@gids) {
    &get_pairs($gid);
}
#print Dumper(\%pairs_in_genomes);
#print Dumper(\$gid);

print "Genome_id\t";
print join "\t", sort keys %seen_pairs;
print "\n";
foreach my $gid (@gids) {
    print $gid;
    foreach my $pair ( sort keys %seen_pairs) {
	print "\t", $pairs_in_genomes{$gid}->{$pair} ? 1 : 0;
    }
    print "\n";
}
my @colnum;
my %seen_str;
foreach my $col (sort keys %columns) {
    my $str ="";
    for my $gid (@gids) {
	my $status = $columns{$col}->{$gid} ? 1 : 0;
	$str .=  $status;
    }
    $seen_str{$str}++;
}

#say join Dumper(\%seen_str), sort keys %seen_pairs;
say Dumper(\%seen_str);
$gcdhits->finish();
$sql->finish();
$dbh->disconnect;
exit;

#############################

sub get_pairs {
    my $gid = shift;
    my @genes;
    $gcdhits->execute($gid);
    while (my ($locus, $start, $stop, $strand, $cdhit_id) = $gcdhits->fetchrow_array()) {
	push @genes, { locus => $locus,  start => $start, stop => $stop, strand => $strand, cdhit => $cdhit_id};
    }
#print Dumper(\@genes); exit;
    for (my $i = 0; $i <= $#genes -1; $i++) {
	my @cds = sort {$a <=> $b} ($genes[$i]->{cdhit}, $genes[$i+1]->{cdhit});
#	$pairs_in_genomes{$cds[0]."-".$cds[1]}->{$gid}++;
	my $cd_pair = join "-", @cds;
	$seen_pairs{$cd_pair}++; 
	$pairs_in_genomes{$gid}->{$cd_pair}++;
	$columns{$cd_pair}->{$gid}++;	

	}
    }


