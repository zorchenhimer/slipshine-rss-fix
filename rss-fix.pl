#!/usr/bin/perl

##
## The MIT License (MIT)
##
## Copyright (c) 2015 Nick Scheibenpflug
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
## THE SOFTWARE.
##

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use LWP::Simple;

# Get the broken RSS feed.
my $borked_rss = get('http://orgymania.net/updates.xml');

# Grab the RSS header.
$borked_rss =~ /<channel>(.*?)<item>/s;
my $header = $1;
my %header_sections = $header =~ /<([^>]+)>(.*?)<\/\1>/smg;

$header_sections{'generator'} = 'Not Slipshine.  That shit\'s borked.';

# Grab all the <item> elements.
my @items = $borked_rss =~ /<item>(.*?)<\/item>/smg;
my @ul_links;

# Iterate over each item in the <channel> and extract all the links.
foreach my $item (@items) {
    # Get a hash of all the tags in the current <item> element.
    my %sections = $item =~ /<([^>]+)>(.*?)<\/\1>/smg;

    # Get a list of all the updates in the description.
    $sections{'description'} =~ m/<ul>(.*?)<\/ul>/smg;
    my @list_items = split /<li>/, $1;

    # Each update gets its own <item> and we will find more than one link per
    # <item> on occasion.
    foreach my $l (@list_items) {
        if ($l) {
            # Grab the real URL, update title, and user title
            # (eg. 'updated by ...').
            $l =~ m#<a href="(.*?)">(.*?)</a>(.*)#;
            my $ul_link = $1;
            my $ul_title = $2;
            my $ul_title_b = $3;

            $ul_title_b =~ s/<(.*?)>//g;

            # Package the new data.
            my %link_data;
            $link_data{'link'} = $ul_link;
            $link_data{'title'} = $ul_title;
            $link_data{'titleb'} = $ul_title_b;
            $link_data{'pubDate'} = $sections{'pubDate'};

            # Store the data.
            push @ul_links, \%link_data;
        }
    }
}

# Print directly to the browser.
print "Content-type: text/xml\n\n";

# RSS header stuff.
print qq(<?xml version="1.0" encoding="iso-8859-1" ?>\n<rss version="2.0">\n);
print "<channel>\n\t<title>$header_sections{title}</title>\n",
    "\t<description>$header_sections{description}</description>\n",
    "\t<pubDate>$header_sections{pubDate}</pubDate>\n",
    "\t<generator>$header_sections{generator}</generator>\n",
    "\t<link>$header_sections{link}</link>\n";

# Print each <item>.
foreach my $nlink (@ul_links) {
    print "\t<item>\n",
        "\t\t<title>$nlink->{title}</title>\n",
        "\t\t<guid>$nlink->{link}</guid>\n",
        "\t\t<link>$nlink->{link}</link>\n",
        "\t\t<pubDate>$nlink->{pubDate}</pubDate>\n",
        "\t\t<description><![CDATA[<a href=\"$nlink->{link}\">$nlink->{title}</a>$nlink->{titleb}]]></description>\n",
        "\t</item>\n";
}

# RSS footer.
print "</channel>\n</rss>\n";
