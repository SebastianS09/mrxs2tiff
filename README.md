# mrxs2tiff

_For digital pathology_

A simple bash script to convert scanned digital whole slide images in the MIRAX .mrxs implementation from 3DHistech to pyramidal tiffs using vips

Change arguments to vips such as tile size directly in script 

Sample vips call:

    vips tiffsave $INPUT[autocrop=true] $OUTPUT --tile --tile-width 256 --tile-height 256 --pyramid --bigtiff --compression=jpeg --Q 85 --vips-progress
