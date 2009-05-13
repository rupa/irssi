#!/usr/bin/perl
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = "0.0.1";
%IRSSI = (
    authors     => "",
    contact     => "",
    name        => "",
    description => "random",
    license     => "GPLv2",
    url         => "",
    changed     => "",
    modules     => "",
);

print CLIENTCRAP "random.pl $VERSION loaded.";
print CLIENTCRAP "/random";

sub randomnick {
    my ($server, $channel, $spareme, $spareops) = @_;
    my @nicks;
    for my $nick ($channel->nicks() ) {
        next if $spareops && $nick->{op};
        next if $spareme && ($nick->{nick} eq $server->{nick});
        push @nicks, $nick;
    }
    return $nicks[rand(scalar(@nicks))]->{nick};
}

sub random {
    my ($msg, $server, $chan) = @_;
    return if not $chan;

    my $victim = randomnick($server, $chan, 0, 0);
    return if not $chan->{chanop};

    $server->command("/MSG ".$chan->{name}." ".$victim." ".$msg);
}

Irssi::command_bind("random", "random", "random");
