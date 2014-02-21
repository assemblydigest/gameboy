Last time, there was a tutorial on how to write an empty boilerplate Game Boy ROM. Before any useful progress can happen, we will really want to be able to display things on the Game Boy screen. You could make placeholder patterns in code, or by manually typing hex values, but that's a bit of work. It'd be *way* nicer to just be able to load up some real images!

A big problem with homebrew development is the lack of accessible tools. To help with this effort, I've made a few things available online. You can use them by just opening them in a modern web browser.

Go here to try out "Brew Tool", which is a collection of different tools I've made for homebrew stuff: http://make.vg/brewtool/

Out of all of those, there two tools of interest for making art:

&#9670; [Map Tool](http://make.vg/brewtool/map/index.html) - You tell it to open an image that adheres to the Game Boy Color restrictions, and it spits out a .chr tileset, a Game Boy Color palettes, and the map data for that image.

&#9670; [CHR Tool](http://make.vg/brewtool/chr/index.html) - You tell it to open an image, and it tries its best to convert to a 4-color palette. You can adjust the which palette values it uses for each color being converted, and then you can save the final image as a .chr.

The code is open source and [available to view](https://github.com/Bananattack/brewtool/), so anyone with some JavaScript knowledge can modify and make improvements. You can also make asks here or [submit an issue](https://github.com/Bananattack/brewtool/issues) on GitHub.

Anyway, let's dive into some stuff.

### **Map Tool**

This tool is designed to be pretty simple to use. It will automatically extract tiles and palettes and map data from an image you give it, but it expects images that conform to the Game Boy Color background art limitations:

&#9670; Maximum of 4 colors per 8x8 area.<br/>
&#9670; 256 unique tiles max (doesn't use the GBC's extra tileset memory -- assumes that you might still want your art compatible with the original GB)<br/>
&#9670; 8 unique palettes (of 4 colors) max<br/>

Any image that doesn't follow these requirements is rejected and won't finish loading.

You can give Map Tool an image like this:

![This is a test image.](http://make.vg/images/homebrew/homebrew-test-image.png "This is a test image.")

And it will spit out a tileset, like this:

![This is a tileset.](http://make.vg/images/homebrew/homebrew-test-image.tiles.png "This is a tileset.")

and a palette that looks like this:

![This is a palette.](http://make.vg/images/homebrew/homebrew-test-image.pal.png "This is a palette.")

It does a pretty good job of looking at image, and extracting unique tile patterns and color palettes.

This auto-detection has some weird flaws, and sometimes creates redundant tiles (where the palette is different but pattern is the same) or palettes that may not be the same way an actual person might organize them. Buuuuuut, the important part, is that it extracts enough data from the original image to reassemble it later.

You can save a bunch of junk from here:

**Tileset**

&#9670; The **raw GB tileset (.chr)** can be used to embed the raw art in the ROM in a way the GB and GBC expects.<br />
&#9670; The **tileset image** is just a png of the tileset you see.<br />
&#9670; The **combined tileset image** is a png of all the tiles in the tileset, used against every palette combination.<br />

**Palettes**

&#9670; The **raw 15-bit palette (.pal)** is a binary file containing the 15-bit RGB palette in a way the Game Boy Color understands.<br />
&#9670; The **attibute set** is just an image that contains all the color palettes. Each palette additionally fits in an 8x8 pixel block (which is the size of an attribute tile on the GBC). Might be useful to someone.<br />

**Map**

There are a bunch of different formats for the tile map:
&#9670; The **tile map** is a map using the 8x8 tiles in the tileset to make a background image. It's a CSV text file.<br />
&#9670; The **attribute map** is a secondary map that decides which palettes to use for each tile, for the Game Boy Color. It's a CSV text file.<br />
&#9670; The **combined map** uses the combined tileset image to make te original map, as a CSV text file.<br />
&#9670; The **combined tiled map** uses the combined tileset image to make the original map. This is a .tmx map file, which you can open with [Tiled](http://www.mapeditor.org/). When you're done messing with the map, you can save it back to an image file!<br />
&#9670; **Binary tile map** is the tile map in raw binary format, which you can load on the Game Boy.<br />
&#9670; **Binary attribute map** is the attribute map in raw binary format (which decides which palette gets used where), which you can load on the Game Boy.<br />

There's a lot of options here, but for getting a background we can store in the ROM, these are things we're interested in: raw GB tileset (.chr), raw 15-bit palette (.pal), binary tile map, and binary attribute map. Save your art somewhere handy.

### **CHR Tool**

CHR Tool is a little more manual than Map Tool, you give it an image you want to convert into a tileset. It doesn't create maps for you, and it doesn't detect palettes, or cut out redundant tiles. You can also use this tool to preview a .chr file you've already made.

You give CHR Tool an image with a bunch of tiles, maybe something like this:

![This is a tileset.](http://make.vg/images/homebrew/molasses-tileset.png "This is a tileset.")

You can adjust the palette conversion by hand in case it messed something up by changing the numbers between 0 - 3 in the little boxes. Finally, you'll get something like this:

![This is a tileset.](http://make.vg/images/homebrew/molasses-tileset-after.png "This is a tileset.")

You can save this as a .chr now. This tool is capable of saving Game Boy and NES .chr files, and can also save the color-reduced tileset as a PNG.

### **Wrapping Up**

&#9670; If you don't want to use this there are other tools, such as YY-CHR, and various commandline tools for converting images into files. Or you might consider using a hex editor if you're comfortable with that. I've also written a Python script that converts paletted PNG images into CHR files that requires Python 2.7 and PIL. None of these tools are quite as accessible though, so this is why I made web-based tools.

&#9670; These tools mainly spit out simple, raw, uncompressed binary formats. Depending on how much art your game uses down the road, there may need to be another step to add lossless compression to the data. RLE compression is pretty simple, but probably want something like dictionary compression too. Squish is a silly project I've made to that end: https://github.com/Bananattack/squish

&#9670; Feel free to contribute to make better tools! The homebrew community at large could use them!

Next time, we'll go over how to actually embed some artwork into a Game Boy ROM. 