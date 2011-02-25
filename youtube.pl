#!/usr/bin/perl

use strict;
use Irssi;
use POSIX;
use LWP::Simple;
use HTML::Entities;
use HTML::TreeBuilder;
use Encode;
use vars qw($VERSION %IRSSI);

my $VERSION = '0.01';
my %IRSSI = (
    authors     => 'rupa',
    contact     => '',
    name        => '',
    description => 'print some info about youtube links',
    license     => '',
);

# channels to publicly display info in
my @chans = ('#mefi', '#dongs', '#sippin');

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
        $url = $_ if( $_ =~ /^http:\/\/...?\.youtube\.com/ );
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
            #} elsif( $tag eq 'description' ) {
            #$content =~ s/<br( \/)?>/ /g;
            #$content =~ s/  */ /g;
            #push @a, $tag.": ".$content;
        }
    }
    my $out = join(" ", @a);
    $out =~ s/\n/ /g;
    $out =~ s/<br>/ /g;
    $out =~ s/http:\/\///g;
    return $out;
}

sub dispatch {
    return if not Irssi::settings_get_bool("youtube");
    my ($server, $msg, $nick, $mask, $chan) = @_;
    $chan = $nick if not $chan;
    my @args = ($server, $msg, $nick, $mask, $chan);

    my ($reader, $writer);
    pipe($reader, $writer);
    my $pid = fork();
    if( not defined $pid ) {
        Irssi::print("Can't fork!");
        close($reader);
        close($writer);
    }
    if( $pid > 0 ) {
        close($writer);
        Irssi::pidwait_add($pid);
        my $p;
        my @pargs = ($reader, \$p, \@args);
        $p = Irssi::input_add(fileno($reader), INPUT_READ, \&p_input, \@pargs);
    } else {
        my $data = youtube(split(/ /, $msg));
        print ($writer $data);
        close($writer);
        POSIX::_exit(1);
    }
}

sub p_input {
    my ($reader, $pipetag, $argref) = @{$_[0]};
    my $out = <$reader>;
    close($reader);
    Irssi::input_remove($$pipetag);
    return if not $out;
    my ($server, $msg, $nick, $mask, $chan) = @{$argref};
    my $win = Irssi::active_win();
    if( grep(/^$chan$/, @chans) ) {
        $out = decode_entities($out);
        $out = uc($out) if strftime("%m/%d", localtime) eq ("10/22");
        $server->command("/MSG $chan YOUTUBE: $out");
    } else {
        $out = decode_entities($out);
        $win->print("$chan - $out", "CLIENTCRAP");
    }
}

Irssi::signal_add("message public", "dispatch");
Irssi::signal_add("message own_public", "dispatch");
Irssi::settings_add_bool("youtube", "youtube", 0);
