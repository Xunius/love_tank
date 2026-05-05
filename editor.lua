local Editor = {}

function Editor.handleCustomMapInput(key)
    if key == "escape" then
        -- Return to main menu
        custom_map_menu.active = false
        return
    end

    if #custom_map_menu.available_maps == 0 then
        return -- No maps to navigate
    end

    if key == "up" then
        custom_map_menu.cursor_position = custom_map_menu.cursor_position - 1
        if custom_map_menu.cursor_position < 1 then
            custom_map_menu.cursor_position = #custom_map_menu.available_maps
        end

        -- Handle scrolling
        if custom_map_menu.cursor_position <= custom_map_menu.scroll_offset then
            custom_map_menu.scroll_offset = math.max(0, custom_map_menu.cursor_position - 1)
        elseif custom_map_menu.cursor_position > custom_map_menu.scroll_offset + custom_map_menu.max_visible then
            custom_map_menu.scroll_offset = custom_map_menu.cursor_position - custom_map_menu.max_visible
        end

        custom_map_menu.cursor_blink_timer = 0
        custom_map_menu.cursor_visible = true

    elseif key == "down" then
        custom_map_menu.cursor_position = custom_map_menu.cursor_position + 1
        if custom_map_menu.cursor_position > #custom_map_menu.available_maps then
            custom_map_menu.cursor_position = 1
        end

        -- Handle scrolling
        if custom_map_menu.cursor_position <= custom_map_menu.scroll_offset then
            custom_map_menu.scroll_offset = math.max(0, custom_map_menu.cursor_position - 1)
        elseif custom_map_menu.cursor_position > custom_map_menu.scroll_offset + custom_map_menu.max_visible then
            custom_map_menu.scroll_offset = custom_map_menu.cursor_position - custom_map_menu.max_visible
        end

        custom_map_menu.cursor_blink_timer = 0
        custom_map_menu.cursor_visible = true

    elseif key == "return" or key == "space" then
        -- Load selected custom map
        if custom_map_menu.cursor_position <= #custom_map_menu.available_maps then
            local selected_map = custom_map_menu.available_maps[custom_map_menu.cursor_position]
            Editor.loadCustomMapAndStartGame(selected_map)
        end
    end
end

-- Add this function to initialize the custom map menu:
function Editor.initCustomMapMenu()
    custom_map_menu.active = true
    custom_map_menu.cursor_position = 1
    custom_map_menu.cursor_blink_timer = 0
    custom_map_menu.cursor_visible = true
    custom_map_menu.scroll_offset = 0

    -- Get available maps
    custom_map_menu.available_maps = Editor.getAvailableMaps()

    if #custom_map_menu.available_maps == 0 then
        -- No maps found, you might want to show a message
        print("No custom maps found")
    end
end

