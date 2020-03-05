#!/usr/bin/env perl

# PODNAME: extend_gtf_three_prime_utrs.pl
# ABSTRACT: Extend 3' UTR length in GTF file

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2020-03-03

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use version; our $VERSION = qv('v0.1.0');

use Readonly;

# Constants
Readonly our $CHR       => 0;
Readonly our $FEATURE   => 2;
Readonly our $START     => 3;
Readonly our $END       => 4;
Readonly our $STRAND    => 6;
Readonly our $ATTRIBUTE => 8;

# Default options
my $fai_file;
my $target_length = 4000;    ## no critic (ProhibitMagicNumbers)
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my %length_of = get_chr_lengths($fai_file);

my $gtf_fh = \*STDIN;
while ( my @gene = get_gene($gtf_fh) ) {
    @gene = extend_gene(@gene);
    foreach my $fields (@gene) {
        printf "%s\n", join "\t", @{$fields};
    }
}

# Get chromosome lengths from index
sub get_chr_lengths {
    my ($file) = @_;

    my %len;

    open my $fh, q{<}, $file;
    while ( my $line = <$fh> ) {
        chomp $line;
        my ( $chr, $length ) = split /\t/xms, $line;
        $len{$chr} = $length;
    }
    close $fh;

    return %len;
}

