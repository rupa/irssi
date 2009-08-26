#!/usr/bin/perl -w

use strict;
use vars qw($VERSION %IRSSI);

use LWP::Simple;
use HTML::TreeBuilder;

$VERSION = '0.01';
%IRSSI = (
  authors => 'rupa',
  contact => '',
  description => 'spam your channel with random 4chan drollery',
  name => '',
  license => ''
);

# use a cached copy until number of qotes falls below $min
my $min = 30;

print CLIENTCRAP "/4ch [search]";
print CLIENTCRAP "if [search] not found, use a random quote";

my @anons = ();

sub getanons {
    # get all the <blockquotes?> out of /b/
    my $html = get("http://img.4chan.org/b/imgboard.html");
    return if( !defined $html );
    # as_text just changes <br />'s to ''
    $html =~ s/(<br \/>)+/ /g;
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($html);
    @anons = ();
    my @elements = $tree->find('blockquote');
    for (@elements) {
        my $i = $_->as_text;
        $i =~ s/>>[0-9]{9}//g;
        $i =~ s/Comment too long. Click here to view the full text\.$//;
        $i =~ s/ITT://;
        next if !$i;
        push(@anons, $i);
    }
    $tree->delete;
    return @anons;
}

sub getone {

    my ($srch, $server, $channel) = @_;
    return if not $channel;
    $channel = $channel->{name};

    @anons = getanons() if scalar(@anons) < $min;
    my $i = 0;
    if( $srch ) {
        my @fnd = grep(/$srch/i, @anons);
        if( @fnd ) {
            my $want = $fnd[int(rand(scalar(@fnd)))];
            ++$i until $anons[$i] eq $want;
        }
    }
    $i = int(rand(scalar(@anons))) if !$i;
    my $anon =  $anons[$i];
    splice(@anons, $i, 1);

    $anon =~ s/\/b\//$channel/g if $channel;

    $server->command("/MSG $channel $anon");

}

Irssi::command_bind('4ch', 'getone');
