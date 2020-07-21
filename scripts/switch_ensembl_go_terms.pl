#!/usr/bin/env perl

# PODNAME: switch_ensembl_go_terms.pl
# ABSTRACT: Switch order of list of GO terms and Ensembl genes

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
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my %go2gene;

# Iterate over STDIN
while ( my $line = <> ) {
    chomp $line;
    my ( $gene, $terms ) = split /\t/xms, $line;
    next if $terms eq q{-};
    my @terms = split /,/xms, $terms;
    foreach my $term (@terms) {
        $go2gene{$term}{$gene} = 1;
    }
}

foreach my $term ( sort keys %go2gene ) {
    printf "%s\t%s\n", $term, ( join q{,}, sort keys %{ $go2gene{$term} } );
}

# Get and check command line options
sub get_and_check_options {

    # Get options
    GetOptions(
        'debug' => \$debug,
        'help'  => \$help,
        'man'   => \$man,
    ) or pod2usage(2);

    # Documentation
    if ($help) {
        pod2usage(1);
    }
    elsif ($man) {
        pod2usage( -verbose => 2 );
    }

    return;
}

__END__
=pod

=encoding UTF-8

=head1 NAME

switch_ensembl_go_terms.pl

Switch order of list of GO terms and Ensembl genes

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script takes the output of get_ensembl_go_descendants.pl and switches the
order from a list of of Ensembl genes with associated GO terms to a list of GO
terms with associated Ensembl genes.

=head1 EXAMPLES

    cat gene-go.tsv | perl switch_ensembl_go_terms.pl \
        > go-gene.tsv

=head1 USAGE

   get_ensembl_go_terms.pl
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

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
