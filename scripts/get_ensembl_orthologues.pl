#!/usr/bin/env perl

# PODNAME: get_ensembl_orthologues.pl
# ABSTRACT: Get all orthologues from a species for all genes of another species

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2020-03-22

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use version; our $VERSION = qv('v0.1.0');

use Bio::EnsEMBL::Registry;

# Default options
my $species            = 'Homo sapiens';
my $orthologue_species = 'Danio rerio';
my $ensembl_dbhost     = 'ensembldb.ensembl.org';
my $ensembl_dbport;
my $ensembl_dbuser = 'anonymous';
my $ensembl_dbpass;
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

# Connnect to Ensembl database
Bio::EnsEMBL::Registry->load_registry_from_db(
    -host => $ensembl_dbhost,
    -port => $ensembl_dbport,
    -user => $ensembl_dbuser,
    -pass => $ensembl_dbpass,
);

# Get genebuild version
my $genebuild_version = 'e' . Bio::EnsEMBL::ApiVersion::software_version();
warn 'Genebuild version: ', $genebuild_version, "\n" if $debug;

# Get Ensembl adaptors
my $ga = Bio::EnsEMBL::Registry->get_adaptor( $species, 'core', 'Gene' );
my $gma =
  Bio::EnsEMBL::Registry->get_adaptor( 'Multi', 'Compara', 'GeneMember' );
my $ha = Bio::EnsEMBL::Registry->get_adaptor( 'Multi', 'Compara', 'Homology' );

# Ensure database connection isn't lost; Ensembl 64+ can do this more elegantly
## no critic (ProhibitMagicNumbers)
if ( Bio::EnsEMBL::ApiVersion::software_version() < 64 ) {
## use critic
    Bio::EnsEMBL::Registry->set_disconnect_when_inactive();
}
else {
    Bio::EnsEMBL::Registry->set_reconnect_when_lost();
}

# Get all genes
my $genes = $ga->fetch_all();
foreach my $gene ( sort { $a->stable_id cmp $b->stable_id } @{$genes} ) {
    my @orthologues;
    my $member = $gma->fetch_by_stable_id( $gene->stable_id );
    if ($member) {
        my $homologies = $ha->fetch_all_by_Member( $member,
            -TARGET_SPECIES => $orthologue_species );
        foreach my $homology ( @{$homologies} ) {
            foreach my $homology_member ( @{ $homology->gene_list() } ) {
                next if $homology_member->stable_id eq $gene->stable_id;
                push @orthologues, $homology_member->stable_id . q{:}
                  . ( $homology->is_high_confidence() ? q{1} : q{0} );
            }
        }
    }
    printf "%s\n", join "\t", $gene->stable_id,
      ( join q{,}, sort @orthologues );
}

# Get and check command line options
sub get_and_check_options {

    # Get options
    GetOptions(
        'species=s'            => \$species,
        'orthologue_species=s' => \$orthologue_species,
        'ensembl_dbhost=s'     => \$ensembl_dbhost,
        'ensembl_dbport=i'     => \$ensembl_dbport,
        'ensembl_dbuser=s'     => \$ensembl_dbuser,
        'ensembl_dbpass=s'     => \$ensembl_dbpass,
        'debug'                => \$debug,
        'help'                 => \$help,
        'man'                  => \$man,
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

get_ensembl_orthologues.pl

Get all orthologues from a species for all genes of another species

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script dumps a list of Ensembl gene stable IDs along with stable IDs of
orthologous genes from another species. Each orthologous gene has a :1 or :0
appended to its stable ID to indicate whether it's a high confidence or low
confidence orthologue respectively.

=head1 EXAMPLES

    perl \
        -Ibranch-ensembl-99/ensembl/modules \
        get_ensembl_orthologues.pl

    perl \
        -Ibranch-ensembl-99/ensembl/modules \
        get_ensembl_orthologues.pl \
        --species "Homo sapiens" \
        --orthologue_species "Danio rerio"

=head1 USAGE

    get_ensembl_orthologues.pl
        [--species species]
        [--orthologue_species species]
        [--ensembl_dbhost host]
        [--ensembl_dbport port]
        [--ensembl_dbuser username]
        [--ensembl_dbpass password]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--species SPECIES>

Species (defaults to "Homo sapiens").

=item B<--orthologue_species SPECIES>

Orthologous species (defaults to "Danio rerio").

=item B<--ensembl_dbhost HOST>

Ensembl MySQL database host.

=item B<--ensembl_dbport PORT>

Ensembl MySQL database port.

=item B<--ensembl_dbuser USERNAME>

Ensembl MySQL database username.

=item B<--ensembl_dbpass PASSWORD>

Ensembl MySQL database password.

=item B<--debug>

Print debugging information.

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print this script's manual page and exit.

=back

=head1 DEPENDENCIES

Ensembl Perl API - http://www.ensembl.org/info/docs/api/

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
