#!/usr/bin/perl
# Note: this replaces youtube.pl and vids.pl

use strict;
use Irssi;
use POSIX;
use XML::Simple;
use LWP::Simple;
use HTML::Entities;
use HTML::TreeBuilder;
use JSON;
use Encode;
use Net::Netrc;

#use Data::Dumper;

# flickr API key goes in ~/.netrc:
# machine flickr.api
#     login YOUR_API_KEY
my $flickr_api = Net::Netrc->lookup('flickr.api');
$flickr_api = $flickr_api->login if $flickr_api;

use vars qw($VERSION %IRSSI);

my $VERSION = '0.01';
my %IRSSI = (
    authors     => 'rupa',
    contact     => '',
    name        => '',
    description => 'print some info about links',
    license     => '',
);

print CLIENTCRAP "loading linkinfo.pl $VERSION ...";

sub youtube {
    my ($id) = @_;
    #print "youtube $id";
    my %video = ( service => "YOUTUBE", title => "", description => "" );
    my $content = get "http://gdata.youtube.com/feeds/api/videos/$id";
    defined $content or return %video;
    my $ref = XMLin($content);
    my $title = $ref->{'title'}->{'content'};
    (my $description = $ref->{'content'}->{'content'}) =~ s/\s+/ /g;
    my %video = ( service => "YOUTUBE",
                  title => $title,
                  description => $description );
    for my $key ( keys %video ) {
        $video{$key} =~ s/<br>/ /g;
        $video{$key} =~ s/http:\/\///g;
    }
    return %video;
}

sub vimeo {
    my ($id) = @_;
    my %video = ( service => "VIMEO", title => "", description => "" );
    print "vimeo $id";
    my $content = get "http://vimeo.com/api/v2/video/$id.json";
    defined $content or return %video;
    my $text = from_json($content);
    #print Dumper($text);
    my %video = ( service => "VIMEO",
                  title => $text->[0]->{title},
                  description => $text->[0]->{description} );
    for my $key ( keys %video ) {
        $video{$key} =~ s/<br \/>\n/ /g;
        $video{$key} =~ s/http:\/\///g;
    }
    return %video;
}

sub flickr {
    my ($id) = @_;
    my %photo = ( service => "FLICKR", title => "", description => "" );
    my $url = "http://api.flickr.com/services/rest/";
    my $query = "method=flickr.photos.getInfo&api_key=$flickr_api&photo_id=$id";
    my $content = get "$url?$query";
    defined $content or return %photo;
    my $ref = XMLin($content);
    my $title = $ref->{'photo'}->{'title'};
    my $description = $ref->{'photo'}->{'description'};
    $title = "" if ref($title) eq "HASH";
    $description = "" if ref($description) eq "HASH";
    my %photo = ( service => "FLICKR",
                  title => $title,
                  description => $description || "" );
    for my $key ( keys %photo ) {
        $photo{$key} =~ s/<br>/ /g;
        $photo{$key} =~ s/http:\/\///g;
    }
    return %photo;
}

sub amazon {
    my ($url) = @_;
    my %thing = ( service => "AMAZON", title => "", description => "" );
    my $content = get $url;
    my $tree = HTML::TreeBuilder->new_from_content($content);
    $thing{'title'} = $tree->look_down('_tag', 'title')->as_text;
    $thing{'title'} =~ s/amazon\.com:? ?//i;
    $tree->delete();
    return %thing;
}

sub parse_string {
    # take a string and return an array of hashes {service, title, description}
    my ($str) = @_;
    #print "parsing $str";
    my @words = split(/ /, $str);
    my @out = ();
    foreach (@words) {
        next if $_ !~ /^https?:\/\//;
        if ( $_ =~ /https?:\/\/(www\.)?youtube\.com\/watch\?.*v=([^\.\!\?\#,&]*)/ ) {
            push(@out, {youtube($2)});
        } elsif( $_ =~ /^https?:\/\/(www\.)?vimeo\.com\/([^\.\!\?,]*)/ ) {
            push(@out, {vimeo($2)});
        } elsif( $_ =~ /^http:\/\/(www\.)?amazon\.com\// ) {
            push(@out, {amazon($_)});
            next;
        } elsif( $flickr_api ) {
            if( $_ =~ /https?:\/\/(www\.)?flickr\.com\/photos\/[^\/]+\/([^\/]+)\// ) {
                push(@out, {flickr($2)});
            } elsif( $_ =~ /https?:\/\/[^\.]+\.static\.flickr\.com\/[^\/]+\/([^_]+)_/ ) { 
                push(@out, {flickr($1)});
            }
        }
    }
    return @out;
}

sub dispatch {
    # don't be blockin', yo
    return if not Irssi::settings_get_bool("linkinfo");
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
        foreach( parse_string($msg) ) {
            next if not $_->{title};
            print ($writer " " . $_->{service} . ": " . $_->{title});
        }
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
    $out = decode_entities($out);
    if( grep(/^$chan$/, split(/ +/, Irssi::settings_get_str("linkinfochans")) ) ) {
        $out = uc($out) if strftime("%m/%d", localtime) eq ("10/22");
        $server->command("/MSG $chan$out");
    } else {
        $win->print("$chan -$out", "CLIENTCRAP");
    }
}

Irssi::signal_add("message public", "dispatch");
Irssi::signal_add("message own_public", "dispatch");
Irssi::settings_add_bool("linkinfo", "linkinfo", 0);
Irssi::settings_add_str("linkinfo", "linkinfochans", "");

print CLIENTCRAP "/set linkinfo on|off";
print CLIENTCRAP "/set linkinfochans #chan1 #chan2 ...";
print CLIENTCRAP "Active chans: " . Irssi::settings_get_str("linkinfochans");
