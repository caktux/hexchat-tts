#!/usr/bin/perl -w

# HexChat TTS addon v0.2
# Copyright (c) 2003  Kai Hauser
# Copyright (c) 2015  caktux

# This Perlscript is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This Perlscript is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at http://www.gnu.org/licenses/gpl.txt
# for more details.

use strict;

my $version = "0.2.2";

HexChat::register( "HexChat TTS Script", $version, "", "" );
HexChat::print("\002HexChat TTS Script $version   \017\0033[Loaded]");
HexChat::print("type /tts help for instructions");

HexChat::hook_command( "TTS",     "sub_TTS" );
HexChat::hook_server( "PRIVMSG",  "sub_msg" );
HexChat::hook_server( "NOTICE",   "sub_msg" );
HexChat::hook_server( "JOIN",     "sub_watch" );
HexChat::hook_server( "PART",     "sub_watch" );
HexChat::hook_server( "600",      "sub_notify" );
HexChat::hook_server( "601",      "sub_notify" );

# make TTS on by default
my $TTS_on = 1;

# path to the tts script and files
my $ttspath = HexChat::get_info('configdir') . "/addons/tts";
HexChat::print("Settings saved in " . $ttspath);

# hash with files
my %listfiles = (
    "TTS Nick list"    => "$ttspath/nicklist",
    "TTS Channel list" => "$ttspath/chanlist",
    "TTS Notify list"  => "$ttspath/notifylist",
    "TTS Ignore list"  => "$ttspath/ignorelist",
    "TTS Watch list"   => "$ttspath/watchlist",
    "TTS Engine"       => "$ttspath/engine",
    "TTS Language"     => "$ttspath/language");

# arrays for the lists
my @nicklist;
my @chanlist;
my @notifylist;
my @ignorelist;
my @watchlist;
my @engine;
my @language;

# hash for the list, only used for loading, saving the lists
my $lists = {
    "TTS Nick list"    => \@nicklist,
    "TTS Channel list" => \@chanlist,
    "TTS Notify list"  => \@notifylist,
    "TTS Ignore list"  => \@ignorelist,
    "TTS Watch list"   => \@watchlist,
    "TTS Engine"       => \@engine,
    "TTS Language"     => \@language
};

# load the lists
while ( ( my $list, my $file ) = each %listfiles ) {
    if ( open FH, "< $file" ) {
        @{ $lists->{$list} } = <FH>;
        chomp @{ $lists->{$list} };
        @{ $lists->{$list} } and HexChat::print("$list loaded\n");
    }
}
close FH;

# check if there is a # infront or add it
my $i;
for ( $i = 0 ; $i < @chanlist ; $i++ ) {
    $chanlist[$i] = chansharp( $chanlist[$i] );
}

