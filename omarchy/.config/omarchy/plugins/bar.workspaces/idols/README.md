# Workspace portraits

One PNG per member, 128x128, circle-cropped by the widget at render time.
Filenames come from the `members` map at the top of Workspaces.qml:

    toru.png       workspace 1   Asakura Toru
    madoka.png     workspace 2   Higuchi Madoka
    koito.png      workspace 3   Fukumaru Koito
    hinana.png     workspace 4   Ichikawa Hinana
    (none)         workspace 5   falls back to a dot in the theme accent

All four were cut from the noctchill theme's own fastfetch logo,
~/.config/omarchy/themes/noctchill/idol.png (750x700). To recut:

    SRC=~/.config/omarchy/themes/noctchill/idol.png
    magick "$SRC" -crop 150x150+147+75  +repage -resize 128x128 -strip toru.png
    magick "$SRC" -crop 145x145+372+132 +repage -resize 128x128 -strip madoka.png
    magick "$SRC" -crop 140x140+257+292 +repage -resize 128x128 -strip koito.png
    magick "$SRC" -crop 135x135+544+307 +repage -resize 128x128 -strip hinana.png

Tighter crops read better: at 20px the face should fill most of the circle.
A missing file falls back to that member's colour as a dot, so a partial set
is fine.

To remap workspaces, rename members, or point at a directory outside the
repo, set `members` / `iconDir` / `iconSize` on the `bar.workspaces` entry in
~/.config/omarchy/shell.json.
