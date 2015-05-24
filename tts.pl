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

IRC::register( "HexChat TTS Script", "0.2.0", "", "" );
IRC::print("\002HexChat TTS Script v0.2.0   \017\0033[Loaded]");
IRC::print("type /tts help for instructions");

IRC::add_command_handler( "TTS",     "sub_TTS" );
IRC::add_message_handler( "PRIVMSG", "sub_msg" );
IRC::add_message_handler( "NOTICE",  "sub_msg" );
IRC::add_message_handler( "JOIN",    "sub_watch" );
IRC::add_message_handler( "PART",    "sub_watch" );
IRC::add_message_handler( "600",     "sub_notify" );
IRC::add_message_handler( "601",     "sub_notify" );

# make TTS on by default
my $TTS_on = 1;

# path to the tts script and files, IRC::get_info(4) returns .config/hexchat path in your home-directory
my $ttspath = IRC::get_info(4) . "/addons/tts";
IRC::print("Settings saved in " . $ttspath);

# hash with files
my %listfiles = (
    "TTS Channel list" => "$ttspath/chanlist",
    "TTS Notify list"  => "$ttspath/notifylist",
    "TTS Ignore list"  => "$ttspath/ignorelist",
    "TTS Watch list"   => "$ttspath/watchlist",
    "TTS Engine"       => "$ttspath/engine",
    "TTS Language"     => "$ttspath/language");

# arrays for the lists
my @chanlist;
my @notifylist;
my @ignorelist;
my @watchlist;
my @engine;
my @language;

# hash for the list, only used for loading, saving the lists
my $lists = {
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
        @{ $lists->{$list} } and IRC::print("$list loaded\n");
    }
}
close FH;

# check if there is a # infront or add it
my $i;
for ( $i = 0 ; $i < @chanlist ; $i++ ) {
    $chanlist[$i] = chansharp( $chanlist[$i] );
}

