# Redact the seditious statements of your chosen list of nicks with easily
# cracked encryption.
#
# /set redact_nicks nick1 ... nickn
#
# Their stuff still gets logged,
# but you don't have to see them unless you want to,
# in which case you can select the text with yr mouse.

use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = "0.1";
%IRSSI = (
    authors     => "rupa",
    name        => "redact",
    description => "redact the words of those tiresome or officious.",
    license     => "BSD",
);

sub redact_by_nick {
    my ($server, $data, $nick, $mask, $target) = @_;
    if( grep(/^$nick$/, split(' ', Irssi::settings_get_str('redact_nicks'))) ) {

        # black on black
        $data = "\0031,1" . $data;

    }
    Irssi::signal_continue($server, $data, $nick, $mask, $target);
}

Irssi::signal_add('message public', 'redact_by_nick');
Irssi::signal_add('message irc action', 'redact_by_nick');

Irssi::settings_add_str('ministryoftruth', 'redact_nicks', 'redubious');
