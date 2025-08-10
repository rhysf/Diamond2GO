package fastafile;
use strict;
use Bio::SeqIO;
use Exporter;
use Encode;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.1;
@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw();
%EXPORT_TAGS = (DEFAULT => [qw()], ALL =>[qw()]);
use FindBin qw($Bin);
use lib "$Bin";

### rfarrer@broadinstitute.org

sub init_fasta_struct {
	my $fasta_struct = $_[0];
	my %new_struct;
	$new_struct{'filename'} = $$fasta_struct{'filename'};
	return \%new_struct
}

sub fasta_to_struct {
	my $input = $_[0];
	my %struct;
	$struct{'filename'} = $input;
	warn "fasta_to_struct: saving from $input...\n";
	my $inseq = Bio::SeqIO->new('-file' => "<$input",'-format' => 'fasta');
	while (my $seq_obj = $inseq->next_seq) { 
		my $id = $seq_obj->id;
		my $seq = $seq_obj->seq;
		my $desc = $seq_obj->description;
		my $length = length($seq);
		
		# Save
		$struct{'seq'}{$id} = $seq;
		$struct{'desc'}{$id} = $desc;
		$struct{'seq_length'}{$id} = $length;
		push @{$struct{'order'}}, $id;
	}
	return \%struct;
}

sub fasta_struct_print {
	my ($fasta_struct, $output_format, $data_type, $split_into_files, $outfile_optional_parameter) = @_;
	die "fasta_struct_print: $output_format\n" if($output_format eq 'none');
	die "fasta_struct_print: $output_format not recognised\n" unless($output_format =~ m/color|fasta|tba|fastq|nexus|phylip/);
	die "fasta_struct_print: $data_type not recognised for nexus output\n" if(($output_format =~ m/nexus/) && ($data_type !~ m/dna|prot/));

	# Outfile?
	my $ofh;
	if(defined $outfile_optional_parameter) {
		open $ofh, '>', $outfile_optional_parameter or die "Cannot open $outfile_optional_parameter : $!\n";
	}

	# Go through the FASTA struct accordind to the order array
	warn "fasta_struct_print output=$output_format\n";
	my ($sequence_length, $sequence_count, $split_count, $split_name) = (0, 0, 0, 0);
	FASTA: foreach my $id(@{$$fasta_struct{'order'}}) {
		die "no sequence found in FASTA struct for $id\n" if(!defined $$fasta_struct{'seq'}{$id});
		my $seq  = $$fasta_struct{'seq'}{$id};
		my $desc = $$fasta_struct{'desc'}{$id};

		# Nexus format (all are expected to be the same length)
		$sequence_length = length($seq); 
		$sequence_count++;

		# only FASTA supported
		($split_count, $split_name, $ofh) = &fasta_struct_print_to_fasta($fasta_struct, $id, $split_into_files, $split_count, $split_name, $ofh); 

	}

	return 1;
}


sub fasta_struct_print_to_fasta {
	my ($fasta_struct, $id, $split_into_files, $split_count, $split_name, $ofh_optional_parameter) = @_;

	# Check an id is defined
	die "$id not found in FASTA structure\n" if(!defined $$fasta_struct{'seq'}{$id});

	# Get sequence
	my $seq = $$fasta_struct{'seq'}{$id};
	$seq =~ s/(\S{60})/$1\n/g;

	# Get description
	my $desc = "";
	if(defined $$fasta_struct{'desc'}{$id}) { $desc = " $$fasta_struct{'desc'}{$id}"; }
	my $filename = $$fasta_struct{'filename'};
	my $entry = ">$id$desc\n$seq\n";
	my $output_name;

	# Print to standard output
	if($split_into_files eq 'n') { 
		if(defined $ofh_optional_parameter) { print $ofh_optional_parameter "$entry"; }
		else { print "$entry"; }
	}

	# Print to separate files
	else {
		if($split_count eq 0) {
			if($split_into_files eq 1) { $output_name = ($filename . '-' . $id . '.fasta'); }
			else { $output_name = ($filename . '-split-into-' . $split_into_files . '-entries-per-file-pt-' . $split_name . '.fasta'); }
			open $ofh_optional_parameter, '>', $output_name or die "Cannot open $output_name: $!\n";
		}
		print $ofh_optional_parameter $entry;
		$split_count++;
		if($split_count eq $split_into_files) {
			$split_count = 0;
			close $ofh_optional_parameter;
			$split_name++;
		}
	}
	return ($split_count, $split_name, $ofh_optional_parameter);
}

sub remove_stop_codons {
	my $fasta_struct = $_[0];
	warn "remove_stop_codons...\n";
	my $new_fasta = &init_fasta_struct($fasta_struct);
	FASTA: foreach my $id(@{$$fasta_struct{'order'}}) {
		die "no sequence found in FASTA struct for $id\n" if(!defined $$fasta_struct{'seq'}{$id});
		my $seq  = $$fasta_struct{'seq'}{$id};
		my $desc = $$fasta_struct{'desc'}{$id};
		my $length = length($seq);

		$seq =~ s/\*//g;

		# save
		$$new_fasta{'seq'}{$id} = $seq;
		$$new_fasta{'desc'}{$id} = $desc;
		$$new_fasta{'seq_length'}{$id} = $length;
		push @{$$new_fasta{'order'}}, $id;
	}
	return $new_fasta;
}

sub remove_genes {
	my ($fasta_struct, $gene_ids_with_no_hits) = @_;
	warn "remove_genes...\n";

	my $genes_total = 0;
	my $genes_removed = 0;
	my $new_fasta = &init_fasta_struct($fasta_struct);
	FASTA: foreach my $id(@{$$fasta_struct{'order'}}) {
		die "no sequence found in FASTA struct for $id\n" if(!defined $$fasta_struct{'seq'}{$id});
		my $seq  = $$fasta_struct{'seq'}{$id};
		my $desc = $$fasta_struct{'desc'}{$id};
		my $length = length($seq);

		$genes_total++;
		if(!defined $$gene_ids_with_no_hits{$id}) {
			$genes_removed++;
			next FASTA;
		}

		# save
		$$new_fasta{'seq'}{$id} = $seq;
		$$new_fasta{'desc'}{$id} = $desc;
		$$new_fasta{'seq_length'}{$id} = $length;
		push @{$$new_fasta{'order'}}, $id;
	}
	warn "remove_genes: ignoring $genes_removed / $genes_total genes that already have GO-terms\n";
	return $new_fasta;
}

sub fasta_id_to_order_array {
	my $input = $_[0];
	my @order;
	warn "fasta_id_to_order_array: saving order from $input...\n";
	my $inseq = Bio::SeqIO->new('-file' => "<$input",'-format' => 'fasta');
	while (my $seq_obj = $inseq->next_seq) { 
		my $id = $seq_obj->id;
		push @order, $id;
	}
	return (\@order);
}

1;
