HexChat Text-To-Speech add-on
=============================

Provides Text-To-Speech functionality to HexChat using ­­­­`festival` or `espeak` (with or without `mbrola`). Based on [XChat TTS Script v0.1](http://xchatttsscript.sourceforge.net/).

#### Requirements

##### Using festival
For best results, install `festival` and a voice package like `festvox-kallpc16k` for `english` or `festvox-rablpc16k` for `british_english`:
```
sudo apt-get install festival festvox-rablpc16k
```

##### Using mbrola
If you want to use `mbrola` instead:
```
sudo apt-get install mbrola
```
[Download a voice package](http://www.tcts.fpms.ac.be/synthesis/mbrola/mbrcopybin.html) and install it in `/usr/share/mbrola/`

#### Installation
Clone this repository to `~/.config/hexchat/addons/tts` (renaming `hexchat-tts` to `tts`):
```
git clone https://github.com/caktux/hexchat-tts.git ~/.config/hexchat/addons/tts
```

Link the `tts.pl` script in the `addons` folder to load it when HexChat launches:
```
ln -s ~/.config/hexchat/addons/tts/tts.pl ~/.config/hexchat/addons/tts.pl
```

#### Usage and options
```
/tts info             Display some generel informations
/tts [on|off]         Turns TTS on/off (default is on)
/tts addchan          listen to the current channel
/tts delchan          stop listening to the current channel
/tts listchans        shows all channels on the listening to list
/tts notify [<nick>]  lists TTS notify list, add/del <nick>
/tts ignore [<nick>]  lists TTS ignore list, add/del <nick>
/tts watch [<nick>]   notifies you when <nick> join/parts a chan
/tts use <engine>     TTS engine ('espeak', 'mbrola' or 'festival')
/tts lang <language>  TTS language (festival->english, mbrola->us1)
/tts say <text>       says the text
```

#### TODO
- Volume control
