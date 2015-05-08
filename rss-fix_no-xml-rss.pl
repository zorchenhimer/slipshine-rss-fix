#!/usr/bin/perl

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use LWP::Simple;

my $borked_rss = get('http://orgymania.net/updates.xml');
$borked_rss =~ /<channel>(.*?)<item>/s;
my $header = $1;
my %header_sections = $header =~ /<([^>]+)>(.*?)<\/\1>/smg;

$header_sections{'docs'} = '';
$header_sections{'generator'} = 'Not Slipshine.  That shit\'s borked.';

my @items = $borked_rss =~ /<item>(.*?)<\/item>/smg;
my @ul_links;

foreach my $item (@items) {
    my %sections = $item =~ /<([^>]+)>(.*?)<\/\1>/smg;

    $sections{'description'} =~ m/<ul>(.*?)<\/ul>/smg;
    my @list_items = split /<li>/, $1;
    foreach my $l (@list_items) {
        if ($l) {
            $l =~ m#<a href="(.*?)">(.*?)</a>#;
            my $ul_link = $1;
            my $ul_title = $2;

            my %link_data;
            $link_data{'link'} = $ul_link;
            $link_data{'title'} = $ul_title;
            $link_data{'pubDate'} = $sections{'pubDate'};

            push @ul_links, \%link_data;
        }
    }
}

print "Content-type: text/xml\n\n";

print qq(<?xml version="1.0" encoding="iso-8859-1" ?>\n<rss version="2.0">\n);
print "<channel>\n\t<title>$header_sections{title}</title>\n",
    "\t<description>$header_sections{description}</description>\n",
    "\t<pubDate>$header_sections{pubDate}</pubDate>\n",
    "\t<generator>$header_sections{generator}</generator>\n",
    "\t<link>$header_sections{link}</link>\n";

foreach my $nlink (@ul_links) {
    print "\t<item>\n";
    print "\t\t<title>$nlink->{title}</title>\n";
    print "\t\t<guid>$nlink->{link}</guid>\n";
    print "\t\t<link>$nlink->{link}</link>\n";
    print "\t\t<pubDate>$nlink->{pubDate}</pubDate>\n";
    print "\t\t<description><![CDATA[<a href=\"$nlink->{link}\">$nlink->{title}</a>]]></description>\n";
    print "\t</item>\n";
}
print "</channel>\n</rss>\n";