sub sub_TTS() {
    my $argsline = shift;
    $argsline =~ s/\s+/ /g;
    my @args = split( " ", $argsline );
    my $i    = 0;
    my $j    = 0;

    if ( uc $args[0] eq 'INFO' ) {
        IRC::print("here will be some information - soon(tm) ...");
    }
    elsif ( uc $args[0] eq 'ON' ) {
        $TTS_on = 1;
        IRC::print("TTS switched \0033on");
    }
    elsif ( uc $args[0] eq 'OFF' ) {
        $TTS_on = 0;
        IRC::print("TTS switched \0034off");
    }
    elsif ( uc $args[0] eq 'USE' ) {
        if ( uc $args[1] eq 'ESPEAK' || uc $args[1] eq 'FESTIVAL' || uc $args[1] eq 'MBROLA' ) {
          $engine[0] = uc $args[1];
          savelist("TTS Engine");
          IRC::print("TTS using \0033$args[1]");
        }
        else {
          IRC::print("No engine named \0034$args[1]");
        }
    }
    elsif ( uc $args[0] eq 'LANG' ) {
        $language[0] = $args[1];
        savelist("TTS Language");
        IRC::print("TTS language is \0033$args[1]");
    }
    elsif ( uc $args[0] eq 'ADDCHAN' ) {
        my $mychan = $args[1] || IRC::get_info(2);
        $mychan = chansharp($mychan);
        if ( $mychan ne "" ) {
            for ( $i = 0 ; $i < @chanlist ; $i++ ) {
                if ( uc $mychan eq uc $chanlist[$i] ) {
                    IRC::print("already listening to $mychan\n");
                    last;
                }
            }
            if ( $i == @chanlist ) {
                $chanlist[$i] = $mychan;
                IRC::print("listening to $mychan\n");
                savelist("TTS Channel list");
            }
        }
        else { IRC::print("no channel specified\n"); }
    }
    elsif ( uc $args[0] eq 'DELCHAN' ) {
        my $mychan = $args[1] || IRC::get_info(2);
        $mychan = chansharp($mychan);
        if ( $mychan ne "" ) {
            for ( $i = 0 ; $i < @chanlist ; $i++ ) {
                if ( uc $mychan eq uc $chanlist[$i] ) {
                    splice( @chanlist, $i, 1 );
                    IRC::print("stopped listening to $mychan\n");
                    savelist("TTS Channel list");
                    $i = -1;
                    last;
                }
            }
            if ( $i > -1 ) {
                IRC::print("wasn't listening to $mychan\n");
            }
        }
        else { IRC::print("You are not in a channel\n"); }
    }
    elsif ( uc $args[0] eq 'LISTCHANS' ) {
        IRC::print("\002\026\0038,12 -- TTS Channel list --------------- \n");
        if ( @chanlist > 0 ) {
            for ( $i = 0 ; $i < @chanlist ; $i++ ) {
                IRC::print("  $chanlist[$i]");
            }
            IRC::print( scalar @chanlist . " channels in TTS channel list.\n" );
        }
        else { IRC::print("TTS Channel list is empty.\n"); }
    }
    elsif ( uc $args[0] eq 'NOTIFY' ) {
        if ( $args[1] eq "" ) {
            IRC::print(
                "\002\026\0038,12 -- TTS Notify list --------------- \n");
            if ( @notifylist > 0 ) {
                for ( $i = 0 ; $i < @notifylist ; $i++ ) {
                    IRC::print("  $notifylist[$i]\n");
                }
                IRC::print( scalar @notifylist . " users in TTS Notify list." );
            }
            else { IRC::print("TTS Notify list is empty.\n"); }
        }
        else {
            for ( $i = 0 ; $i < @notifylist ; $i++ ) {
                if ( uc $args[1] eq uc $notifylist[$i] ) {
                    splice( @notifylist, $i, 1 );
                    savelist("TTS Notify list");
                    IRC::command("/notify $args[1]");
                    IRC::print("$args[1] deleted from TTS Notify list.\n");
                    $i = -1;
                    last;
                }
            }
            if ( $i == @notifylist ) {
                $notifylist[$i] = $args[1];
                savelist("TTS Notify list");
                IRC::command("/notify $args[1]");
                IRC::print("$args[1] added to TTS Notify list.\n");
            }
        }
    }
    elsif ( uc $args[0] eq 'IGNORE' ) {
        if ( $args[1] eq "" ) {
            IRC::print(
                "\002\026\0038,12 -- TTS Ignore list --------------- \n");
            if ( @ignorelist > 0 ) {
                for ( $i = 0 ; $i < @ignorelist ; $i++ ) {
                    IRC::print("  $ignorelist[$i]\n");
                }
                IRC::print( scalar @ignorelist . " users in TTS Ignore list." );
            }
            else { IRC::print("TTS Ignore list is empty.\n"); }
        }
        else {
            for ( $i = 0 ; $i < @ignorelist ; $i++ ) {
                if ( uc $args[1] eq uc $ignorelist[$i] ) {
                    splice( @ignorelist, $i, 1 );
                    savelist("TTS Ignore list");
                    IRC::print("$args[1] deleted from TTS Ignore list.\n");
                    $i = -1;
                    last;
                }
            }
            if ( $i == @ignorelist ) {
                $ignorelist[$i] = $args[1];
                savelist("TTS Ignore list");
                IRC::print("$args[1] added to TTS Ignore list.\n");
            }
        }
    }
    elsif ( uc $args[0] eq 'WATCH' ) {
        if ( $args[1] eq "" ) {
            IRC::print("\002\026\0038,12 -- TTS Watch list --------------- \n");
            if ( @watchlist > 0 ) {
                for ( $i = 0 ; $i < @watchlist ; $i++ ) {
                    IRC::print("  $watchlist[$i]\n");
                }
                IRC::print( scalar @watchlist . " users in TTS Watch list." );
            }
            else { IRC::print("TTS Watch list is empty.\n"); }
        }
        else {
            for ( $i = 0 ; $i < @watchlist ; $i++ ) {
                if ( uc $args[1] eq uc $watchlist[$i] ) {
                    splice( @watchlist, $i, 1 );
                    savelist("TTS Watch list");
                    IRC::print("$args[1] deleted from TTS Watch list.\n");
                    $i = -1;
                    last;
                }
            }
            if ( $i == @watchlist ) {
                $watchlist[$i] = $args[1];
                savelist("TTS Watch list");
                IRC::print("$args[1] added to TTS Watch list.\n");
            }
        }
    }
    elsif ( uc $args[0] eq 'SAY' ) {
        if ( $args[1] eq "" ) {
            IRC::print("say what?");
        }
        else {
            if ($TTS_on) {
                shift @args;
                my $saystring = join( " ", @args );
                sub_say("$saystring");
            }
            else { IRC::print("TTS is \0034off\017, switch it on first"); }
        }
    }

    #   elsif (uc $args[0] eq 'SET') {
    #     if ($args[1] ne "") {
    #        IRC::print("not implemented yet");
    #      }
    #      else {IRC::print("set what?");}
    #   }
    elsif ( uc $args[0] eq 'HELP' ) {
        IRC::print("\n\026  HexChat TTS Script v0.2.0                - help -                        \n");
        IRC::print("\026  \017 /tts info             Display some generel informations               \026  \n");
        IRC::print("\026  \017 /tts [on|off]         Turns TTS on/off (default is on)                \026  \n");
        IRC::print("\026  \017 /tts addchan          listen to the current channel                   \026  \n");
        IRC::print("\026  \017 /tts delchan          stop listening to the current channel           \026  \n");
        IRC::print("\026  \017 /tts listchans        shows all channels on the listening to list    \026  \n");
        IRC::print("\026  \017 /tts notify [<nick>]  lists TTS notify list, add/del <nick>           \026  \n");
        IRC::print("\026  \017 /tts ignore [<nick>]  lists TTS ignore list, add/del <nick>           \026  \n");
        IRC::print("\026  \017 /tts watch [<nick>]   notifies you when <nick> join/parts a chan      \026  \n");
        IRC::print("\026  \017 /tts use <engine>     TTS engine ('espeak', 'mbrola' or 'festival')   \026  \n");
        IRC::print("\026  \017 /tts lang <language>  TTS language (festival->english, mbrola->us1)   \026  \n");
        IRC::print("\026  \017 /tts say <text>       says the text                                   \026  \n");
        IRC::print("\026                                                                           \n\n");
    }
    elsif ( uc $args[0] eq '' ) {
        my $status;
        if   ($TTS_on) { $status = "\0033on" }
        else           { $status = "\0034off" }
        IRC::print("TTS is $status");
    }
    else { IRC::print("\0034UNKNOWN command\ntype /tts help"); }
    return 1;
}