sub sub_TTS() {
    my $argsline = $_[1][1];
    $argsline =~ s/\s+/ /g;
    my @args = split( " ", $argsline );
    my $i    = 0;
    my $j    = 0;

    if ( uc $args[0] eq 'INFO' ) {
        HexChat::print("HexChat Text-To-Speech add-on $version - https://github.com/caktux/hexchat-tts");
    }
    elsif ( uc $args[0] eq 'ON' ) {
        $TTS_on = 1;
        HexChat::print("TTS switched \0033on");
    }
    elsif ( uc $args[0] eq 'OFF' ) {
        $TTS_on = 0;
        HexChat::print("TTS switched \0034off");
    }
    elsif ( uc $args[0] eq 'USE' ) {
        if ( uc $args[1] eq 'ESPEAK' || uc $args[1] eq 'FESTIVAL' || uc $args[1] eq 'MBROLA' ) {
          $engine[0] = uc $args[1];
          savelist("TTS Engine");
          HexChat::print("TTS using \0033$args[1]");
        }
        else {
          HexChat::print("No engine named \0034$args[1]");
        }
    }
    elsif ( uc $args[0] eq 'LANG' ) {
        $language[0] = $args[1];
        savelist("TTS Language");
        HexChat::print("TTS language is \0033$args[1]");
    }
    elsif ( uc $args[0] eq 'ADDNICK' ) {
        my $nick = $args[1];
        my $mychan = HexChat::get_info('channel');
        $mychan = chansharp($mychan);
        if ( $nick ne "" and $mychan ne "" ) {
            for ( $i = 0 ; $i < @nicklist ; $i++ ) {
                my @nickchan = split( " ", $nicklist[$i] );
                if ( uc $nick eq uc $nickchan[0] and uc $mychan eq uc $nickchan[1]) {
                    HexChat::print("already listening to $nick in $mychan\n");
                    last;
                }
            }
            if ( $i == @nicklist ) {
                $nicklist[$i] = $nick . " " . $mychan;
                HexChat::print("listening to $nick in $mychan\n");
                savelist("TTS Nick list");
            }
        }
        else { HexChat::print("no nick/channel specified\n"); }
    }
    elsif ( uc $args[0] eq 'DELNICK' ) {
        my $nick = $args[1];
        my $mychan = HexChat::get_info('channel');
        $mychan = chansharp($mychan);
        if ( $nick ne "" and $mychan ne "" ) {
            for ( $i = 0 ; $i < @nicklist ; $i++ ) {
                my @nickchan = split( " ", $nicklist[$i] );
                if ( uc $nick eq uc $nickchan[0] and uc $mychan eq uc $nickchan[1] ) {
                    splice( @nicklist, $i, 1 );
                    HexChat::print("stopped listening to $nick in $mychan\n");
                    savelist("TTS Nick list");
                    $i = -1;
                    last;
                }
            }
            if ( $i > -1 ) {
                HexChat::print("wasn't listening to $nick in $mychan\n");
            }
        }
        else { HexChat::print("You are not in a channel\n"); }
    }
    elsif ( uc $args[0] eq 'LISTNICKS' ) {
        HexChat::print("\002\026\0038,04 -- TTS Nick list --------------- \n");
        if ( @nicklist > 0 ) {
            for ( $i = 0 ; $i < @nicklist ; $i++ ) {
                HexChat::print("  $nicklist[$i]");
            }
            HexChat::print( scalar @nicklist . " nicks in TTS nick list.\n" );
        }
        else { HexChat::print("TTS Nick list is empty.\n"); }
    }
    elsif ( uc $args[0] eq 'ADDCHAN' ) {
        my $mychan = $args[1] || HexChat::get_info('channel');
        $mychan = chansharp($mychan);
        if ( $mychan ne "" ) {
            for ( $i = 0 ; $i < @chanlist ; $i++ ) {
                if ( uc $mychan eq uc $chanlist[$i] ) {
                    HexChat::print("already listening to $mychan\n");
                    last;
                }
            }
            if ( $i == @chanlist ) {
                $chanlist[$i] = $mychan;
                HexChat::print("listening to $mychan\n");
                savelist("TTS Channel list");
            }
        }
        else { HexChat::print("no channel specified\n"); }
    }
    elsif ( uc $args[0] eq 'DELCHAN' ) {
        my $mychan = $args[1] || HexChat::get_info('channel');
        $mychan = chansharp($mychan);
        if ( $mychan ne "" ) {
            for ( $i = 0 ; $i < @chanlist ; $i++ ) {
                if ( uc $mychan eq uc $chanlist[$i] ) {
                    splice( @chanlist, $i, 1 );
                    HexChat::print("stopped listening to $mychan\n");
                    savelist("TTS Channel list");
                    $i = -1;
                    last;
                }
            }
            if ( $i > -1 ) {
                HexChat::print("wasn't listening to $mychan\n");
            }
        }
        else { HexChat::print("You are not in a channel\n"); }
    }
    elsif ( uc $args[0] eq 'LISTCHANS' ) {
        HexChat::print("\002\026\0038,04 -- TTS Channel list --------------- \n");
        if ( @chanlist > 0 ) {
            for ( $i = 0 ; $i < @chanlist ; $i++ ) {
                HexChat::print("  $chanlist[$i]");
            }
            HexChat::print( scalar @chanlist . " channels in TTS channel list.\n" );
        }
        else { HexChat::print("TTS Channel list is empty.\n"); }
    }
    elsif ( uc $args[0] eq 'NOTIFY' ) {
        if ( $args[1] eq "" ) {
            HexChat::print("\002\026\0038,04 -- TTS Notify list --------------- \n");
            if ( @notifylist > 0 ) {
                for ( $i = 0 ; $i < @notifylist ; $i++ ) {
                    HexChat::print("  $notifylist[$i]\n");
                }
                HexChat::print( scalar @notifylist . " users in TTS Notify list." );
            }
            else { HexChat::print("TTS Notify list is empty.\n"); }
        }
        else {
            for ( $i = 0 ; $i < @notifylist ; $i++ ) {
                if ( uc $args[1] eq uc $notifylist[$i] ) {
                    splice( @notifylist, $i, 1 );
                    savelist("TTS Notify list");
                    HexChat::command("/notify $args[1]");
                    HexChat::print("$args[1] deleted from TTS Notify list.\n");
                    $i = -1;
                    last;
                }
            }
            if ( $i == @notifylist ) {
                $notifylist[$i] = $args[1];
                savelist("TTS Notify list");
                HexChat::command("/notify $args[1]");
                HexChat::print("$args[1] added to TTS Notify list.\n");
            }
        }
    }
    elsif ( uc $args[0] eq 'IGNORE' ) {
        if ( $args[1] eq "" ) {
            HexChat::print("\002\026\0038,04 -- TTS Ignore list --------------- \n");
            if ( @ignorelist > 0 ) {
                for ( $i = 0 ; $i < @ignorelist ; $i++ ) {
                    HexChat::print("  $ignorelist[$i]\n");
                }
                HexChat::print( scalar @ignorelist . " users in TTS Ignore list." );
            }
            else { HexChat::print("TTS Ignore list is empty.\n"); }
        }
        else {
            for ( $i = 0 ; $i < @ignorelist ; $i++ ) {
                if ( uc $args[1] eq uc $ignorelist[$i] ) {
                    splice( @ignorelist, $i, 1 );
                    savelist("TTS Ignore list");
                    HexChat::print("$args[1] deleted from TTS Ignore list.\n");
                    $i = -1;
                    last;
                }
            }
            if ( $i == @ignorelist ) {
                $ignorelist[$i] = $args[1];
                savelist("TTS Ignore list");
                HexChat::print("$args[1] added to TTS Ignore list.\n");
            }
        }
    }
    elsif ( uc $args[0] eq 'WATCH' ) {
        if ( $args[1] eq "" ) {
            HexChat::print("\002\026\0038,04 -- TTS Watch list --------------- \n");
            if ( @watchlist > 0 ) {
                for ( $i = 0 ; $i < @watchlist ; $i++ ) {
                    HexChat::print("  $watchlist[$i]\n");
                }
                HexChat::print( scalar @watchlist . " users in TTS Watch list." );
            }
            else { HexChat::print("TTS Watch list is empty.\n"); }
        }
        else {
            for ( $i = 0 ; $i < @watchlist ; $i++ ) {
                if ( uc $args[1] eq uc $watchlist[$i] ) {
                    splice( @watchlist, $i, 1 );
                    savelist("TTS Watch list");
                    HexChat::print("$args[1] deleted from TTS Watch list.\n");
                    $i = -1;
                    last;
                }
            }
            if ( $i == @watchlist ) {
                $watchlist[$i] = $args[1];
                savelist("TTS Watch list");
                HexChat::print("$args[1] added to TTS Watch list.\n");
            }
        }
    }
    elsif ( uc $args[0] eq 'SAY' ) {
        if ( $args[1] eq "" ) {
            HexChat::print("say what?");
        }
        else {
            if ($TTS_on) {
                shift @args;
                my $saystring = join( " ", @args );
                sub_say("$saystring");
            }
            else { HexChat::print("TTS is \0034off\017, switch it on first"); }
        }
    }

    #   elsif (uc $args[0] eq 'SET') {
    #     if ($args[1] ne "") {
    #        HexChat::print("not implemented yet");
    #      }
    #      else {HexChat::print("set what?");}
    #   }
    elsif ( uc $args[0] eq 'HELP' ) {
        HexChat::print("\n\026  HexChat TTS Script v$version                - help -                        \n");
        HexChat::print("\026  \017 /tts info             Display some generel informations               \026  \n");
        HexChat::print("\026  \017 /tts [on|off]         Turns TTS on/off (default is on)                \026  \n");
        HexChat::print("\026  \017 /tts addchan          listen to the current channel                   \026  \n");
        HexChat::print("\026  \017 /tts delchan          stop listening to the current channel           \026  \n");
        HexChat::print("\026  \017 /tts listchans        shows all channels on the listening to list     \026  \n");
        HexChat::print("\026  \017 /tts addnick <nick>   listen to <nick> in the current channel         \026  \n");
        HexChat::print("\026  \017 /tts delnick <nick>   stop listening to <nick> in the current channel \026  \n");
        HexChat::print("\026  \017 /tts listnicks        shows all nicks/channels on the listening list  \026  \n");
        HexChat::print("\026  \017 /tts notify [<nick>]  lists TTS notify list, add/del <nick>           \026  \n");
        HexChat::print("\026  \017 /tts ignore [<nick>]  lists TTS ignore list, add/del <nick>           \026  \n");
        HexChat::print("\026  \017 /tts watch [<nick>]   notifies you when <nick> join/parts a chan      \026  \n");
        HexChat::print("\026  \017 /tts use <engine>     TTS engine ('espeak', 'mbrola' or 'festival')   \026  \n");
        HexChat::print("\026  \017 /tts lang <language>  TTS language (festival->english, mbrola->us1)   \026  \n");
        HexChat::print("\026  \017 /tts say <text>       says the text                                   \026  \n");
        HexChat::print("\026                                                                           \n\n");
    }
    elsif ( uc $args[0] eq '' ) {
        my $status;
        if   ($TTS_on) { $status = "\0033on" }
        else           { $status = "\0034off" }
        HexChat::print("TTS is $status");
    }
    else { HexChat::print("\0034UNKNOWN command\ntype /tts help"); }

    return HexChat::EAT_ALL;
}

