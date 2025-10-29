#!/usr/bin/perl
# Reads a GPX XML file and extract <trk><name> elements using XML::LibXML with XPath and namespaces.
# If the file contains <trk> elements the <name> of each track is printed else nothing is printed.

# use strict;
use warnings;

use XML::LibXML;
use XML::LibXML::XPathContext;

my $filename = $ARGV[0];

my $doc = XML::LibXML->load_xml(location => $filename);

# Create an XPathContext object
my $xpc = XML::LibXML::XPathContext->new($doc);

# Register namespaces
$xpc->registerNs('tx', "http://www.topografix.com/GPX/1/0");


# Find nodes using XPath
my ($tx_trk_name) = $xpc->findnodes('//tx:trk/tx:name');

foreach my $node ($xpc->findnodes('//tx:trk/tx:name')) {
    print "TRK-NAME: " . $node->textContent  . "\n" ;
}


