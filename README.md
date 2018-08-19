# Mr Stash
Mr Stash was a badge I built for DC26 to use for trade of other badges and SAOs. 
License is MIT so do what you want with it just don't litigate me. 

**NOTE** I screwed up and wipped my laptop hard drive before pulling the final firmware version off it. The version in this repo is from right before I left for DC26 and is missing the following items:
- LED mode that cycles though all patterns
- Bonus hidden morse code message at high pattern offset 
- All but one vibe pattern
- Vibe mode that cycles though all patterns once
- Updated touch sensor code. Code in repo works good in my house in MN but was unuseable in the dry Nevada enviroment. 

## InkScape
Inkscape was used for the "art" layout of the badge. This mainly consisted of the outline, Stash, motors, IR sensor locations, and eyebrows. These layser were converted into SVG files then imported into KiCad as footprints. 
The edge cuts were post processed via Perl scripts to convert it from a filled zone (KiCad 3D viewer pukes on this) to line segemnts. 

## KiCad
This is a KiCad 4.x project that has been updated to 5.0 so some things are a little funky. 
Note the following parts were not populated in the final design:
1x 0.1uF cap
4x 22uF cap
2x diodes
1x badge bus connector
1x SAO connector 

## mplabX
This is a mplabX 4.2 project that was upgraded mid project to 5.0. All programming / debug was done with a PicKit4 or a PicKit3 (killed my PK4 just before leaving for DC26)
The firmware source is all contained in Mr_Stash.asm (see not above about missing functions)

## documentation
This is a XLS/PDF dump of the spreadsheet documentation I was using during development. 
All the menu items and command protocall are detailed in here. 






Copyright (c) 2018 Peter Shabino

Permission is hereby granted, free of charge, to any person obtaining a copy of this hardware, software, and associated documentation files 
(the "Product"), to deal in the Product without restriction, including without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Product, and to permit persons to whom the Product is furnished to do so, subject to the 
following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Product.

THE PRODUCT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE PRODUCT OR THE USE OR OTHER DEALINGS IN THE PRODUCT.