-- Add this function to load a custom map and start the game:
function Editor.loadCustomMapAndStartGame(mapName)
    -- Set up game state
    game_state = "game"
    stage = 1  -- Custom maps use stage 1 settings
    playing_custom_map = true

    -- Initialize world first
    world = wf.newWorld(0, 0, true)
    Map.initCollisionClasses()
    Map.addBorder()

    enemy_color = 'silver'
    if stage == 2 then
        enemy_color = 'green'
    end

    --mapName = 'maps' .. mapName
    print(mapName)

    -- Try to load the custom map
    if Editor.loadMap(mapName) then
        print("Successfully loaded custom map: " .. mapName)

        -- Initialize player and game state
        player = Entities.spawnPlayer(false, starting_player_level)

        -- Reset game variables
        enemies_spawned = 0
        enemies_defeated = 0
        total_enemies_to_spawn = stage_settings[1].total_enemies_to_spawn  -- Use stage 1 settings
        spawn_timer = stage_settings[1].spawn_timer
        ori_spawn_timer = 5
        game_over = false
        game_won = false

        -- Reset engine sound
        Audio.stopEngineSound()
        engine_state.current = "idle"
        engine_state.is_fading = false
        engine_state.fade_timer = 0
        love.timer.sleep(0.1)  -- Small delay to ensure everything is set up
        Audio.startEngineSound()

        -- Reset other game state
        bullets = {}
        enemy_bullets = {}
        enemy_engine_states = {}
        enemies = {}
        spawn_effects = {}
        active_particle_systems = {}
        damage_numbers = {}
        score_numbers = {}
        p1_kill_counts = {}
        p2_kill_counts = {}
        pickups = {}
        drop_pickup_rate = 0.4

        for ll in pairs(enemy_levels) do
            p1_kill_counts[ll] = 0
        end

        -- Initialize spawn locations
        spawn_locations = {
            {x = 0, y = 0},
            {x = math.floor(world_width_in_cells / 2), y = 0},
            {x = world_width_in_cells - 1, y = 0}
        }

        -- Clear tank trails
        tank_trails.player_trail = {left_track = {}, right_track = {}}
        tank_trails.enemy_trails = {}

        -- Reset power-ups
        is_freeze = false
        is_steel_wall = false
        shields = {}
        you_win_timer = 5
        world_expanded = false

        -- Initialize camera
        camera.x = 0
        camera.y = 0
        camera.shake_duration = 0
        camera.shake_magnitude = 0
        camera.shake_x = 0
        camera.shake_y = 0

        -- Close custom map menu
        custom_map_menu.active = false

        gameover_label = {quad = ui_quads['gameover'],
            x = window_width / 2 - cell_size * 2,
            y = window_height,
            min_y = window_height * 0.4,
            vy = -250}

    else
        print("Failed to load custom map: " .. mapName)
        -- Return to title screen on failure
        Title.loadTitlePage()
    end
end

function Editor.initConstructionMode()
    construction.is_active = true
    game_state = "construction"

    -- Initialize empty world
    world = wf.newWorld(0, 0, true)
    Map.initCollisionClasses()
    Map.addBorder()

    map_objects = {}

    -- Set cursor to center of map
    construction.cursor_x = math.floor(world_width_in_cells / 2)
    construction.cursor_y = math.floor(world_height_in_cells / 2)

    -- Place base
    base = {}
    base.x = start_cell_x * cell_size + cell_size / 2
    base.y = start_cell_y * cell_size + cell_size / 2
    base.hp = 1
    base.collider = world:newRectangleCollider(base.x - cell_size / 2, base.y - cell_size / 2, cell_size, cell_size)
    base.collider:setFixedRotation(true)
    base.collider:setType('static')
    base.collider:setCollisionClass('Base')
    base.collider:setObject(base)

    -- Build walls around base
    Map.buildBaseWalls()

    -- Initialize camera for construction
    camera.x = 0
    camera.y = 0

    construction.preview_block = construction.available_blocks[construction.selected_block_index]
end