sub sub_msg {
    if ($TTS_on) {
        my $mynick  = HexChat::get_info('nick');
        my $mychan  = HexChat::get_info('channel');
        my $rawline = $_[1][0];
        my $i       = 0;
        my $saystring = "";
        $rawline =~ m/:(.*?)!(.*?)@(.*?) (.*?) (.*?) :(.*)/;

        # $rawline == complete line
        # $1       == Nickname
        # $2       == Ident
        # $3       == Host
        # $4       == MessageType
        # $5       == MsgTo
        # $6       == MsgText

        my $nick   = $1;
        my $msgto  = $5;
        my $msgtxt = $6;

        if ( $nick ne "" ) {
            for ( $i = 0 ; $i < @ignorelist ; $i++ ) {
                if ( uc $nick eq uc $ignorelist[$i] ) { return HexChat::EAT_NONE; }
            }

            if ( uc $msgto eq uc $mynick ) {
                $saystring = "$nick says: $msgtxt";
            }
            elsif ( $msgtxt =~ /\b$mynick\b/i ) {
                if ( $msgtxt =~ /^ACTION / ) {
                    $msgtxt =~ s/ACTION //;
                    ##
                    ## if joint channels > 1 "in $msgto: $nick $msgtxt" else "$nick $msgtxt"
                    ## look if HexChat :: get_info (2) supplies all channels or current
                    ##
                    $saystring = "in $msgto: $nick $msgtxt";
                }
                else { $saystring = "$nick says in $msgto: $msgtxt"; }
            }
            elsif ( @nicklist > 0 ) {
                for ( $i = 0 ; $i < @nicklist ; $i++ ) {
                    my @nickchan = split( " ", $nicklist[$i] );
                    if ( uc $nick eq uc $nickchan[0] and uc $msgto eq uc $nickchan[1] ) {
                        if ( @nicklist > 1 ) {
                            if ( $msgtxt =~ /^ACTION / ) {
                                $msgtxt =~ s/ACTION //;
                                $saystring = "in $msgto: $nick $msgtxt";
                            }
                            else {
                                $saystring = "$nick says in $msgto: $msgtxt";
                            }
                        }
                        else {
                            if ( $msgtxt =~ /^ACTION / ) {
                                $msgtxt =~ s/ACTION //;
                                $saystring = "$nick $msgtxt";
                            }
                            else { $saystring = "$nick says $msgtxt"; }
                        }
                        $i = -1;
                        last;
                    }
                }
            }
            elsif ( @chanlist > 0 ) {
                for ( $i = 0 ; $i < @chanlist ; $i++ ) {
                    if ( uc $msgto eq uc $chanlist[$i] ) {
                        if ( @chanlist > 1 ) {
                            if ( $msgtxt =~ /^ACTION / ) {
                                $msgtxt =~ s/ACTION //;
                                $saystring = "in $msgto: $nick $msgtxt";
                            }
                            else {
                                $saystring = "$nick says in $msgto: $msgtxt";
                            }
                        }
                        else {
                            if ( $msgtxt =~ /^ACTION / ) {
                                $msgtxt =~ s/ACTION //;
                                $saystring = "$nick $msgtxt";
                            }
                            else { $saystring = "$nick says $msgtxt"; }
                        }
                        $i = -1;
                        last;
                    }
                }
            }
            if ( $saystring ne "" ) {
              sub_say("$saystring");
            }
        }
    }

    return HexChat::EAT_NONE;
}

