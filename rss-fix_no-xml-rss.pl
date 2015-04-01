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

my @new_items;

foreach my $item (@items) {
    my %sections = $item =~ /<([^>]+)>(.*?)<\/\1>/smg;

    $sections{'description'} =~ s/^\s+//sg;
    $sections{'description'} =~ s/\s+/ /sg;
    $sections{'description'} =~ s/<!\[CDATA\[//sg;
    $sections{'description'} =~ s/\s*\]\]>//sg;

    $sections{'description'} =~ /href="([^"]+)"/;
    my $real_link = $1;

    $sections{'description'} =~ s/<br> /\n/g;
    $sections{'description'} =~ s/<[^>]+>//g;
    $sections{'description'} =~ s/\n/ - /sg;
    $sections{'description'} =~ s/\s+$//sg;

    $sections{'description'} =~ /^(.+) by (.+) - (.+)$/;
    my $real_title = $1. ' - '. $3;

    ## Re-assignment
    $sections{'link'} = $real_link;
    $sections{'title'} = $real_title;
    $sections{'guid'} = md5_hex($real_title.$real_link);
    $sections{'description'} .= "<br /><a href=\"$real_link\">$real_link</a>";
    push(@new_items, \%sections);
}
print "Content-type: text/xml\n\n";

print qq(<?xml version="1.0" encoding="iso-8859-1" ?>\n<rss version="2.0">\n);
print "<channel>\n\t<title>$header_sections{title}</title>\n",
    "\t<description>$header_sections{description}</description>\n",
    "\t<pubDate>$header_sections{pubDate}</pubDate>\n",
    "\t<generator>$header_sections{generator}</generator>\n",
    "\t<link>$header_sections{link}</link>\n";

foreach my $n_item (@new_items) {
    print "\t<item>\n";
    foreach my $section (sort keys %{$n_item}) {
        if( $section eq 'description' ) {
            print "\t\t<description><![CDATA[$n_item->{description}]]></description>\n";
        } elsif( $section eq 'guid' ) {
            print "\t\t<guid isPermaLink=\"false\">$n_item->{guid}</guid>\n";
        } else {
            print "\t\t<$section>$n_item->{$section}</$section>\n";
        }
    }
    print "\t</item>\n";
}
print "</channel>\n</rss>\n";