function Editor.handleConstructionInput(key)

    if construction.save_prompt.active then
        if key == "return" then
            -- Save map with entered name
            --saveMap(construction.save_prompt.text)
            Editor.saveMapFromConstruction(construction.save_prompt.text)
            construction.save_prompt.active = false
            Title.loadTitlePage()
        elseif key == "escape" then
            -- Cancel save
            construction.save_prompt.active = false
            Title.loadTitlePage()
        elseif key == "backspace" then
            construction.save_prompt.text = string.sub(construction.save_prompt.text, 1, -2)
        elseif string.len(key) == 1 and string.len(construction.save_prompt.text) < 20 then
            construction.save_prompt.text = construction.save_prompt.text .. key
        end
        return
    end

    if key == "escape" then
        -- Show save prompt
        construction.save_prompt.active = true
        construction.save_prompt.text = ""
        construction.save_prompt.cursor_blink = 0
        construction.save_prompt.cursor_visible = true

    elseif key == "up" then
        construction.cursor_y = math.max(0, construction.cursor_y - 1)

    elseif key == "down" then
        construction.cursor_y = math.min(world_height_in_cells - 1, construction.cursor_y + 1)

    elseif key == "left" then
        construction.cursor_x = math.max(0, construction.cursor_x - 1)

    elseif key == "right" then
        construction.cursor_x = math.min(world_width_in_cells - 1, construction.cursor_x + 1)

    elseif key == "x" then
        -- Scroll forward through blocks
        construction.selected_block_index = construction.selected_block_index + 1
        if construction.selected_block_index > #construction.available_blocks then
            construction.selected_block_index = 1
        end
        construction.preview_block = construction.available_blocks[construction.selected_block_index]

    elseif key == "z" then
        -- Scroll backward through blocks
        construction.selected_block_index = construction.selected_block_index - 1
        if construction.selected_block_index < 1 then
            construction.selected_block_index = #construction.available_blocks
        end
        construction.preview_block = construction.available_blocks[construction.selected_block_index]

    elseif key == "return" or key == "space" then
        -- Place selected block at cursor position
        Editor.placeBlockAtCursor()
    end
end


function Editor.createConsNewBlock(grid_x, grid_y, block_type)

    local x = grid_x * cell_size
    local y = grid_y * cell_size
    local width, height = cell_size, cell_size
    local is_full = true

    if block_type == "steel_quarter" then
        width, height = cell_size / 2, cell_size / 2
        is_full = false
    elseif string.find(block_type, "_") then
        is_full = false
        if string.find(block_type, "right") or string.find(block_type, "left") then
            width = cell_size / 2
        elseif string.find(block_type, "top") or string.find(block_type, "bottom") then
            height = cell_size / 2
        end
    end

    local new_block = {
        x = x,
        y = y,
        sub_x = 0,
        sub_y = 0,
        width = width,
        height = height,
        type = block_type,
        is_full_block = is_full,
        collider = nil
    }

    -- Adjust sub positions for partial blocks
    if block_type == "brick_right" or block_type == "steel_right" then
        new_block.sub_x = cell_size / 2
        --print('####', new_block.sub_x, new_block.sub_y)
    elseif block_type == "brick_bottom" or block_type == "steel_bottom" then
        new_block.sub_y = cell_size / 2
        --print('####', new_block.sub_x, new_block.sub_y)
    end
    return new_block
end

function Editor.placeBlockAtCursor()
    local grid_x = construction.cursor_x
    local grid_y = construction.cursor_y
    local block_type = construction.available_blocks[construction.selected_block_index]

    -- Don't place blocks on base or base walls
    if (grid_x == start_cell_x and grid_y == start_cell_y) then
        return
    end

    -- Remove existing block if any
    if map_objects[grid_x] and map_objects[grid_x][grid_y] then
        for _, block in ipairs(map_objects[grid_x][grid_y]) do
            if block.collider and not block.collider:isDestroyed() then
                block.collider:destroy()
            end
        end
    end

    -- Create new block
    local new_block = Editor.createConsNewBlock(grid_x, grid_y, block_type)

    -- Create collider
    new_block.collider = world:newRectangleCollider(
        new_block.x + new_block.sub_x,
        new_block.y + new_block.sub_y,
        new_block.width,
        new_block.height
    )
    new_block.collider:setType('static')
    new_block.collider:setObject(new_block)

    -- Set collision class
    local prefix = block_type:match("([^_]+)")
    local collision_class
    if prefix == 'brick' then
        collision_class = 'Brick'
    elseif prefix == 'steel' then
        collision_class = 'Steel'
    elseif prefix == 'grass' then
        collision_class = 'Grass'
    elseif prefix == 'water' then
        collision_class = 'Water'
    elseif prefix == 'ice' then
        collision_class = 'Ice'
    end

    new_block.collider:setCollisionClass(collision_class)

    if block_type == 'ice' then
        new_block.collider:setSensor(true)
    end

    -- Store block
    map_objects[grid_x] = map_objects[grid_x] or {}
    map_objects[grid_x][grid_y] = {new_block}
