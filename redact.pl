# Replaces /ignore with easily cracked encryption.
#
# Their stuff still gets logged, but you don't have to see it unless you want
# to, in which case, in most terminals, you can select the text with your
# mouse.
#
# should still treat QUIT/JOIN/PART type /ignores normally

use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = "0.2";
%IRSSI = (
    authors     => "rupa",
    name        => "redact",
    description => "redact the words of those tiresome or officious.",
    license     => "BSD",
);

Irssi::theme_register(['redact', "{msgnick \$0}" . "\0031,1" . "\$1"]);

sub redact_ignored {
    my ($server, $data, $nick, $mask, $target) = @_;
    if( $server->ignore_check($nick, $mask, $target, $data, MSGLEVEL_PUBLIC) ) {
        # strip colors and formatting
        #$data = Irssi::strip_codes($data);
        $data =~ s/\x03\d?\d?(,\d?\d?)?|\x02|\x1f|\x16|\x06|\x07//g;
        $server->printformat($target, MSGLEVEL_PUBLIC, "redact", $nick, $data);
    }
}

Irssi::signal_add_first("message public", "redact_ignored");
Irssi::signal_add_first("message private", "redact_ignored");
Irssi::signal_add_first("ctcp action", "redact_ignored");