sub sub_notify {
    if ($TTS_on) {
        my $mynick  = HexChat::get_info('nick');
        my $mychan  = HexChat::get_info('channel');
        my $rawline = $_[1][0];

        $rawline =~ m/:(.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*?) :(.*?)/;

        # $rawline == complete line
        # $1       == server
        # $2       == status (login logout)
        # $3       == realname
        # $4       == nick
        # $5       == ident
        # $6       == host
        # $7       == irgendwas
        # $8       == text status

        my $i = 0;
        my $verb;
        if   ( $2 eq "600" ) { $verb = "is online" }
        else                 { $verb = "going offline" }
        for ( $i = 0 ; $i < @notifylist ; $i++ ) {
            if ( uc $4 eq uc $notifylist[$i] ) {
                sub_say("$4 $verb");
                last;
            }
        }
    }

    return HexChat::EAT_NONE;
}

sub sub_watch {
    if ($TTS_on) {

        my $rawline = $_[1][0];
        $rawline =~ /:(.*?)!(.*?)@(.*?) (.*?) (.*)/;

        # $rawline == complete line
        # $1       == Nickname
        # $2      == Ident
        # $3       == Host
        # $4       == MessageType
        # $5       == Channel

        my $i    = 0;
        my $chan = $5;
        $chan =~ s/^\://;
        my $verb;
        if   ( uc $4 eq "JOIN" ) { $verb = "joined" }
        else                     { $verb = "left" }
        for ( $i = 0 ; $i < @watchlist ; $i++ ) {
            if ( uc $1 eq uc $watchlist[$i] ) {
                sub_say("$1 $verb channel: $5");
                last;
            }
        }
    }

    return HexChat::EAT_NONE;
}

