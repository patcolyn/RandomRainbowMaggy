# Deactivate all layers, select the desired layer to export, and activate the script
# Path and hue ranges are hard coded, modify them as needed

from gimpfu import *

def batch_colorise(image, drawable):
    
    active_layer = pdb.gimp_image_get_active_layer(image)
    layer_name = pdb.gimp_item_get_name(active_layer)
    lock = int(layer_name[-1])
    
    saturation = 80
    lightness = 0 # 10 for bow
    
    
    pdb.gimp_edit_copy(drawable)
    
    """
    for lock in range(0, 9):
        layer = pdb.gimp_image_get_layer_by_name(image, "lock_" + str(lock))
        check = pdb.gimp_image_set_active_layer(image, layer)
    """
    
    for hue in range(0, 360, 10):
        filename = "lock_" + str(lock) + "_" + str(hue) + ".png"
        fullpath = "C:/Program Files/Steam/steamapps/common/The Binding of Isaac Rebirth/mods/RandomRainbowMaggy/generators/gimp-plugin/export/" + filename
        
        pdb.gimp_drawable_colorize_hsl(drawable, hue, saturation, lightness)
        pdb.file_png_save_defaults(image, drawable, fullpath, filename)

        floating_sel = pdb.gimp_edit_paste(drawable, True)
        pdb.gimp_floating_sel_anchor(floating_sel)


register(
    "python-fu-colorise-batch",
    "Batch colourise",
    "Show more UI Options...",
    "Pat Colyn", "Pat Colyn", "2021",
    "Batch colourise",
    "RGBA",
    [
        (PF_IMAGE, "image", "takes current image", None),
        (PF_DRAWABLE, "drawable", "input layer", None),
    ],
    [],
    batch_colorise, menu="<Image>/Scripts"
)


main()