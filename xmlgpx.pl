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

my $context = $doc;
my $xpath;

# Find nodes using XPath
my $default_ns = $doc->documentElement->namespaceURI();

if ($default_ns) {
    my $xpc = XML::LibXML::XPathContext->new($doc);
    $xpc->registerNs('gpx', $default_ns);
    $xpath = '//gpx:trk/gpx:name';
    $context = $xpc;
} else {
    # Fallback for files with no namespace
    $xpath = '//trk/name';
}

my @nodes = eval { $context->findnodes($xpath) };
if ($@) {
    print STDERR "Error during XPath query on '$filename': $@";
} else {
    foreach my $node (@nodes) {
        print "TRK-NAME: " . $node->textContent  . "\n" ;
    }
}
