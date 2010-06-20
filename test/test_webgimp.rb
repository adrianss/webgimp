require 'helper'

class TestWebgimp < Test::Unit::TestCase
  def test_it_should_get_current_layer_state
    # visibility, offset, mode, opacity
  end
  def test_it_should_add_a_layer_state_to_layers_states
    image = 1
    layer_states = LayerStates.new(image)
  end
end
