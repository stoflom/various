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

# Register namespaces
$xpc->registerNs('tx', "http://www.topografix.com/GPX/1/0");


# Find nodes using XPath
my @nodes = eval { $xpc->findnodes('//tx:trk/tx:name') };
if ($@) {
    print STDERR "Error during XPath query on '$filename': $@";
} else {
    foreach my $node (@nodes) {
        print "TRK-NAME: " . $node->textContent  . "\n" ;
    }
}