end

function Editor.updateConstruction(dt)
    if construction.save_prompt.active then
        construction.save_prompt.cursor_blink = construction.save_prompt.cursor_blink + dt
        if construction.save_prompt.cursor_blink >= 0.5 then
            construction.save_prompt.cursor_visible = not construction.save_prompt.cursor_visible
            construction.save_prompt.cursor_blink = 0
        end
    end
end

function Editor.drawConstruction()
    love.graphics.setBackgroundColor(0.4, 0.4, 0.4)

    -- Draw world
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- Draw black background
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, world_width, world_height)
    love.graphics.setColor(1, 1, 1)

    -- Draw borders
    Draw.drawBorder()

    -- Draw base
    Draw.drawBase()

    -- Draw map objects
    Draw.drawMapObjects(false)
    Draw.drawMapObjects(true)

    -- Draw cursor (tank sprite)
    local cursor_world_x = construction.cursor_x * cell_size
    local cursor_world_y = construction.cursor_y * cell_size
    --print('cx', construction.cursor_x, construction.cursor_y, 'cursor_world_x', cursor_world_x, 'cursor_world_y', cursor_world_y)

    love.graphics.setColor(1, 1, 1, 0.8)  -- Slightly transparent
    love.graphics.draw(
        spritesheet,
        player_quads[1][0],
        cursor_world_x + cell_size/2,
        cursor_world_y + cell_size/2,
        0,
        cell_size / full_sprite_width,
        cell_size / full_sprite_height,
        full_sprite_width/2,
        full_sprite_height/2
    )

    -- Draw preview block under cursor
    if construction.preview_block and map_objects_quads[construction.preview_block] then
        love.graphics.setColor(1, 1, 1, 1.0)  -- More transparent
        local p_block = Editor.createConsNewBlock(
            construction.cursor_x, construction.cursor_y, construction.preview_block)
        --print('$$$$', construction.cursor_x, construction.cursor_y, p_block.x, p_block.y, p_block.width, p_block.height)

        love.graphics.draw(
            spritesheet,
            map_objects_quads[construction.preview_block],
            p_block.x + p_block.sub_x, p_block.y + p_block.sub_y,
            0,
            cell_size / full_sprite_width,
            cell_size / full_sprite_height
        )

        --[[
        love.graphics.draw(
            spritesheet,
            map_objects_quads[construction.preview_block],
            cursor_world_x + cell_size/2,
            cursor_world_y + cell_size/2,
            0,
            cell_size / full_sprite_width,
            cell_size / full_sprite_height,
            full_sprite_width/2,
            full_sprite_height/2
        )
        --]]
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.pop()

    -- Draw UI
    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.newFont(16)
    love.graphics.setFont(font)
    love.graphics.print("CONSTRUCTION MODE", 10, 10)
    love.graphics.print("Cursor: " .. construction.cursor_x .. ", " .. construction.cursor_y, 10, 30)
    love.graphics.print("Block: " .. (construction.preview_block or "none"), 10, 50)
    love.graphics.print("Controls:", 10, 80)
    love.graphics.print("Arrow Keys: Move cursor", 10, 100)
    love.graphics.print("X/Z: Change block", 10, 120)
    love.graphics.print("Space: Place block", 10, 140)
    love.graphics.print("ESC: Save/Exit", 10, 160)

    -- Draw save prompt
    if construction.save_prompt.active then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, window_width, window_height)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Enter map name (or ESC to exit without saving):", 0, window_height/2 - 60, window_width, "center")

        local prompt_text = construction.save_prompt.text
        if construction.save_prompt.cursor_visible then
            prompt_text = prompt_text .. "_"
        end
        love.graphics.printf(prompt_text, 0, window_height/2 - 20, window_width, "center")
        love.graphics.printf("Press ENTER to save", 0, window_height/2 + 20, window_width, "center")
    end
