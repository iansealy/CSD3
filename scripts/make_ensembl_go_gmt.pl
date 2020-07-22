#!/usr/bin/env perl

# PODNAME: make_ensembl_go_gmt.pl
# ABSTRACT: Make Ensembl Gene Ontology GMT files for GSEA

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2020-07-21

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $go_file;
my $go_gene_file;
## no critic (ProhibitMagicNumbers)
my $min_set_size = 5;
my $max_set_size = 2000;
## use critic
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my @namespaces = qw(biological_process cellular_component molecular_function);

# Read in genes associated with each GO term
my $go2gene = read_go_gene_file($go_gene_file);

# Handle each namespace separately
foreach my $namespace (@namespaces) {
    my $short_namespace = uc $namespace;
    $short_namespace =~
      s/\A ([[:upper:]])[[:upper:]]+_([[:upper:]])[[:upper:]]+ \z/$1$2/xms;

    # Read in GO terms with their descendants
    my ( $go2go, $name_for, $allgene2go, $go_count_for ) =
      read_go_file( $go_file, $namespace, $go2gene );

# Output gene sets, collapsing duplicates
# Show name only for term with smallest number of genes, but list all accessions
    open my $fh, '>', $short_namespace . '.gmt'; ## no critic (RequireBriefOpen)
    foreach my $genes ( keys %{$allgene2go} ) {
        ## no critic (ProhibitReverseSortBlock)
        my @terms =
          sort { $go_count_for->{$b} <=> $go_count_for->{$a} || $a cmp $b }
          keys %{ $allgene2go->{$genes} };
        ## use critic
        my $term        = $terms[0];
        my $short_terms = join q{_}, @terms;
        $short_terms =~ s/://xmsg;
        printf {$fh} "GO_%s_%s_%s\thttps://www.ebi.ac.uk/QuickGO/term/%s\t%s\n",
          $short_namespace, uc $name_for->{$term}, $short_terms, $term, $genes;
    }
    close $fh;
}

sub read_go_gene_file {
    my ($file) = @_;

    my %go2gene;

    open my $fh, '<', $file;
    while ( my $line = <$fh> ) {
        chomp $line;
        my ( $term, $genes ) = split /\t/xms, $line;
        my @genes = split /,/xms, $genes;
        $go2gene{$term} = \@genes;
    }
    close $fh;

    return \%go2gene;
}

sub read_go_file {
    ## no critic (ProhibitReusedNames)
    my ( $file, $required_namespace, $go2gene ) = @_;
    ## use critic

    my %go2go;
    my %name_for;
    my %allgene2go;
    my %go_count_for;
    open my $fh, '<', $file;    ## no critic (RequireBriefOpen)
    while ( my $line = <$fh> ) {
        chomp $line;
        my ( $parent_term, $name, $namespace, $terms ) = split /\t/xms, $line;
        next if $namespace ne $required_namespace;
        if ( $terms eq q{-} ) {
            $terms = q{};
        }
        my @terms = split /,/xms, $terms;
        push @terms, $parent_term;
        my %gene;
        foreach my $term (@terms) {
            if ( exists $go2gene->{$term} ) {
                foreach my $gene ( @{ $go2gene->{$term} } ) {
                    $gene{$gene} = 1;
                }
            }
        }
        next
          if scalar keys %gene < $min_set_size
          || scalar keys %gene > $max_set_size;
        my $genes = join "\t", sort keys %gene;
        $name =~ s/[ -]+/_/xmsg;
        $name =~ s/_+/_/xmsg;
        $name =~ s/\W+//xmsg;
        $go2go{$parent_term}              = $terms;
        $name_for{$parent_term}           = $name;
        $allgene2go{$genes}{$parent_term} = 1;
        $go_count_for{$parent_term}       = scalar @terms;
    }
    close $fh;

    return \%go2go, \%name_for, \%allgene2go, \%go_count_for;
}

# Get and check command line options
sub get_and_check_options {

    # Get options
    GetOptions(
        'go_file=s'      => \$go_file,
        'go_gene_file=s' => \$go_gene_file,
        'min_set_size=i' => \$min_set_size,
        'max_set_size=i' => \$max_set_size,
        'debug'          => \$debug,
        'help'           => \$help,
        'man'            => \$man,
    ) or pod2usage(2);

    # Documentation
    if ($help) {
        pod2usage(1);
    }
    elsif ($man) {
        pod2usage( -verbose => 2 );
    }

    if ( !$go_file ) {
        pod2usage("--go_file must be specified\n");
    }
    if ( !$go_gene_file ) {
        pod2usage("--go_gene_file must be specified\n");
    }

    return;
}

__END__
=pod

=encoding UTF-8

=head1 NAME

make_ensembl_go_gmt.pl

Make Ensembl Gene Ontology GMT files for GSEA

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script takes the output of get_ensembl_go_terms.pl and of
switch_ensembl_go_terms.pl (which in turn operates on the output of
get_ensembl_go_descendants.pl) and writes out Ensembl Gene Ontology GMT files
for use with GSEA.

=head1 EXAMPLES

    perl make_ensembl_go_gmt.pl \
      --go_file go.tsv \
      --go_gene_file go-gene.tsv

    perl make_ensembl_go_gmt.pl \
      --go_file go.tsv \
      --go_gene_file go-gene.tsv \
      --min_set_size 25 \
      --max_set_size 500

=head1 USAGE

   make_ensembl_go_gmt.pl
        [--go_file file]
        [--go_gene_file file]
        [--min_set_size int]
        [--max_set_size int]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--go_file FILE>

File listing GO terms and heir descendants. Produced by
get_ensembl_go_descendants.pl.

=item B<--go_gene_file FILE>

File list GO terms and genes associated with them. Produced by
get_ensembl_go_terms.pl and switch_ensembl_go_terms.pl.

=item B<--min_set_size INT>

The minimum number of genes that a set must contain.

=item B<--max_set_size INT>

The maximum number of genes that a set can contain.

=item B<--debug>

Print debugging information.

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print this script's manual page and exit.

=back

=head1 DEPENDENCIES

None

=head1 AUTHOR

=over 4

=item *

Ian Sealy

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Ian Sealy.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
