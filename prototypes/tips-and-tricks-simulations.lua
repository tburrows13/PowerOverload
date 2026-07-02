local simulations = {}

simulations.po_main =
{
  init =
  [[
    player = game.simulation.create_test_player{name = "big K"}
    player.character.teleport{0, 3}
    game.simulation.camera_position = {0, 0.5}
    game.simulation.camera_player = player
    game.simulation.camera_player_cursor_position = player.position

    game.surfaces[1].create_entity{name = "po-huge-electric-pole", position = {-6, 0}, force = "player"}
    game.surfaces[1].create_entity{name = "po-medium-electric-fuse", position = {0, 0}, force = "player"}
    game.surfaces[1].create_entity{name = "po-transformer", position = {5, 0}, force = "player"}

    step_1 = function()
      script.on_nth_tick(1, function()
        if game.simulation.move_cursor({position = {-6, 0}, speed = 0.05}) then
          step_2()
        end
      end)
    end

    step_2 = function()
      local count = 60
      script.on_nth_tick(1, function()
        count = count - 1
        if count > 0 then return end
        if game.simulation.move_cursor({position = {5, 0}, speed = 0.05}) then
          step_1()
        end
      end)
    end

    step_1()
  ]]
}

return simulations
