The *Game Boy* and *Game Boy Color* were very cool handhelds with lots of nifty games. Maybe at one point you've wondered "hmm, what was programming for the Game Boy like?" or you've wanted to make your own. Assembly is confusing and messy, but it's entirely possible to learn.

I plan to write a bunch of tutorials from the ground up, explaining how to use the Game Boy hardware to do different techniques. Before that, I should explain the bare minimum to get a ROM that "works", even if it does nothing yet.

If you don't understand everything here, don't worry, you don't have to right now. A lot of this can be copy-pasted verbatim and changed later, but I've taken time to break it down and explain different pieces.

This tutorial uses Z80 assembly and an assembler named [RGBDS](http://anthony.bentley.name/rgbds/), which is included with the download link at the bottom. 

### **Layout**

First thing to do is to tell the assembler where to put the code. Make a text file, name it **game.z80** (or game.txt or whatever you want really), then open it and put the following:

<pre><code>SECTION "rom", HOME<br/></code></pre>

&#9670; This defines a section named *rom* located in the **HOME** bank (ROM bank 0).

&#9670; RGBDS sections are kind of ugly, but you can read a bit about them here: http://otakunozoku.com/RGBDSdocs/asm/section.htm

### **Boot Header**

Now that the assembler knows enough information, there is also the matter of giving some information to the Game Boy. The Game Boy will only run cartridges that pass the boot verification, and everything else will lock on the startup screen. To pass the boot procedure, there needs to be a **Boot Header** that adheres to a Game Boy format. The header also has enough information about the hardware the catridge uses, which can be used by emulators.

You can skim this and change the headers later.

The first section in the header is pretty boring, but can be used to store really small subroutines aligned to 8-byte boundaries, called **RST Handlers**. (There's a series of optimized instructions called *rst* (short for restart) which take less CPU cycles and use less bytes in the ROM to call.)

<pre><code>; $0000 - $003F: RST handlers.<br/>ret<br/>REPT 7<br/>    nop<br/>ENDR<br/>; $0008<br/>ret<br/>REPT 7<br/>    nop<br/>ENDR<br/>; $0010<br/>ret<br/>REPT 7<br/>    nop<br/>ENDR<br/>; $0018<br/>ret<br/>REPT 7<br/>    nop<br/>ENDR<br/>; $0020<br/>ret<br/>REPT 7<br/>    nop<br/>ENDR<br/>; $0028<br/>ret<br/>REPT 7<br/>    nop<br/>ENDR<br/>; $0030<br/>ret<br/>REPT 7<br/>    nop<br/>ENDR<br/>; $0038<br/>ret<br/>REPT 7<br/>    nop<br/>ENDR</code></pre>

RGBDS requires you to pad areas manually, it has no "org" directive to skip ahead in the ROM, and you can't use the same SECTION with different addresses twice. So you need use the **REPT** (repeat) macro or **DS** (define storage) directive to pad bytes manually.

The next section is a series of **Interrupt Handlers**, for responding to different events that can be triggered by the Game Boy hardware. These are also aligned to 8-byte boundaries.

<pre><code>; $0040 - $0067: Interrupt handlers.<br/>jp draw<br/>REPT 5<br/>    nop<br/>ENDR<br/>; $0048<br/>jp stat<br/>REPT 5<br/>    nop<br/>ENDR<br/>; $0050<br/>jp timer<br/>REPT 5<br/>    nop<br/>ENDR<br/>; $0058<br/>jp serial<br/>REPT 5<br/>    nop<br/>ENDR<br/>; $0060<br/>jp joypad<br/>REPT 5<br/>    nop<br/>ENDR</code></pre>

There are few different interrupts:

&#9670; *draw* is a **Vertical Blank** ("v-blank") handler. It happens once every frame when the LCD screen has drawn the final scanline. During this short time it's safe to mess with the video hardware and there won't be interference.<br/>
&#9670; *stat* is a **Status Interrupt** handler. It is fired when certain conditions are met in the LCD Status register. Writing to the LCD Status Register, it's possible to configure which events trigger the Status interrupt. One use is to trigger **Horizontal Blank** ("h-blank") interrupts, which occur when there's a very small window of time between scanlines of the screen, to make a really tiny change to the video memory.<br/>
&#9670; *timer* is a **Timer Interrupt** handler. It is fired when the Game Boy's 8-bit timer wraps around from `255` to `0`. The timer's update frequency is customizable.<br/>
&#9670; *serial* is a **Serial Interrupt** handler. It is triggered when the a serial link cable transfer has completed sending/receiving a byte of data.<br/>
&#9670; *joypad* is a **Joypad Interrupt** handler. Its primary purpose is to break the Game Boy from its low-power standby state, and isn't terribly useful for much else.<br/>
&#9670; The Interrupt Flag register can be used to determine which interrupt has happened.<br/>
&#9670; The Interrupt Enable register configures what events will triggered interrupts.<br/>

<br/>

Then there is a small area with some free space which you can use for whatever you want, which is 152 bytes long. We ignore this for now.

<pre><code>; $0068 - $00FF: Free space.<br/>DS $98</code></pre>

Following that, there is an area that is 4 bytes in length that can hold code for the **Startup Routine**, which is executed directly after the cartridge passes the boot check.

<pre><code>; $0100 - $0103: Startup handler.<br/>nop<br/>jp main<br/></code></pre>

Since this is tiny, pretty much all that fits is an instruction to jump somewhere else in the ROM.

Next, there is some binary data that defines the **Nintendo logo**. This data on the cartridge must match the exact logo in Game Boy's internal boot ROM, or the Game Boy boot procedure will lock up after the logo is displayed.

<pre><code>; $0104 - $0133: The Nintendo Logo.<br/>DB $CE, $ED, $66, $66, $CC, $0D, $00, $0B<br/>DB $03, $73, $00, $83, $00, $0C, $00, $0D<br/>DB $00, $08, $11, $1F, $88, $89, $00, $0E<br/>DB $DC, $CC, $6E, $E6, $DD, $DD, $D9, $99<br/>DB $BB, $BB, $67, $63, $6E, $0E, $EC, $CC<br/>DB $DD, $DC, $99, $9F, $BB, $B9, $33, $3E<br/></code></pre>

Then there's the **Title** for the ROM, which is 11 characters in all caps. Any unusued bytes should be filled with 0, which we do with the DS directive.

<pre><code>; $0134 - $013E: The title, in upper-case letters, followed by zeroes.<br/>DB "TEST"<br/>DS 7 ; padding<br/></code></pre>

The **Manufacturer Code** is an uppercase 4 letter-string, but on older titles it's used for more letters in the game title. Lots of emulators will display this as part of the title, which is undesirable, so here it's just filled with `0` values.

<pre><code>; $013F - $0142: The manufacturer code.<br/>DS 4<br/></code></pre>

The **GBC Compatibility Flag** decides whether the ROM is compatible with both the Game Boy Color and the original Game Boy, or if it was a GBC-exclusive. Monochrome games use it as another uppercase letter in the title. Saying the ROM is exclusive doesn't actually prevent the ROM from starting if it is run on an original Game Boy, but both compatible/exclusive settings have the effect of enabling extra features on the Game Boy Color.

<pre><code>; $0143: Gameboy Color compatibility flag.    <br/>GBC_UNSUPPORTED EQU $00<br/>GBC_COMPATIBLE EQU $80<br/>GBC_EXCLUSIVE EQU $C0<br/>DB GBC_UNSUPPORTED<br/></code></pre>

The **Licensee Code** is a two-character name in upper case. Which was used to indicate who developed/published the cartridge.

<pre><code>; $0144 - $0145: "New" Licensee Code, a two character name.<br/>DB "OK"<br/></code></pre>

The **Super Game Boy** compatibility flag indicates whether this ROM has extra features on the Super Game Boy. If set, then a ROM can utilize the Super Game Boy transfer transfer protocol to add things like border images, custom palettes, screen recoloring, sprites, sound effects, and sometimes even data that can be sent to SNES RAM and run on the SNES (both 65816 and SPC programs).

<pre><code>; $0146: Super Gameboy compatibility flag.<br/>SGB_UNSUPPORTED EQU $00<br/>SGB_SUPPORTED EQU $03<br/>DB SGB_UNSUPPORTED<br/></code></pre>

The **Cartridge Type** determines what Memory Bank Controller the cartridge has, as well other additional hardware that the Game Boy can use: rumble, extra RAM, battery-backed saves, a real-time clock, etc. Some carts are pretty unique, like Tamagotchi and Game Boy Camera.

<pre><code>; $0147: Cartridge type. Either no ROM or MBC5 is recommended.<br/>CART_ROM_ONLY EQU $00<br/>CART_MBC1 EQU $01<br/>CART_MBC1_RAM EQU $02<br/>CART_MBC1_RAM_BATTERY EQU $03<br/>CART_MBC2 EQU $05<br/>CART_MBC2_BATTERY EQU $06<br/>CART_ROM_RAM EQU $08<br/>CART_ROM_RAM_BATTERY EQU $09<br/>CART_MMM01 EQU $0B<br/>CART_MMM01_RAM EQU $0C<br/>CART_MMM01_RAM_BATTERY EQU $0D<br/>CART_MBC3_TIMER_BATTERY EQU $0F<br/>CART_MBC3_TIMER_RAM_BATTERY EQU $10<br/>CART_MBC3 EQU $11<br/>CART_MBC3_RAM EQU $12<br/>CART_MBC3_RAM_BATTERY EQU $13<br/>CART_MBC4 EQU $15<br/>CART_MBC4_RAM EQU $16<br/>CART_MBC4_RAM_BATTERY EQU $17<br/>CART_MBC5 EQU $19<br/>CART_MBC5_RAM EQU $1A<br/>CART_MBC5_RAM_BATTERY EQU $1B<br/>CART_MBC5_RUMBLE EQU $1C<br/>CART_MBC5_RUMBLE_RAM EQU $1D<br/>CART_MBC5_RUMBLE_RAM_BATTERY EQU $1E<br/>CART_POCKET_CAMERA EQU $FC<br/>CART_BANDAI_TAMA5 EQU $FD<br/>CART_HUC3 EQU $FE<br/>CART_HUC1_RAM_BATTERY EQU $FF<br/>DB CART_ROM_ONLY<br/></code></pre>

The **ROM Size** determines how much read-only memory is available on the cartridge. The simplest has two 16 KB banks, and each setting is some multiple of 32 KB.

<pre><code>; $0148: Rom size.<br/>ROM_32K EQU $00<br/>ROM_64K EQU $01<br/>ROM_128K EQU $02<br/>ROM_256K EQU $03<br/>ROM_512K EQU $04<br/>ROM_1024K EQU $05<br/>ROM_2048K EQU $06<br/>ROM_4096K EQU $07<br/>ROM_1152K EQU $52<br/>ROM_1280K EQU $53<br/>ROM_1536K EQU $54<br/>DB ROM_32K<br/></code></pre>

The **RAM Size** indicates how much random-access memory is on the cartridge. This is additional RAM on top of the RAM that GB / GBC provides, and it might be battery-backed to persist data as saves and so on. Apparently for the MBC2, you need to say it has "no RAM" even though the MBC2 actually does have its own RAM memory.

<pre><code>; $0149: Ram size.<br/>RAM_NONE EQU $00<br/>RAM_2K EQU $01<br/>RAM_8K EQU $02<br/>RAM_32K EQU $03<br/>DB RAM_NONE<br/></code></pre>

Then finally some other stuff, that doesn't really need to be explained too much. The data located for the **Header Checksum** and **Global Checksum** is calculated by an external patching tool, because it's too tedious to calculate by hand. The Header Checksum needs to be correct or the cartridge won't pass the boot check. Running **rgbfix** will patch your ROM for you.

<pre><code>; $014A: Destination code.<br/>DEST_JAPAN EQU $00<br/>DEST_INTERNATIONAL EQU $01<br/>DB DEST_INTERNATIONAL<br/>; $014B: Old licensee code.<br/>; $33 indicates new license code will be used.<br/>; $33 must be used for SGB games.<br/>DB $33<br/>; $014C: ROM version number<br/>DB $00<br/>; $014D: Header checksum.<br/>; Assembler needs to patch this.<br/>DB $FF<br/>; $014E- $014F: Global checksum.<br/>; Assembler needs to patch this.<br/>DW $FACE</code></pre>

Whew, and we're done!

For more information, there are some resources:

&#9670; The Cartridge Header: http://nocash.emubase.de/pandocs.htm#thecartridgeheader

&#9670; Reverse engineering the Game Boy's internal boot code: http://gbdev.gg8.se/wiki/articles/Gameboy_Bootstrap_ROM

### **Loose Ends**

After the boot header, there needs to a little bit more going on, so the program can actually compile.

<pre><code>; $0150: Code!<br/>main:<br/>.loop:<br/>    halt<br/>    jr .loop<br/><br/>draw:<br/>stat:<br/>timer:<br/>serial:<br/>joypad:<br/>    reti</code></pre>

This creates a *main* function that just loops forever, sleeping periodically to use minimal battery life. This will also use placeholder interrupt handlers that do nothing, for now.

### **Putting it All Together**

Finally, you need to run a few different RGBDS tools to build the project: 

<pre><code>rgbasm -ogame.obj game.z80<br/>rgblink -mgame.map -ngame.sym -ogame.gb game.obj<br/>rgbfix -p0 -v game.gb<br/></code></pre>

&#9670; "game.z80" is the name of your input file<br/>
&#9670; "game.map", "game.sym" and "game.obj" are build artifacts.<br/>
&#9670; "game.sym" can be used for debugging in BGB.<br/>
&#9670; "game.gb" is the name you want the resulting ROM file to have.<br/>

It should spit out text similar to this:

<pre><code>Output filename game.obj<br/>Assembling game.z80<br/>Pass 1...<br/>Pass 2...<br/>Success! 244 lines in 0.00 seconds (4879999 lines/minute)</code></pre>

And there you go! If all went well, you should see **game.gb**, your very own Game Boy ROM. It does nothing useful yet, but it's now an empty template which boots up and can be used to make a game.

&#9670; You can [download the code and assembler here](http://make.vg/get/assemblydigest/part-1-make-a-gb-rom.zip).

&#9670; You can also [view the code and this tutorial on Github](https://github.com/assemblydigest/gameboy/tree/master/part-1-make-a-gb-rom/rgbds)!

&#9670; This download does not include a Game Boy emulator, but there are plenty available online.

&#9670; I really recommend [BGB](http://bgb.bircd.org/) if you're on Windows, as it is probably the most accurate GB emulator and it contains many developer-friendly features.

&#9670; You can also buy cartrdiges like the [Drag N Derp](http://derpcart.com/) to test on real hardware.

### **Next Steps**

In another part, there will be a tutorial to make a ROM that actually does more than just pass the boot check. Things like:

&#9670; How to make graphics for the Game Boy<br/>
&#9670; Tiles and the Background Layer<br/>
&#9670; The Window Layer<br/>
&#9670; Sprites<br/>
&#9670; Scrolling<br/>
&#9670; Game Boy Color hardware<br/>
&#9670; Scanline Effects<br/>
&#9670; Math<br/>
&#9670; Algorithms<br/>
&#9670; Bank Switching<br/>
&#9670; Neat Programming Tricks<br/>

Expect a new tutorial soon!