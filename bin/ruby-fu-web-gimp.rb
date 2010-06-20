require 'rubyfu'

include Gimp
include RubyFu

require '/home/wander/proyectos/webgimp/lib/webgimp.rb'


register(
         "ruby-fu-save-layers-state", #procedure name
         _("Save the current layers state: Visibility, Opacity, Mode, Offsets"), #blurb
         _("Save layers state"), #help
         "Adrian Sanchez", #author
         "Adrian Sanchez", #copyright
         "2010", #date
         _("Save State"), #menupath
         "*", #image types
         [
          ParamDef.STRING("state_name", _("State Name"), "current")
         ], #params
         [] #results
         ) do |run_mode, image, drawable, state_name|

  layers_state = WebGimp::LayerStates.new(image)
  layers_state.save_by_name(state_name)

end

menu_register("ruby-fu-save-layers-state", "<Image>/Web/Layers")


register(
         "ruby-fu-restore-layers-state", #procedure name
         _("Restore the current layers state: Visibility, Opacity, Mode, Offsets"), #blurb
         _("Restore layers state"), #help
         "Adrian Sanchez", #author
         "Adrian Sanchez", #copyright
         "2010", #date
         _("Restore State"), #menupath
         "*", #image types
         [
          ParamDef.STRING("state_name", _("State Name"), "current")
         ], #params
         [] #results
         ) do |run_mode, image, drawable, state_name|

  layers_state = WebGimp::LayerStates.new(image)
  layers_state.restore_by_name(state_name)

  Display.flush
end

menu_register("ruby-fu-restore-layers-state", "<Image>/Web/Layers")



# Set Image slice export state
register(
         "ruby-fu-set-img-slice", #procedure name
         _("Set the current selection, layers state to export as sliced image"), #blurb
         _("Set selection as image to slice"), #help
         "Adrian Sanchez", #author
         "Adrian Sanchez", #copyright
         "2010", #date
         _("Set Image"), #menupath
         "*", #image types
         [
          ParamDef.STRING("image_name", _("Image Name"), "h-bg")
         ], #params
         [] #results
         ) do |run_mode, image, drawable, image_name|
  
  layers_state = WebGimp::LayerStates.new(image)
  state_name = image_name + ".img"  
  layers_state.save_by_name(state_name)
  image_slice = WebGimp::ImageSlice.new("image" => image, "name" => image_name)
  image_slice.save
end

menu_register("ruby-fu-set-img-slice", "<Image>/Web/Slice")


# Export all image slices state
register(
         "ruby-fu-export-all-img-slices", #procedure name
         _("Export all Image slices"), #blurb
         _("Set selection as image to slice"), #help
         "Adrian Sanchez", #author
         "Adrian Sanchez", #copyright
         "2010", #date
         _("Export All"), #menupath
         "*", #image types
         [
         ], #params
         [] #results
         ) do |run_mode, image, drawable|

  layers_state = WebGimp::LayerStates.new(image)
  slices = WebGimp::ImageSlices.new(image)
  slices.export_all
  layers_state.set_state
  Display.flush
end

menu_register("ruby-fu-export-all-img-slices", "<Image>/Web/Slice")