sub sub_say {
    $_[0] =~ s/\'//g;
    my $engine = @engine[0];
    my $language = @language[0];
    my $os = $^O;

    if ($os eq 'darwin') {
      system("kill -s 9 `ps -ef | grep say | grep -v grep | awk '{print \$2}'`");
      system("say '$_[0]' &");
    }
    else {
      if ( $engine eq 'FESTIVAL' ) {
        if ($language eq "") {
          $language = 'english';
        }
        system("kill -s 9 `ps -ef | grep festival | grep -v grep | awk '{print \$2}'`");
        system("echo '$_[0]' | festival --tts --language $language &");
      }
      elsif ( $engine eq 'MBROLA' ) {
        if ($language eq "") {
          $language = 'us1';
        }
        system("kill -s 9 `ps -ef | grep aplay | grep -v grep | awk '{print \$2}'`");
        system("espeak -v mb/mb-$language -s 150 -p 40 '$_[0]' | mbrola /usr/share/mbrola/$language/$language - -.au | aplay &");
      }
      else {
        system("kill -s 9 `ps -ef | grep espeak | grep -v grep | awk '{print \$2}'`");
        system("espeak -s 150 -p 40 '$_[0]' &");
      }
    }
}

sub savelist {
    my $file = $listfiles{ $_[0] };
    if ( open FH, "> $file" ) {
        print FH join( "\n", @{ $lists->{ $_[0] } } );
        close FH;
    }
    else {
        HexChat::print("Error saving $file: $!");
    }
}

# adds # to channel
sub chansharp {
    my $chansharp = $_[0];
    if ( $chansharp ne "" ) {
        $chansharp =~ /^#/ or $chansharp = "#" . $chansharp;
    }
    return $chansharp;
}
