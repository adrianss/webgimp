require 'yaml'

module WebGimp
  module FileAccess

    private
    def load_config_file(filename)
      begin
        raw_config = File.read(filename)
        config = YAML.load(raw_config)
      rescue
        config = { }
      end

      config
    end

    def store_config_file(filename, config)
      File.open(filename, "w") do |f|
        f.puts(config.to_yaml)
      end
    end

    def image_filename(image = nil)
      image ||= @image
      begin
        name = PDB['gimp-image-get-filename'].call(image) + ".yml"
      rescue
        name = ""
      end

      name
    end
  end

  class LayerStates
    include FileAccess

    def initialize(image)
      @image = image
      get_state
    end

    def restore_by_name(state_name)
      filename = image_filename
      return if filename.empty?
      config = load_config_file(filename)
      layers_state = config.has_key?(:layer_states) && config[:layer_states][state_name]
      if layers_state
        set_state(layers_state)
      end
    end

    def save_by_name(state_name)
      filename = image_filename
      return if filename.empty?
      config = load_config_file(filename)
      if config.has_key?(:layer_states) && config[:layer_states].is_a?(Hash)
        config[:layer_states][state_name] = @layer_states
      else
        config[:layer_states] = { state_name => @layer_states }
      end
      store_config_file(filename, config)
    end

    def get_state
      @layer_states = []
      layers.each do |layer|
        @layer_states << get_layer_state(layer)
      end

      @layer_states
    end

    def set_state(layers_state = nil)
      layers_state ||= @layer_states
      layers_state.each do |state|
        restore_layer_state(state)
      end
    end


    private

    def layers
      @layers = PDB['gimp-image-get-layers'].call(@image)[1]

      @layers
    end

    def get_layer_state(layer)
      state = { }
      state[:tattoo] = PDB['gimp-layer-get-tattoo'].call(layer)
      state[:visibility] = PDB['gimp-drawable-get-visible'].call(layer)
      state[:opacity] = PDB['gimp-layer-get-opacity'].call(layer)
      state[:offsets] = PDB['gimp-drawable-offsets'].call(layer)
      state[:mode] = PDB['gimp-layer-get-mode'].call(layer)

      state
    end

    def restore_layer_state(state)
      layer = nil

      if state[:tattoo]
        layer = PDB['gimp-image-get-layer-by-tattoo'].call(@image, state[:tattoo])
      end

      if layer
        PDB['gimp-drawable-set-visible'].call(layer, state[:visibility]) if state[:visibility]
        PDB['gimp-layer-set-opacity'].call(layer, state[:opacity]) if state[:opacity]
        PDB['gimp-layer-set-offsets'].call(layer, *(state[:offsets])) if state[:offsets]
        PDB['gimp-layer-set-mode'].call(layer, state[:mode]) if state[:mode]
      end

      true
    end
  end

  class ImageSlices
    include FileAccess
    def initialize(image)
      @image = image
      get_images
    end

    def get_images
      @images = []
      filename = image_filename
      return if filename.empty?
      config = load_config_file(filename)

      if config.has_key?(:image_slices) && config[:image_slices].is_a?(Hash)
        @images = config[:image_slices].values
      end
    end

    def export_all
      @images.each do |image|
        #File.open("/home/wander/mydebug.log", "w") { |f| f.puts "#{image.inspect}"}
        ImageSlice.new(image.merge({ "image" => @image })).export
      end
    end
  end

  class ImageSlice
    include FileAccess

    def initialize(opts = { })
      #name, path, formats = ["jpg"]
      @image = opts["image"]
      @name = opts["name"]
      @path = opts["path"]
      @state_name = opts["state_name"] || (@name + ".img")
      @formats = opts["formats"] || ["jpg"]
      if !opts["selection"]
        @selection = PDB['gimp-selection-bounds'].call(@image)
        @selection.shift # get only coor x1, y1, x2, y2
      else
        @selection = opts["selection"]
      end
    end

    def export
      # restore layers state
      WebGimp::LayerStates.new(@image).restore_by_name(@state_name)
      x1 = @selection[0]
      y1 = @selection[1]
      x2 = @selection[2]
      y2 = @selection[3]
      width = (x2 - x1).abs
      height = (y2 - y1).abs
      PDB['gimp-selection-none'].call(@image)
      param_selection = [@image, x1, y1, width, height, CHANNEL_OP_ADD, false, 0]
      File.open("/home/wander/mydebug.log", "w") { |f| f.puts "#{param_selection.inspect}"}
      PDB['gimp-rect-select'].call(*param_selection)
      image_selection = PDB['gimp-edit-copy-visible'].call(@image)
      if image_selection
        img = PDB['gimp-edit-paste-as-new'].call
        #Image.new(width, height, RGB)
        #layer = Layer.new(img, width, height, RGBA_IMAGE, @name, 100, NORMAL_MODE)
        
        #img.add_layer(layer, nil)
        # img
        Display.new(img)
        Display.flush
      end
      # restore selection
      # copy visible
      # create new image with copy selection
      # crop
      # save for web
    end

    def save
      filename = image_filename
      return if filename.empty?
      config = load_config_file(filename)
      image_slice = {
        "name" => @name,
        "path" => @path,
        "state_name" => @state_name,
        "selection" => @selection,
        "formats" => @formats
      }

      if config.has_key?(:image_slices) && config[:image_slices].is_a?(Hash)
        config[:image_slices][@name] = image_slice
      else
        config[:image_slices] = { @name => image_slice }
      end
      store_config_file(filename, config)
    end
  end
end
