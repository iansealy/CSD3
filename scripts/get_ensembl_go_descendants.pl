#!/usr/bin/env perl

# PODNAME: get_ensembl_go_descendants.pl
# ABSTRACT: Get Ensembl GO terms with all their descendant terms

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

no warnings 'recursion';    ## no critic (ProhibitNoWarnings)

use Bio::EnsEMBL::Registry;

# Default options
my $accession_regexp;
my $ensembl_dbhost = 'ensembldb.ensembl.org';
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
my $goa =
  Bio::EnsEMBL::Registry->get_adaptor( 'Multi', 'Ontology', 'OntologyTerm' );

# Ensure database connection isn't lost; Ensembl 64+ can do this more elegantly
## no critic (ProhibitMagicNumbers)
if ( Bio::EnsEMBL::ApiVersion::software_version() < 64 ) {
## use critic
    Bio::EnsEMBL::Registry->set_disconnect_when_inactive();
}
else {
    Bio::EnsEMBL::Registry->set_reconnect_when_lost();
}

my $statement =
  q(SELECT accession FROM term WHERE is_obsolete = 0 AND accession LIKE "GO:%");
my $sth = $goa->prepare($statement);
$sth->execute();
my $accession;
$sth->bind_columns( \($accession) );
while ( $sth->fetch() ) {
    next if defined $accession_regexp && $accession !~ m/$accession_regexp/xms;
    my $term = $goa->fetch_by_accession($accession);
    my %descendant =
      map { $_->accession => 1 } @{ $goa->fetch_all_by_ancestor_term($term) };
    printf "%s\t%s\t%s\t%s\n", $term->accession, $term->name,
      $term->namespace, ( join q{,}, sort keys %descendant ) || q{-};
}

# Get and check command line options
sub get_and_check_options {

    # Get options
    GetOptions(
        'accession_regexp=s' => \$accession_regexp,
        'ensembl_dbhost=s'   => \$ensembl_dbhost,
        'ensembl_dbport=i'   => \$ensembl_dbport,
        'ensembl_dbuser=s'   => \$ensembl_dbuser,
        'ensembl_dbpass=s'   => \$ensembl_dbpass,
        'debug'              => \$debug,
        'help'               => \$help,
        'man'                => \$man,
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

get_ensembl_go_descendants.pl

Get Ensembl GO terms with all their descendant terms

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script dumps a list of Gene Ontology terms along with a list of their
descendant terms.

=head1 EXAMPLES

    perl \
        -Ibranch-ensembl-99/ensembl/modules \
        get_ensembl_go_descendants.pl \
        > go.tsv

=head1 USAGE

   get_ensembl_go_as_gmt_stage1.pl
        [--accession_regexp regexp]
        [--ensembl_dbhost host]
        [--ensembl_dbport port]
        [--ensembl_dbuser username]
        [--ensembl_dbpass password]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--accession_regexp REGEXP>

Regular expression for limiting terms by accession.

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
