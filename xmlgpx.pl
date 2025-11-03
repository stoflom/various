#!/usr/bin/perl
# Reads a GPX XML file created by gpsbabel and extracts <trk><name> elements using XML::LibXML with XPath and namespaces.
# If the file contains <trk><name> the name of each track is printed else nothing is printed.

use strict;
use warnings;

use XML::LibXML;
use XML::LibXML::XPathContext;


my $filename = $ARGV[0];
die "Usage: $0 <gpx-file>\n" unless defined $filename;

my $doc;
eval {
    $doc = XML::LibXML->load_xml(location => $filename);
};
if ($@) {
    die "Error: Failed to parse XML file '$filename'.\n$@";
}

# Create an XPathContext object
my $xpc = XML::LibXML::XPathContext->new($doc);

# Find the topografix namespace to be version-insensitive
my ($gpx_namespace) = grep { $_->getValue =~ /topografix\.com/ } $doc->documentElement->getNamespaces;
#print "Namespace: " . ($gpx_namespace ? $gpx_namespace->getValue : "None") . "\n";

# Define the XPath query
my $xpath_query;

# Find nodes using XPath
if ($gpx_namespace) {
    my $namespace_uri = $gpx_namespace->getValue;
    # Register the found namespace with a prefix 'tx'
    $xpc->registerNs('tx', $namespace_uri);
    $xpath_query = '//tx:trk/tx:name';
} else {
    # Fallback for files with no namespace
    $xpath_query = '//trk/name';
}

my @nodes = eval { $xpc->findnodes($xpath_query) };
if ($@) {
    print STDERR "Error during XPath query on '$filename': $@";
} else {
    foreach my $node (@nodes) {
        print "TRK-NAME: " . $node->textContent  . "\n" ;
    }
}
