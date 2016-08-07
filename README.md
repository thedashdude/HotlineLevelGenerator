# HotlineLevelGenerator
HotlineLevelGenerator generates random levels for Hotline Miami 2: Wrong Number.

To generate a level for Hotline Miami 2
---
  1. Create a new level in the HM2 level editor.
  2. Hit 'o' while it is highlighted to open the files for it.
  3. Run `main.lua` to create/write wll.txt, obj.txt and tls.txt.
  4. Copy the data from the written files to level0.wll, level0.obj and level0.tls using Notepad++.
  5. Clear `level0.play`
  6. Load the level in HM2, and then save it.
  7. You may now play the randomly generated level.

Info on the file in HotlineLevelGenerator
---
  * `main.lua` is the lua code the build a random level and write the data to the text files
  * `DashSolids.lua` is a small collision detection file used to avoid overlapping rooms
  * `wll.txt` is an example output of 'main.lua'
  * `obj.txt` is an example output of 'main.lua'
  * `tls.txt` is an example output of 'main.lua'
  * `HotlineExplain.txt` is short explanation of what the files in a level do
  * `HotlineExplainObj.txt` is a more in-depth explanation of the 'level0.obj' file
  * `HotlineExplainTls.txt` is a more in-depth explanation of the 'level0.tls' file
  * `HotlineExplainWll.txt` is a more in-depth explanation of the 'level0.Wll' file
  * `HotlineExplainPlay.txt` is a more in-depth explanation of the 'level0.Play' file

---
Feel free to do with this code and information as you wish, but please give credit.
