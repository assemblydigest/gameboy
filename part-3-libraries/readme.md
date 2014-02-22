Last time I lied, there's a bit more stuff before the tutorial. I thought I'd post some useful library files, because we'll be needing them soon.

&#9670; **Memory Routines**: filling a memory area with a common value, copying data from one memory location to another

&#9670; **Hardware Defines**: useful constants and hardware registers for Game Boy, Game Boy Color, and Super Game Boy hardware.

I'll explain these up a little bit:

### **Memory Routines**

Include this library in the code area of your ROM to get two useful memory routines: filling a memory area with a common value, copying data from one memory location to another.

In Wiz:

<pre><code>include 'memory.wiz'</code></pre>

In RGBDS:

<pre><code>INCLUDE "memory.z80"</code></pre>

Here's the documentation for these functions:

&mdash; **memset** &mdash;<br/>
Fills a range in memory, starting at *hl* and spanning *bc* bytes, with a specified byte value *a*.

**Arguments**<br/>
*hl* = destination address<br />
*bc* = byte count<br />
*a* = value<br />

&mdash; **memcpy** &mdash;<br/>
Copies *bc* bytes from the source at *hl* to the destination at *de*.

**Arguments**<br/>
*de* = destination address<br />
*hl* = source address<br />
*bc* = byte count<br />

<br />

### **Hardware Defines**

Include this library anywhere to get a bunch of useful constants and hardware registers for the Game Boy, Game Boy Color, and Super Game Boy.

In Wiz:

<pre><code>include 'gameboy.wiz'</code></pre>

In RGBDS:

<pre><code>INCLUDE "gameboy.z80"</code></pre>

Please open the file in a text editor to see what constants are defined exactly, but here's a quick list of stuff it has constants for:<br />
&#9670; Boot-header Constants<br />
&#9670; LCD Controller - for configuring basic screen settings.<br />
&#9670; LCD Status - for managing status interrupts and detecting current LCD state.<br />
&#9670; LCD OAM DMA - for copying all sprites' Object Attribute Memory to the screen.<br />
&#9670; RAM areas for tile memory, bg maps, object attribute memory, and wavetable for audio.<br />
&#9670; Background Scroll Registers<br />
&#9670; Scanline State and Interrupt Management<br />
&#9670; Window Positioning<br />
&#9670; GB Monochrome Palette<br />
&#9670; GBC Color Palette<br />
&#9670; GBC Bank Selection (for extra Video RAM and Work RAM banks)<br />
&#9670; GBC Speed Settings<br />
&#9670; GBC Infrared Communication<br />
&#9670; GBC DMA Transfer<br />
&#9670; Super Game Boy Packets<br />
&#9670; Audio Settings<br />
&#9670; Tone, Tone 2, Wave, and Noise<br />
&#9670; Joypad<br />
&#9670; Link Cable<br />
&#9670; Timer<br />
&#9670; Interrupt Configuration<br />

It's recommended that you also read the "Pan Docs" for some relevant information: http://nocash.emubase.de/pandocs.htm -- These roughly correspond to the stuff mentioned in there.

Alternatively there's the GBDev wiki which contains a lot of similar info: http://gbdev.gg8.se/wiki/articles/Main_Page

### **Later!**

If you want to check them out, [you can download these libraries](http://make.vg/get/assemblydigest/part-3-libraries.zip).

You can also [view the source on Github](https://github.com/assemblydigest/gameboy/tree/master/part-3-libraries).

Catch you later!