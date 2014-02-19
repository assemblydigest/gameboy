The *Game Boy* and *Game Boy Color* were very cool handhelds with lots of nifty games. Maybe at one point you've wondered "hmm, what was programming for the Game Boy like?" or you've wanted to make your own. Assembly is confusing and messy, but it's entirely possible to learn.

I plan to write a bunch of tutorials from the ground up, explaining how to use the Game Boy hardware to do different techniques. Before that, I should explain the bare minimum to get a ROM that "works", even if it does nothing yet.

If you don't understand everything here, don't worry, you don't have to right now. A lot of this can be copy-pasted verbatim and changed later, but I've taken time to break it down and explain different pieces.

This tutorial uses a high-level assembly language named [Wiz](http://github.com/Bananttack/wiz), which is included with the download link at the bottom. Since it is a relatively new tool and still in development, I plan to cover another tutorial explaining the same stuff, but for the [RGBDS](http://anthony.bentley.name/rgbds/) assembler.

### **Layout**

First thing to do is to tell the assembler how its different memory banks are laid out. Make a text file, name it **game.wiz** (or game.txt or whatever you want really), then open it and put the following:

<pre><code>let K = 1024<br/>bank rom: rom * 16 * K<br/>bank rom2: rom * 16 * K<br/>bank ram: ram * 4 * K<br/>bank ram2: ram * 4 * K<br/>bank hram: ram * 127<br/></code></pre>

It will need to be changed more later, but the above settings are a good placeholder for a simple original Game Boy ROM with no special hardware.

A few things:

&#9670; *rom* and *rom2* is the **Read Only Memory** on the cartridge that holds the program code and data. They're split into 16 KB banks.

Memory Bank Controller hardware allows cartridges to have more than 16K banks of ROM, by using a technique called **Bank Switching**. This technique allows selecting what bank of memory gets shown at `0x4000` .. `0x7FFF`, but it won't be used yet.

&#9670; *ram* and *ram2* is **Random Access Memory** used to read and write information that the code uses while it runs.

The Game Boy has 2 banks of 4 KB RAM. The Game Boy Color expands this and gives you 8 banks to work with, and you can bank-switch which 4K bank can be used at `0xD000` .. `0xDFFF`.

&#9670; *hram* is a another chunk of systen RAM on the Game Boy, which is 127 bytes. It stands for **High RAM**, because it occupies `0xFF80` .. `0xFFFE` - which is the "high" part of the Game Boy's 16-bit address space.

<br />

Some cartridges will have their own RAM on the cartridge, which can be used for a variety of things. It is sometimes possibly battery-backed to create save files.

These are really simple declarations so the assembler knows a bit about where to locate different pieces of code, data, and runtime variables in the ROM.

&#9670; This explains the Memory Map of the Game Boy in more detail: http://nocash.emubase.de/pandocs.htm#memorymap

### **Boot Header**

Now that the assembler knows enough information, there is also the matter of giving some information to the Game Boy. The Game Boy will only run cartridges that pass the boot verification, and everything else will lock on the startup screen. To pass the boot procedure, there needs to be a **Boot Header** that adheres to a Game Boy format. The header also has enough information about the hardware the catridge uses, which can be used by emulators.

You can skim this and change the headers later.

The first section in the header is pretty boring, but can be used to store really small subroutines aligned to 8-byte boundaries, called **RST Handlers**. (There's a series of optimized instructions called *rst* (short for restart) which take less CPU cycles and use less bytes in the ROM to call.)

<pre><code>// RST handlers.<br/>in rom, 0x0000:<br/>    return<br/>in rom, 0x0008:<br/>    return<br/>in rom, 0x0010:<br/>    return<br/>in rom, 0x0018:<br/>    return<br/>in rom, 0x0020:<br/>    return<br/>in rom, 0x0028:<br/>    return<br/>in rom, 0x0030:<br/>    return<br/>in rom, 0x0038:<br/>    return<br/></code></pre>

The next section is a series of **Interrupt Handlers**, for responding to different events that can be triggered by the Game Boy hardware. These are also aligned to 8-byte boundaries.

<pre><code>// Interrupt handlers.<br/>in rom, 0x0040:<br/>    goto! draw<br/>in rom, 0x0048:<br/>    goto! stat<br/>in rom, 0x0050:<br/>    goto! timer<br/>in rom, 0x0058:<br/>    goto! serial<br/>in rom, 0x0060:<br/>    goto! joypad<br/></code></pre>

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

Following that, there is an area that is 4 bytes in length that can hold code for the **Startup Routine**, which is executed directly after the cartridge passes the boot check.

<pre><code>// Startup handler.<br/>in rom, 0x0100:<br/>    nop<br/>    goto! main<br/></code></pre>

Since this is tiny, pretty much all that fits is an instruction to jump somewhere else in the ROM.

Next, there is some binary data that defines the **Nintendo logo**. This data on the cartridge must match the exact logo in Game Boy's internal boot ROM, or the Game Boy boot procedure will lock up after the logo is displayed.

<pre><code>// The Nintendo Logo.<br/>in rom, 0x0104:<br/>    byte * 48:<br/>        0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B,<br/>        0x03, 0x73, 0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D,<br/>        0x00, 0x08, 0x11, 0x1F, 0x88, 0x89, 0x00, 0x0E,<br/>        0xDC, 0xCC, 0x6E, 0xE6, 0xDD, 0xDD, 0xD9, 0x99,<br/>        0xBB, 0xBB, 0x67, 0x63, 0x6E, 0x0E, 0xEC, 0xCC,<br/>        0xDD, 0xDC, 0x99, 0x9F, 0xBB, 0xB9, 0x33, 0x3E<br/></code></pre>

Then there's the **Title** for the ROM, which is 11 characters in all caps. Any unusued bytes should be filled with 0. (Wiz will do this by repeating the last byte of "`byte * N: ...`" statement to pad the data.)

<pre><code>// The title, in upper-case letters, followed by zeroes.<br/>in rom, 0x0134:<br/>    byte * 11: "TEST", 0<br/></code></pre>

The **Manufacturer Code** is an uppercase 4 letter-string, but on older titles it's used for more letters in the game title. Lots of emulators will display this as part of the title, which is undesirable, so here it's just filled with `0` values.

<pre><code>// The manufacturer code.    <br/>in rom, 0x013F:<br/>    byte * 4: 0<br/></code></pre>

The **GBC Compatibility Flag** decides whether the ROM is compatible with both the Game Boy Color and the original Game Boy, or if it was a GBC-exclusive. Monochrome games use it as another uppercase letter in the title. Saying the ROM is exclusive doesn't actually prevent the ROM from starting if it is run on an original Game Boy, but both compatible/exclusive settings have the effect of enabling extra features on the Game Boy Color.

<pre><code>// Gameboy Color compatibility flag.    <br/>in rom, 0x0143:<br/>    let GBC_UNSUPPORTED = 0x00<br/>    let GBC_COMPATIBLE = 0x80<br/>    let GBC_EXCLUSIVE = 0xC0<br/>    byte * 1: GBC_UNSUPPORTED<br/></code></pre>

The **Licensee Code** is a two-character name in upper case. Which was used to indicate who developed/published the cartridge.

<pre><code>// "New" Licensee Code, a two character name.    <br/>in rom, 0x0144:<br/>    byte * 2: "OK"<br/></code></pre>

The **Super Game Boy** compatibility flag indicates whether this ROM has extra features on the Super Game Boy. If set, then a ROM can utilize the Super Game Boy transfer transfer protocol to add things like border images, custom palettes, screen recoloring, sprites, sound effects, and sometimes even data that can be sent to SNES RAM and run on the SNES (both 65816 and SPC programs).

<pre><code>// Super Gameboy compatibility flag.<br/>in rom, 0x0146:<br/>    let SGB_UNSUPPORTED = 0x00<br/>    let SGB_SUPPORTED = 0x03<br/>    byte * 1: SGB_UNSUPPORTED<br/></code></pre>

The **Cartridge Type** determines what Memory Bank Controller the cartridge has, as well other additional hardware that the Game Boy can use: rumble, extra RAM, battery-backed saves, a real-time clock, etc. Some carts are pretty unique, like Tamagotchi and Game Boy Camera.

<pre><code>// Cartridge type. Either no ROM or MBC5 is recommended.<br/>in rom, 0x0147:<br/>    let CART_ROM_ONLY = 0x00<br/>    let CART_MBC1 = 0x01<br/>    let CART_MBC1_RAM = 0x02<br/>    let CART_MBC1_RAM_BATTERY = 0x03<br/>    let CART_MBC2 = 0x05<br/>    let CART_MBC2_BATTERY = 0x06<br/>    let CART_ROM_RAM = 0x08<br/>    let CART_ROM_RAM_BATTERY = 0x09<br/>    let CART_MMM01 = 0x0B<br/>    let CART_MMM01_RAM = 0x0C<br/>    let CART_MMM01_RAM_BATTERY = 0x0D<br/>    let CART_MBC3_TIMER_BATTERY = 0x0F<br/>    let CART_MBC3_TIMER_RAM_BATTERY = 0x10<br/>    let CART_MBC3 = 0x11<br/>    let CART_MBC3_RAM = 0x12<br/>    let CART_MBC3_RAM_BATTERY = 0x13<br/>    let CART_MBC4 = 0x15<br/>    let CART_MBC4_RAM = 0x16<br/>    let CART_MBC4_RAM_BATTERY = 0x17<br/>    let CART_MBC5 = 0x19<br/>    let CART_MBC5_RAM = 0x1A<br/>    let CART_MBC5_RAM_BATTERY = 0x1B<br/>    let CART_MBC5_RUMBLE = 0x1C<br/>    let CART_MBC5_RUMBLE_RAM = 0x1D<br/>    let CART_MBC5_RUMBLE_RAM_BATTERY = 0x1E<br/>    let CART_POCKET_CAMERA = 0xFC<br/>    let CART_BANDAI_TAMA5 = 0xFD<br/>    let CART_HUC3 = 0xFE<br/>    let CART_HUC1_RAM_BATTERY = 0xFF<br/>    byte * 1: CART_ROM_ONLY<br/></code></pre>

The **ROM Size** determines how much read-only memory is available on the cartridge. The simplest has two 16 KB banks, and each setting is some multiple of 32 KB.

<pre><code>// Rom size.<br/>in rom, 0x0148:<br/>    let ROM_32K = 0x00<br/>    let ROM_64K = 0x01<br/>    let ROM_128K = 0x02<br/>    let ROM_256K = 0x03<br/>    let ROM_512K = 0x04<br/>    let ROM_1024K = 0x05<br/>    let ROM_2048K = 0x06<br/>    let ROM_4096K = 0x07<br/>    let ROM_1152K = 0x52<br/>    let ROM_1280K = 0x53<br/>    let ROM_1536K = 0x54<br/>    byte * 1: ROM_32K<br/></code></pre>

The **RAM Size** indicates how much random-access memory is on the cartridge. This is additional RAM on top of the RAM that GB / GBC provides, and it might be battery-backed to persist data as saves and so on. Apparently for the MBC2, you need to say it has "no RAM" even though the MBC2 actually does have its own RAM memory.

<pre><code>// Ram sizes.<br/>in rom, 0x0149:<br/>    let RAM_NONE = 0x00<br/>    let RAM_2K = 0x01<br/>    let RAM_8K = 0x02<br/>    let RAM_32K = 0x03<br/>    byte * 1: RAM_NONE<br/></code></pre>

Then finally some other stuff, that doesn't really need to be explained too much. The data located for the **Header Checksum** and **Global Checksum** is calculated by the assembler or an external patching tool, because it's too tedious to calculate by hand. Wiz does this as one of the final steps when writing a GB ROM. The Header Checksum needs to be correct or the cartridge won't pass the boot check

<pre><code>/// Destination code.<br/>in rom, 0x014A:<br/>    let DEST_JAPAN = 0x00<br/>    let DEST_INTERNATIONAL = 0x01<br/>    byte * 1: DEST_INTERNATIONAL<br/>// Old licensee code.<br/>// 0x33 indicates new license code will be used.<br/>// 0x33 must be used for SGB games.<br/>in rom, 0x014B: byte * 1: 0x33<br/>// ROM version number<br/>in rom, 0x014C: byte * 1: 0x00<br/>// Header checksum.<br/>// Assembler needs to patch this.<br/>in rom, 0x014D: byte * 1: 0xFF<br/>// Global checksum.<br/>// Assembler needs to patch this.<br/>in rom, 0x014E: word * 1: 0xFACE</code></pre>

Whew, and we're done!

For more information, there are some resources:

&#9670; The Cartridge Header: http://nocash.emubase.de/pandocs.htm#thecartridgeheader

&#9670; Reverse engineering the Game Boy's internal boot code: http://gbdev.gg8.se/wiki/articles/Gameboy_Bootstrap_ROM

### **Loose Ends**

After the boot header, there needs to a little bit more going on, so the program can actually compile.

<pre><code>in rom, 0x0150:<br/>    func main do<br/>        loop<br/>            sleep<br/>        end<br/>    end<br/><br/>    task nothing do<br/>    end<br/><br/>    let draw = nothing<br/>    let stat = nothing<br/>    let timer = nothing<br/>    let serial = nothing<br/>    let joypad = nothing</code></pre>

This creates a *main* function that just loops forever, sleeping periodically to use minimal battery life. This will also use placeholder interrupt handlers that do nothing, for now.

### **Putting it All Together**

Finally, you need to run `wiz` to build the project: (change "game.wiz" for whatever name you give your input file, and "game.gb" for whatever name you want the ROM file to have)

<pre><code>wiz game.wiz -gb -o game.gb</code></pre>

It should spit out text similar to this:

<pre><code>* wiz: version 0.1<br />>> Building...<br />>> Writing ROM...<br />>> Wrote to 'game.gb'.<br />* wiz: Done.<br /></code></pre>

And there you go! If all went well, you should see **game.gb**, your very own Game Boy ROM. It does nothing useful yet, but it's now an empty template which boots up and can be used to make a game.

&#9670; You can [download the code and assembler here](http://make.vg/get/assemblydigest/part-1-make-a-gb-rom.zip).

&#9670; You can also [view the code and this tutorial on Github](https://github.com/assemblydigest/gameboy/tree/master/part-1-make-a-gb-rom/wiz)!

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