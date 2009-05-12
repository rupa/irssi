#!/usr/bin/perl

use strict;
use Irssi;
use POSIX;
use LWP::Simple;
use HTML::TreeBuilder;
use Encode;
use vars qw($VERSION %IRSSI);

my $VERSION = '0.01';
my %IRSSI = (
    authors     => '31d1',
    contact     => '',
    name        => '',
    description => 'youtube',
    license     => '',
);

print CLIENTCRAP "youtube.pl $VERSION loaded.";
print CLIENTCRAP "/set youtube on|off";

sub get_meta {
    my ($content) = @_;
    my ($tree, @elements, %tags, $tag);
    $tree = HTML::TreeBuilder->new;
    $tree->parse($content);
    @elements = $tree->find('meta');
    for $tag ( @elements ) {
        $tags{$tag->attr('name')} = $tag->attr('content'); 
    }
    $tree->delete;
    return %tags;
}

sub youtube {

    # some string split on whitespace pls
    my ($url, $content, %meta, $tag, @a);
    for (@_) {
        if( $_ =~ /^http:\/\/...?\.youtube\.com/ ) {
            $url = $_;
        }
    }
    $url || return "";

    $content = decode_utf8(get $url);
    return "" unless defined $content;

    %meta = get_meta($content);
    return "" if not exists($meta{'title'});

    @a = ();
    while (($tag, $content) = each(%meta)) {
        if( $tag eq 'title' ) {
            unshift @a, $tag.": ".$content;
        } elsif( $tag eq 'description' ) {
            push @a, $tag.": ".$content;
        }
    } 
    return join(" ", @a);
}

sub dispatch {
    my ($server, $msg, $nick, $mask, $chan) = @_;
    $chan = $nick if not $chan;
    my $out = youtube(split(/ /, $msg));
    return if not $out;
    my $win = Irssi::active_win();
    if( $chan eq "#mefi" ) {
        $server->command("/MSG $chan YOUTUBE: $out");
    } else {
        $win->print($out, "CLIENTCRAP");
    }
}

Irssi::signal_add("message public", "dispatch");
Irssi::signal_add("message own_public", "dispatch");
Irssi::settings_add_bool("youtube", "youtube", 0);