end

function Editor.saveMap(filename)
    if not filename or filename == "" then
        print("Invalid filename")
        return false
    end

    local mapData = {}

    -- Add header information
    table.insert(mapData, "-- Battle City Custom Map")
    table.insert(mapData, "-- Map: " .. filename)
    table.insert(mapData, "-- Created: " .. os.date())
    table.insert(mapData, "")
    table.insert(mapData, "local mapData = {")
    table.insert(mapData, '  version = "1.0",')
    table.insert(mapData, '  name = "' .. filename .. '",')
    table.insert(mapData, "  world_size = {")
    table.insert(mapData, "    width = " .. world_width_in_cells .. ",")
    table.insert(mapData, "    height = " .. world_height_in_cells)
    table.insert(mapData, "  },")
    table.insert(mapData, "  base_position = {")
    table.insert(mapData, "    x = " .. start_cell_x .. ",")
    table.insert(mapData, "    y = " .. start_cell_y)
    table.insert(mapData, "  },")
    table.insert(mapData, "  blocks = {")

    -- Serialize all map objects (excluding base walls which are generated)
    local blockCount = 0
    for grid_x, column in pairs(map_objects) do
        for grid_y, blocks in pairs(column) do
            -- Skip base wall positions (they'll be regenerated)
            local is_base_wall = false
            --if (grid_x >= start_cell_x - 1 and grid_x <= start_cell_x + 1 and
                --grid_y >= start_cell_y - 1 and grid_y <= start_cell_y) then
                -- Check if this is exactly a base wall position
                --if (grid_x == start_cell_x - 1 and grid_y == start_cell_y) or
                   --(grid_x == start_cell_x + 1 and grid_y == start_cell_y) or
                   --(grid_x == start_cell_x and grid_y == start_cell_y - 1) or
                   --(grid_x == start_cell_x - 1 and grid_y == start_cell_y - 1) or
                   --(grid_x == start_cell_x + 1 and grid_y == start_cell_y - 1) then
                    --is_base_wall = true
                --end
            --end

            if not is_base_wall then
                for _, block in ipairs(blocks) do
                    blockCount = blockCount + 1
                    table.insert(mapData, "    {")
                    table.insert(mapData, "      grid_x = " .. grid_x .. ",")
                    table.insert(mapData, "      grid_y = " .. grid_y .. ",")
                    table.insert(mapData, '      type = "' .. block.type .. '",')
                    table.insert(mapData, "      sub_x = " .. block.sub_x .. ",")
                    table.insert(mapData, "      sub_y = " .. block.sub_y .. ",")
                    table.insert(mapData, "      width = " .. block.width .. ",")
                    table.insert(mapData, "      height = " .. block.height .. ",")
                    table.insert(mapData, "      is_full_block = " .. tostring(block.is_full_block))
                    table.insert(mapData, "    },")
                end
            end
        end
    end

    table.insert(mapData, "  }")
    table.insert(mapData, "}")
    table.insert(mapData, "")
    table.insert(mapData, "return mapData")

    -- Join all lines
    local fileContent = table.concat(mapData, "\n")

    -- Write to file
    local filepath = filename .. ".lua"
    local success, error = love.filesystem.write(filepath, fileContent)

    if success then
        print("Map saved successfully: " .. filepath .. " (" .. blockCount .. " blocks)")
        -- Debug: check if file actually exists
        local info = love.filesystem.getInfo(filepath)
        if info then
            print("File confirmed - Size: " .. info.size .. " bytes")
        else
            print("Warning: File not found after write operation")
        end
        return true
    else
        print("Failed to save map: " .. (error or "unknown error"))
        return false
    end
end

function Editor.loadMap(filename)
    local filepath = 'maps/' .. filename .. ".lua"

    -- Check if file exists
    local info = love.filesystem.getInfo(filepath)
    if not info then
        print("Map file not found: " .. filepath)
        print("Available files in save directory:")
        local files = love.filesystem.getDirectoryItems("maps")
        for _, file in ipairs(files) do
            if file:match("%.lua$") then
                print("  " .. file)
            end
        end
        return false
    end

    print("Found map file: " .. filepath .. " (Size: " .. info.size .. " bytes)")

    -- Read file content
    local content, error = love.filesystem.read(filepath)
    if not content then
        print("Failed to read map file: " .. (error or "unknown error"))
        return false
    end

    -- Load and execute the map file
    local chunk, loadError = love.filesystem.load(filepath)
    if not chunk then
        print("Failed to load map file: " .. (loadError or "syntax error"))
        print("File content preview:")
        print(content:sub(1, 200) .. (content:len() > 200 and "..." or ""))
        return false
    end

    -- Execute the chunk safely
    local success, mapData = pcall(chunk)
    if not success then
        print("Failed to execute map file: " .. (mapData or "runtime error"))
        return false
    end

    -- Validate map data
    if type(mapData) ~= "table" or not mapData.blocks then
        print("Invalid map format - missing blocks table")
        return false
    end

    print("Loading map: " .. (mapData.name or filename) .. " with " .. #mapData.blocks .. " blocks")

    -- Initialize world
    --if world then
        --world:destroy()
    --end
    --world = wf.newWorld(0, 0, true)
    --initCollisionClasses()
    --addBorder()

    -- Clear existing map
    map_objects = {}

    -- Set world size (if different from default)
    if mapData.world_size then
        world_width_in_cells = mapData.world_size.width or world_width_in_cells
        world_height_in_cells = mapData.world_size.height or world_height_in_cells
        world_width = world_width_in_cells * cell_size
        world_height = world_height_in_cells * cell_size
    end

    -- Set base position (if different from default)
    if mapData.base_position then
        start_cell_x = mapData.base_position.x or start_cell_x
        start_cell_y = mapData.base_position.y or start_cell_y
    end

    -- Create base
    base = {}
    base.x = start_cell_x * cell_size + cell_size / 2
    base.y = start_cell_y * cell_size + cell_size / 2
    base.hp = 1
    base.collider = world:newRectangleCollider(base.x - cell_size / 2, base.y - cell_size / 2, cell_size, cell_size)
    base.collider:setFixedRotation(true)
    base.collider:setType('static')
    base.collider:setCollisionClass('Base')
    base.collider:setObject(base)

    -- Build base walls
    --buildBaseWalls()

    -- Load blocks
    for i, blockData in ipairs(mapData.blocks) do
        local grid_x = blockData.grid_x
        local grid_y = blockData.grid_y

        if not grid_x or not grid_y or not blockData.type then
            print("Warning: Invalid block data at index " .. i)
        else
            print(i, grid_x, grid_y, blockData.type)
            local block = {
                x = grid_x * cell_size,
                y = grid_y * cell_size,
                sub_x = blockData.sub_x or 0,
                sub_y = blockData.sub_y or 0,
                width = blockData.width or cell_size,
                height = blockData.height or cell_size,
                type = blockData.type,
                is_full_block = blockData.is_full_block or false,
                collider = nil
            }

            local block_type = blockData.type
            local sub_grid_blocks
            if block_type == 'steel' then
                sub_grid_blocks = Map.BreakSteel(block)
                for j, s in ipairs(sub_grid_blocks) do
                    print(j, s.x, s.y, s.type, s.sub_x, s.sub_y)
                end

            elseif block_type == 'brick_left' or block_type == 'brick_right'
                or block_type == 'brick_top' or block_type == 'brick_bottom' then
                sub_grid_blocks = Map.BreakHalfBrickBlock(block)

            else
                sub_grid_blocks = {block}
            end

            -- Create collider
            --[[
            block.collider = world:newRectangleCollider(
                block.x + block.sub_x,
                block.y + block.sub_y,
                block.width,
                block.height
            )
            block.collider:setType('static')
            block.collider:setObject(block)

            -- Set collision class
            local prefix = block.type:match("([^_]+)")
            local collision_class = "Brick"  -- Default fallback

            if prefix == 'brick' then
                collision_class = 'Brick'
            elseif prefix == 'steel' then
                collision_class = 'Steel'
            elseif prefix == 'grass' then
                collision_class = 'Grass'
            elseif prefix == 'water' then
                collision_class = 'Water'
            elseif prefix == 'ice' then
                collision_class = 'Ice'
            end

            block.collider:setCollisionClass(collision_class)

            if block.type == 'ice' then
                block.collider:setSensor(true)
            end
            --]]

            -- Store block
            map_objects[grid_x] = map_objects[grid_x] or {}
            --map_objects[grid_x][grid_y] = map_objects[grid_x][grid_y] or {}
           -- table.insert(map_objects[grid_x][grid_y], block)
            map_objects[grid_x][grid_y] = sub_grid_blocks
        end
    end

    -- Clear player spawn area
    if map_objects[player_start_cell_x] and map_objects[player_start_cell_x][player_start_cell_y] then
        local blocks = map_objects[player_start_cell_x][player_start_cell_y]
        -- Destroy all colliders in this cell
        for _, block in ipairs(blocks) do
            if block.collider and not block.collider:isDestroyed() then
                block.collider:destroy()
            end
        end

        -- Clear the cell
        map_objects[player_start_cell_x][player_start_cell_y] = nil
    end

    print("Map loaded successfully: " .. (mapData.name or filename))
    return true
end



function Editor.getAvailableMaps()
    local maps = {}

    -- Check if maps directory exists
    local info = love.filesystem.getInfo("maps")
    if not info or info.type ~= "directory" then
        print("Maps directory doesn't exist")
        return maps
    end

    local files = love.filesystem.getDirectoryItems("maps")

    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            local name = file:match("^(.+)%.lua$")
            table.insert(maps, name)
        end
    end

    return maps
end

-- Debug function to show save directory location
function Editor.showSaveDirectory()
    local saveDir = love.filesystem.getSaveDirectory()
    print("Love2D save directory: " .. saveDir)

    print("Files in save directory:")
    local files = love.filesystem.getDirectoryItems("")
    for _, file in ipairs(files) do
        local info = love.filesystem.getInfo(file)
        if info then
            print("  " .. file .. " (" .. info.type .. ", " .. (info.size or 0) .. " bytes)")
        end
    end
end

-- Enhanced save function for construction mode
function Editor.saveMapFromConstruction(filename)
    print("Attempting to save map: " .. filename)
    Editor.showSaveDirectory()  -- Debug info

    -- Ensure maps directory exists in save directory
    print("Save directory: " .. love.filesystem.getSaveDirectory())
    local created = love.filesystem.createDirectory("maps")
    print("Create maps dir: " .. tostring(created))

    local success = Editor.saveMap('maps/' .. filename)
    if success then
        print("Construction map saved successfully!")
    else
        print("Failed to save construction map")
    end
    return success
end

-- Example usage functions
function Editor.loadCustomMap(mapName)
    if Editor.loadMap(mapName) then
        return true
    else
        print("Failed to load custom map, using default generation")
        Map.createMap(0, 0, world_width_in_cells, world_height_in_cells)
        Map.buildBaseWalls()
        return false
    end
end

-- Load map into construction mode
function Editor.loadMapIntoConstruction(filename)
    if Editor.loadMap(filename) then
        construction.is_active = true
        game_state = "construction"

        construction.cursor_x = math.floor(world_width_in_cells / 2)
        construction.cursor_y = math.floor(world_height_in_cells / 2)
        construction.selected_block_index = 1
        construction.preview_block = construction.available_blocks[1]

        camera.x = 0
        camera.y = 0

        return true
    end
    return false
end

return Editor
