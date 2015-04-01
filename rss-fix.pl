#!/usr/bin/perl

use strict;
use warnings;

use XML::RSS;
use LWP::Simple;
use Digest::MD5 qw(md5_hex);

my $rss = new XML::RSS;
my $borked_rss = get('http://orgymania.net/updates.xml');
my $data = $rss->parse($borked_rss);

foreach my $item (@{$data->{'items'}}) {
    my $orig_title = $item->{'title'};
    $item->{'description'} =~ /<a href="([^"]+)">([^<]+)<\/a>/;
    my ($real_link, $real_title) = ($1, $2);

    $item->{'description'} =~ s/<.*?>//g;
    $item->{'description'} =~ s/\s+/ /sg;

    $item->{'description'} =~ s/^ //g;
    $item->{'description'} =~ s/ $//g;

    $item->{'link'} = $real_link;
    $item->{'title'} = $real_title;
    $item->{'guid'} = md5_hex("$orig_title $real_link");
}

$data->save('fixed.xml');

print "Content-type: text/xml\n\n";
print $data->as_string;