sub sub_msg {
    if ($TTS_on) {
        my $mynick  = IRC::get_info(1);
        my $mychan  = IRC::get_info(2);
        my $rawline = shift;
        my $i       = 0;
        my $presaystring;
        my $saystring;
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
                if ( uc $nick eq uc $ignorelist[$i] ) { return 1; }
            }

            if ( uc $msgto eq uc $mynick ) {
                $saystring = "$nick says: $msgtxt";
            }
            elsif ( $msgtxt =~ /\b$mynick\b/i ) {
                if ( $msgtxt =~ /^ACTION / ) {
                    $msgtxt =~ s/ACTION //;
                    ##
                    ## if joint channels > 1 "in $msgto: $nick $msgtxt" else "$nick $msgtxt"
                    ## schaun ob IRC::get_info(2) alle chans oder nur aktuellen liefert
                    ##
                    $saystring = "in $msgto: $nick $msgtxt";
                }
                else { $saystring = "$nick says in $msgto: $msgtxt"; }
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
            sub_say("$saystring");
        }
    }
}

sub sub_notify {
    if ($TTS_on) {
        my $mynick  = IRC::get_info(1);
        my $mychan  = IRC::get_info(2);
        my $rawline = shift;

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
}

sub sub_watch {
    if ($TTS_on) {

        my $rawline = shift;
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
}

sub sub_say {
    $_[0] =~ s/\'//g;
    my $engine = @engine[0];
    my $language = @language[0];
    if ( $engine eq 'FESTIVAL' ) {
      if ($language eq "") {
        $language = 'english';
      }
      system("echo '$_[0]' | festival --tts --language $language &");
    }
    elsif ( $engine eq 'MBROLA' ) {
      if ($language eq "") {
        $language = 'us1';
      }
      system("espeak -v mb/mb-$language -s 150 -p 40 '$_[0]' | mbrola /usr/share/mbrola/$language/$language - -.au | aplay &");
    }
    else {
      system("espeak -s 150 -p 40 '$_[0]' &");
    }
}

sub savelist {
    my $file = $listfiles{ $_[0] };
    if ( open FH, "> $file" ) {
        print FH join( "\n", @{ $lists->{ $_[0] } } );
        close FH;
    }
    else {
        IRC::print("Error saving $file: $!");
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