# Get all the lines for a gene from the GTF input
{
    my $prev_gene_line;

    sub get_gene {
        my ($fh) = @_;

        # Print comments and get first gene line
        if ( !$prev_gene_line ) {
            while ( my $line = <$fh> ) {
                chomp $line;
                if ( $line =~ m/\A[#]/xms ) {
                    printf "%s\n", $line;
                }
                else {
                    $prev_gene_line = [ split /\t/xms, $line ];
                    last;
                }
            }
        }

        my @gene_lines = ($prev_gene_line);

        while ( my $line = <$fh> ) {
            chomp $line;
            my @fields = split /\t/xms, $line;
            if ( $fields[$FEATURE] eq 'gene' ) {
                $prev_gene_line = \@fields;
                last;
            }
            push @gene_lines, \@fields;
        }

        if ( scalar @gene_lines == 1 ) {
            return;
        }

        return @gene_lines;
    }
}

# Extend gene's 3' UTR/end
sub extend_gene {    ## no critic (ProhibitExcessComplexity)
    my @gene_components = @_;

    my @edited_gene_components;

    my $gene        = $gene_components[0];
    my $gene_start  = $gene->[$START];
    my $gene_end    = $gene->[$END];
    my $chr_length  = $length_of{ $gene->[$CHR] };
    my $strand      = $gene->[$STRAND];
    my @transcripts = grep { $_->[$FEATURE] eq 'transcript' } @gene_components;
    foreach my $transcript (@transcripts) {

        # Format for changes is:
        # "feature type", "old start", "old end", "new start", "new end"
        my @changes;

        my ($transcript_id) =
          $transcript->[$ATTRIBUTE] =~ m/(ENSDART\d{11})/xms;
        my @transcript_components =
          grep { $_->[$ATTRIBUTE] =~ m/$transcript_id/xms; } @gene_components;
        shift @transcript_components;
        my @exons = grep { $_->[$FEATURE] eq 'exon' } @transcript_components;
        my @cdss  = grep { $_->[$FEATURE] eq 'CDS' } @transcript_components;
        my @three_prime_utrs =
          grep { $_->[$FEATURE] eq 'three_prime_utr' } @transcript_components;

        if (@three_prime_utrs) {

            # We're changing an existing 3' UTR
            my $current_utr_length = 0;
            foreach my $utr (@three_prime_utrs) {
                $current_utr_length += $utr->[$END] - $utr->[$START] + 1;
            }
            if ( $current_utr_length < $target_length ) {
                my $extension = $target_length - $current_utr_length;
                if ( $strand eq q{+} ) {
                    push @changes,
                      [
                        'three_prime_utr',
                        $three_prime_utrs[-1]->[$START],
                        $three_prime_utrs[-1]->[$END],
                        $three_prime_utrs[-1]->[$START],
                        $three_prime_utrs[-1]->[$END] + $extension
                      ];
                    push @changes,
                      [
                        'exon',             $exons[-1]->[$START],
                        $exons[-1]->[$END], $exons[-1]->[$START],
                        $exons[-1]->[$END] + $extension
                      ];
                }
                elsif ( $strand eq q{-} ) {
                    push @changes,
                      [
                        'three_prime_utr',
                        $three_prime_utrs[-1]->[$START],
                        $three_prime_utrs[-1]->[$END],
                        $three_prime_utrs[-1]->[$START] - $extension,
                        $three_prime_utrs[-1]->[$END]
                      ];
                    push @changes,
                      [
                        'exon',             $exons[-1]->[$START],
                        $exons[-1]->[$END], $exons[-1]->[$START] - $extension,
                        $exons[-1]->[$END]
                      ];
                }
            }
        }
        elsif (@cdss) {

            # We're changing a transcript that doesn't have a separately
            # annotated UTR but does have a CDS
            my $last_cds_length = $cdss[-1]->[$END] - $cdss[-1]->[$START] + 1;
            my $current_utr_length = -$last_cds_length;
            my @potential_utr_exons;
            if ( $strand eq q{+} ) {
                @potential_utr_exons =
                  grep { $_->[$START] >= $cdss[-1]->[$START] } @exons;
            }
            elsif ( $strand eq q{-} ) {
                @potential_utr_exons =
                  grep { $_->[$END] <= $cdss[-1]->[$END] } @exons;
            }
            foreach my $utr (@potential_utr_exons) {
                $current_utr_length += $utr->[$END] - $utr->[$START] + 1;
            }
            if ( $current_utr_length < $target_length ) {
                my $extension = $target_length - $current_utr_length;
                if ( $strand eq q{+} ) {
                    push @changes,
                      [
                        'exon',             $exons[-1]->[$START],
                        $exons[-1]->[$END], $exons[-1]->[$START],
                        $exons[-1]->[$END] + $extension
                      ];
                }
                elsif ( $strand eq q{-} ) {
                    push @changes,
                      [
                        'exon',             $exons[-1]->[$START],
                        $exons[-1]->[$END], $exons[-1]->[$START] - $extension,
                        $exons[-1]->[$END]
                      ];
                }
            }
        }
        else {
            # We're changing a transcript that doesn't have a CDS, so just
            # extend transcript
            if ( $strand eq q{+} ) {
                push @changes,
                  [
                    'exon',             $exons[-1]->[$START],
                    $exons[-1]->[$END], $exons[-1]->[$START],
                    $exons[-1]->[$END] + $target_length
                  ];
            }
            elsif ( $strand eq q{-} ) {
                push @changes,
                  [
                    'exon',             $exons[-1]->[$START],
                    $exons[-1]->[$END], $exons[-1]->[$START] - $target_length,
                    $exons[-1]->[$END]
                  ];
            }
        }

        my @edited_transcript_components;
        my $transcript_start = $transcript->[$START];
        my $transcript_end   = $transcript->[$END];
        foreach my $component (@transcript_components) {
            foreach my $change (@changes) {
                my ( $feature, $start, $end, $new_start, $new_end ) =
                  @{$change};

                # Don't extend off chromosome
                if ( $new_start < 1 ) {
                    $new_start = 1;
                }
                if ( $new_end > $chr_length ) {
                    $new_end = $chr_length;
                }

                # Apply change if matches current component
                if (   $component->[$FEATURE] eq $feature
                    && $component->[$START] == $start
                    && $component->[$END] == $end )
                {
                    $component->[$START] = $new_start;
                    $component->[$END]   = $new_end;
                    last;
                }
            }
            push @edited_transcript_components, $component;
            if ( $component->[$START] < $transcript_start ) {
                $transcript_start = $component->[$START];
            }
            if ( $component->[$END] > $transcript_end ) {
                $transcript_end = $component->[$END];
            }
        }
        $transcript->[$START] = $transcript_start;
        $transcript->[$END]   = $transcript_end;
        push @edited_gene_components, $transcript,
          @edited_transcript_components;
        if ( $transcript->[$START] < $gene_start ) {
            $gene_start = $transcript->[$START];
        }
        if ( $transcript->[$END] > $gene_end ) {
            $gene_end = $transcript->[$END];
        }
    }
    $gene->[$START] = $gene_start;
    $gene->[$END]   = $gene_end;
    unshift @edited_gene_components, $gene;

    return @edited_gene_components;
}

# Get and check command line options
sub get_and_check_options {

    # Get options
    GetOptions(
        'fai_file=s' => \$fai_file,
        'length=i'   => \$target_length,
        'debug'      => \$debug,
        'help'       => \$help,
        'man'        => \$man,
    ) or pod2usage(2);

    # Documentation
    if ($help) {
        pod2usage(1);
    }
    elsif ($man) {
        pod2usage( -verbose => 2 );
    }

    # Check options
    if ( !$fai_file ) {
        pod2usage("--fai_file must be specified\n");
    }

    return;
}

__END__
=pod

=encoding UTF-8

=head1 NAME

extend_gtf_three_prime_utrs.pl

Extend 3' UTR length in GTF file

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script takes an Ensembl GTF file and extends all 3' UTRs (adding them if
necessary) to a minimum specified target length.

=head1 EXAMPLES

    perl extend_gtf_three_prime_utrs.pl --fai_file grcz11.fa.fai \
        < in.gtf > out.gtf

    perl extend_gtf_three_prime_utrs.pl --fai_file grcz11.fa.fai --length 1000 \
        < in.gtf > out.gtf

=head1 USAGE

    extend_gtf_three_prime_utrs.pl
        [--fai_file file]
        [--length length]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--fai_file FILE>

Tab separated file of chromosomes and their lengths (FASTA index file).

=item B<--length LENGTH>

Minimum number of base pairs to extend 3' UTR to.

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
