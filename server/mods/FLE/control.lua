-- A docker image with the Factorio headless server which has a mod with different scenarios. The mod exposes LUA functions for all the actions available in the game including extracting stats.
-- An application makes it easy to configure and spin up the docker image for a specific scenario and with a specific amount of agents. It includes a thin RCON wrapper mapping to the exposed LUA functions, so it is easy to work with. 


script.on_init(function()
  global.initial_tiles    = {}
  global.initial_entities = {}

  local surface = game.surfaces["nauvis"]  -- or your scenario surface
  surface.show_clouds = false
  surface.always_day = true

  -- Capture all tiles
  for _, tile in pairs(surface.find_tiles_filtered{}) do
    table.insert(global.initial_tiles, {name = tile.name, position = tile.position})
  end

  -- Capture all entities
  for _, ent in pairs(surface.find_entities{}) do
    table.insert(global.initial_entities, {
      name      = ent.name,
      position  = ent.position,
      direction = ent.direction,
      force     = ent.force.name
    })
  end

end)

script.on_event(defines.events.on_player_joined_game, function(event)
  local p = game.players[event.player_index]  

  if p.character and p.character.valid then
    p.character.destroy()
  end

  p.set_controller{ type = defines.controllers.spectator }

  local chars = p.surface.find_entities_filtered{ type = "character" }

  if chars[1] then
    p.associate_character(chars[1])
    p.set_controller{
      type      = defines.controllers.character,
      character = chars[1]
    }
  end
end)

function reset_scenario(num_characters)
  local surface = game.surfaces["nauvis"]
  surface.clear()

  surface.set_tiles(global.initial_tiles, true)
  for _, data in pairs(global.initial_entities) do
    surface.create_entity{
      name      = data.name,
      position  = data.position,
      direction = data.direction,
      force     = game.forces[data.force],
      raise_built = true
    }
  end

  spawn_positions = {
    { 0,  0},  -- center
    { 0,  1},  -- north
    { 0, -1},  -- south
    { 1,  0},  -- east
    {-1,  0},  -- west
    { 1,  1},  -- northeast
    { 1, -1},  -- southeast
    {-1,  1},  -- northwest
    {-1, -1},  -- southwest
  }

  for i = 1, num_characters do
    surface.create_entity{
      name     = "character",
      position = spawn_positions[i],
      force    = game.forces.player
    }
  end
end

remote.add_interface("AICommands", {
  reset = function(num_characters)
    if not num_characters or num_characters < 1 and num_characters > 9 then
      num_characters = 1
    end

    reset_scenario(num_characters)
  end,
  move = function(player_index, pos)
    update_destination_position(pos.x, pos.y)
  end,
  craft = function(player_index, item, count)
	-- global.tas.player = game.get_player(player_index)
	-- global.tas.item = item
	-- global.tas.count = count or -1
	-- return craft()

	local chars = global.tas.player.surface.find_entities_filtered{type='character',force=game.forces.player}
	chars[player_index].begin_crafting{count = count, recipe = item}

  end,
})

commands.add_command(
  "flip",
  "Cycle through available characters on this surface: /flip [next|prev]",
  function(cmd)
    -- 1. Fetch the calling player
    local player = game.get_player(cmd.player_index)
    if not (player and player.valid) then return end

    -- 2. Gather all character entities on their surface
    local chars = player.surface.find_entities_filtered{ type = "character" }
    if #chars == 0 then
      player.print("No characters available to flip through.")
      return
    end

    -- 3. Determine the index of the currently controlled character (if any)
    local current = player.character
    local cur_index = 1
    if current and current.valid then
      for i, c in ipairs(chars) do
        if c == current then
          cur_index = i
          break
        end
      end
    end

    -- 4. Parse direction argument
    local dir = (cmd.parameter or "next"):lower()
    local new_index
    if dir == "prev" then
      new_index = ((cur_index - 2) % #chars) + 1  -- wrap backwards
    else
      new_index = (cur_index % #chars) + 1        -- wrap forwards
    end

    -- 5. Attach player to the new character
    local target = chars[new_index]
    if target and target.valid then
      -- optional: associate the character for kill tracking, etc.
      player.associate_character(target)

      -- switch controller to that character
      player.set_controller{
        type      = defines.controllers.character,
        character = target
      }

      player.print(
        ("Switched to character #%d at position [%.1f, %.1f]")
        :format(target.unit_number, target.position.x, target.position.y)
      )
    else
      player.print("Failed to switch character.")
    end
  end
)

local function clean_it_up_later()
  local area = {
    {game.players[1].position.x - 50, game.players[1].position.y - 50},
    {game.players[1].position.x + 50, game.players[1].position.y + 50}
  }

  local pole = game.players[1].surface.find_entities_filtered{area=area, type="electric-pole"}[1]
  game.print(pole)
  local stats = pole.electric_network_statistics
  game.print(stats)

  local prod = 0
  for name in pairs(stats.output_counts) do
    prod = prod +
      stats.get_flow_count{
        name            = name,
        output          = true,
        precision_index = defines.flow_precision_index.one_minute
      }
  end


  local cap = 0
  for _, gen in ipairs(game.players[1].surface.find_entities_filtered{area=area, type="burner-generator"}) do
  game.print(gen)
    if gen.is_connected_to_electric_network() then
      cap = cap + gen.prototype.max_power_output
    end
  end
  for _, solar in ipairs(game.players[1].surface.find_entities_filtered{area=area, type="solar-panel"}) do
  game.print(solar)
    if solar.is_connected_to_electric_network() then
      cap = cap + solar.get_electric_output_flow_limit()
    end
  end

  for _, solar in ipairs(game.players[1].surface.find_entities_filtered{area=area, type="generator"}) do
    game.print(solar)

    if solar.is_connected_to_electric_network() then
      cap = cap + solar.prototype.max_power_output
    end
  end

  game.print(string.format(
    "Production: %.1f kW of %.1f kW",
    prod*60/1000,
    cap*60/1000
  ))





  local area = {
    {game.player.position.x - 50, game.player.position.y - 50},
    {game.player.position.x + 50, game.player.position.y + 50}
  }


  local buildings = game.player.surface.find_entities_filtered{
    area  = area,
    force = game.player.force
  }

  local status_names = {}
  for name, code in pairs(defines.entity_status) do
    status_names[code] = name
  end

  local direction_names = {}
  for name, code in pairs(defines.direction) do
    direction_names[code] = name
  end

  for _, b in ipairs(buildings) do
    local stat_code = b.status
    local stat_name = status_names[stat_code] or "unknown"
  local dir_code  = b.direction or defines.direction.north
    local dir_name  = direction_names[dir_code] or tostring(dir_code)

    game.print(string.format(
      "%s @ (%.1f, %.1f): status=%s, direction=%s",
      b.name,
      b.position.x, b.position.y,
      stat_name ,
      dir_name  
    ))
  end
end