local Map = {}


function Map.buildBaseWalls()

    -- store base walls
    base_walls = {}

    -- left
    local grid_x = start_cell_x - 1
    local grid_y = start_cell_y
    local x = grid_x * cell_size
    local y = grid_y * cell_size

    local new_block = {
        x = x,
        y = y,
        sub_x = cell_size / 2,
        sub_y = 0,
        width = cell_size / 2,
        height = cell_size,
        type = 'brick_right',
        is_full_block = false,
        collider = nil  -- Will be created on demand
    }

    --new_block.collider = world:newRectangleCollider(x + cell_size / 2, y, cell_size / 2, cell_size)
    --new_block.collider:setType('static')
    --new_block.collider:setCollisionClass('Brick')
    --new_block.collider:setObject(new_block)

    map_objects[grid_x] = map_objects[grid_x] or {}
    map_objects[grid_x][grid_y] = {new_block}

    table.insert(base_walls, new_block)

    -- right
    local grid_x = start_cell_x + 1
    local grid_y = start_cell_y
    local x = grid_x * cell_size
    local y = grid_y * cell_size
    local new_block = {
        x = x,
        y = y,
        sub_x = 0,
        sub_y = 0,
        width = cell_size / 2,
        height = cell_size,
        type = 'brick_right',
        is_full_block = false,
        type = 'brick_left',
        collider = nil  -- Will be created on demand
    }

    --new_block.collider = world:newRectangleCollider(x, y, cell_size / 2, cell_size)
    --new_block.collider:setType('static')
    --new_block.collider:setCollisionClass('Brick')
    --new_block.collider:setObject(new_block)

    map_objects[grid_x] = map_objects[grid_x] or {}
    map_objects[grid_x][grid_y] = {new_block}

    table.insert(base_walls, new_block)

    -- top
    local grid_x = start_cell_x
    local grid_y = start_cell_y - 1
    local x = grid_x * cell_size
    local y = grid_y * cell_size
    local new_block = {
        x = x,
        y = y,
        sub_x = 0,
        sub_y = cell_size / 2,
        width = cell_size,
        height = cell_size / 2,
        type = 'brick_right',
        is_full_block = false,
        type = 'brick_bottom',
        collider = nil  -- Will be created on demand
    }

    --new_block.collider = world:newRectangleCollider(x, y + cell_size / 2, cell_size, cell_size / 2)
    --new_block.collider:setType('static')
    --new_block.collider:setCollisionClass('Brick')
    --new_block.collider:setObject(new_block)

    map_objects[grid_x] = map_objects[grid_x] or {}
    map_objects[grid_x][grid_y] = {new_block}

    table.insert(base_walls, new_block)

    -- top left
    local grid_x = start_cell_x - 1
    local grid_y = start_cell_y - 1
    local x = grid_x * cell_size
    local y = grid_y * cell_size
    local new_block = {
        x = x,
        y = y,
        sub_x = cell_size / 2,
        sub_y = cell_size / 2,
        width = cell_size / 2,
        height = cell_size / 2,
        type = 'brick_right',
        is_full_block = false,
        type = 'brick_quarter',
        collider = nil  -- Will be created on demand
    }

    --new_block.collider = world:newRectangleCollider(x + cell_size / 2, y + cell_size / 2, cell_size / 2, cell_size / 2)
    --new_block.collider:setType('static')
    --new_block.collider:setCollisionClass('Brick')
    --new_block.collider:setObject(new_block)

    map_objects[grid_x] = map_objects[grid_x] or {}
    map_objects[grid_x][grid_y] = {new_block}

    table.insert(base_walls, new_block)

    -- top right
    local grid_x = start_cell_x + 1
    local grid_y = start_cell_y - 1
    local x = grid_x * cell_size
    local y = grid_y * cell_size
    local new_block = {
        x = x,
        y = y,
        sub_x = 0,
        sub_y = cell_size / 2,
        width = cell_size / 2,
        height = cell_size / 2,
        type = 'brick_right',
        is_full_block = false,
        type = 'brick_quarter',
        collider = nil  -- Will be created on demand
    }

    --new_block.collider = world:newRectangleCollider(x, y + cell_size / 2, cell_size / 2, cell_size / 2)
    --new_block.collider:setType('static')
    --new_block.collider:setCollisionClass('Brick')
    --new_block.collider:setObject(new_block)

    map_objects[grid_x] = map_objects[grid_x] or {}
    map_objects[grid_x][grid_y] = {new_block}

    table.insert(base_walls, new_block)

    if game_state == 'game' then
        Map.updateActiveColliders()
    end
end


function Map.initCollisionClasses()
    world:addCollisionClass('Base')
    world:addCollisionClass('Player')
    world:addCollisionClass('Enemy')
    world:addCollisionClass('PlayerBullet', { ignores = { 'Player' } })
    world:addCollisionClass('EnemyBullet')
    world:addCollisionClass('Steel')
    world:addCollisionClass('Brick')
    world:addCollisionClass('Border')
    world:addCollisionClass('Ice', { ignores = {'Player', 'PlayerBullet', 'EnemyBullet'}})
    world:addCollisionClass('Water', { ignores = {'PlayerBullet', 'EnemyBullet'}})
    world:addCollisionClass('Grass', { ignores = {'Player', 'Enemy', 'PlayerBullet', 'EnemyBullet'}})
    world:addCollisionClass('Pickup', { ignores = {'Enemy', 'PlayerBullet', 'EnemyBullet'}})

end


function Map.initializeFuelSystem()
    -- Fuel system configuration
    fuel_config = {
        max_fuel = 100,           -- Maximum fuel capacity
        consumption_rate = 0,     -- Fuel consumed per second while moving
        idle_consumption = 0,   -- Fuel consumed per second while idle (engine running)
        refuel_rate = 25,         -- Fuel gained per second from fuel pickups
        low_fuel_threshold = 20,  -- When fuel bar turns red
        critical_fuel_threshold = 10, -- When fuel bar blinks red

        -- Fuel bar visual settings
        bar_width = cell_size * 0.8,  -- Width of fuel bar
        bar_height = 4,               -- Height of fuel bar
        bar_offset_y = -cell_size/2 - 6  -- Position above tank
    }
end


function Map.addBorder()
    local thickness = border_thickness

    top_border = world:newRectangleCollider(-thickness, -thickness, world_width+thickness, thickness)
    top_border:setType('static')
    top_border:setCollisionClass('Border')

    bottom_border = world:newRectangleCollider(-thickness, world_height, world_width+thickness, thickness)
    bottom_border:setType('static')
    bottom_border:setCollisionClass('Border')

    left_border = world:newRectangleCollider(-thickness, -thickness, thickness, world_height+thickness)
    left_border:setType('static')
    left_border:setCollisionClass('Border')

    right_border = world:newRectangleCollider(world_width, -thickness, thickness, world_height+2*thickness)
    right_border:setType('static')
    right_border:setCollisionClass('Border')
end


function Map.check_in_clear_zone(x_cell, y_cell, clear_zone_x, clear_zone_y, clear_radius_x, clear_radius_y)
    return math.abs(x_cell - clear_zone_x) <= clear_radius_x and math.abs(y_cell - clear_zone_y) <= clear_radius_y
end


function Map.chooseRandomBlock()

    local r = math.random()
    local block_type = 'none'
    local is_full, width, height

    if r < 0.09 then block_type = 'steel'
        elseif r < 0.10 then block_type = 'steel_quarter'; is_full = false; width=cell_size / 2; height = cell_size / 2
        elseif r < 0.20 then block_type = 'brick'; is_full = true; width=cell_size; height = cell_size
        elseif r < 0.23 then block_type = 'brick_right'; is_full = false; width=cell_size / 2; height = cell_size
        elseif r < 0.25 then block_type = 'brick_left'; is_full = false; width=cell_size / 2; height = cell_size
        elseif r < 0.28 then block_type = 'brick_top'; is_full = false; width=cell_size; height = cell_size / 2
        elseif r < 0.30 then block_type = 'brick_bottom'; is_full = false; width=cell_size; height = cell_size / 2
        elseif r < 0.35 then block_type = 'water'; is_full = true; width=cell_size; height = cell_size
        --elseif r < 0.36 then block_type = 'water_quarter'; is_full = false; width=cell_size / 2; height = cell_size / 2
        elseif r < 0.40 then block_type = 'ice'; is_full = true; width=cell_size; height = cell_size
        --elseif r < 0.41 then block_type = 'ice_quarter'; is_full = false; width=cell_size / 2; height = cell_size / 2
        elseif r < 0.48 then block_type = 'grass'; is_full = true; width=cell_size; height = cell_size
        --elseif r < 0.50 then block_type = 'grass_quarter'; is_full = false
        else block_type = 'none'
    end
    return block_type, is_full, width, height

end

-- Parse a tile code like "Bf", "B3", "Tf", "R", "X", "E" etc.
-- Returns material ('brick','steel','water','ice','grass','empty','base')
-- and a bitmask of filled quadrants (4 bits: TL=1, TR=2, BL=4, BR=8)
local function parseTileCode(code)
    code = code or 'X'
    local upper = code:upper()

    if upper == 'X' then return 'empty', 0 end
    if upper == 'E' or upper == 'EE' then return 'base', 15 end
    if upper == 'R' then return 'water', 15 end
    if upper == 'S' then return 'ice', 15 end
    if upper == 'F' then return 'grass', 15 end

    -- Brick or Steel with quadrant mask
    local material_char = upper:sub(1,1)
    local material
    if material_char == 'B' then
        material = 'brick'
    elseif material_char == 'T' then
        material = 'steel'
    else
        return 'empty', 0
    end

    local hex_char = upper:sub(2,2)
    if hex_char == '' then return material, 15 end -- just 'B' or 'T' = full

    local mask = tonumber(hex_char, 16) or 15
    return material, mask
end

-- Place a block at grid position with optional quadrant mask
local function placeBlockFromTile(x_cell, y_cell, material, mask)
    if material == 'empty' or material == 'base' then return end

    local x = x_cell * cell_size
    local y = y_cell * cell_size
    local half = cell_size / 2

    -- Quadrant positions: TL(1)=(0,0), TR(2)=(half,0), BL(4)=(0,half), BR(8)=(half,half)
    local quadrants = {
        {bit = 1, sub_x = 0, sub_y = 0},
        {bit = 2, sub_x = half, sub_y = 0},
        {bit = 4, sub_x = 0, sub_y = half},
        {bit = 8, sub_x = half, sub_y = half},
    }

    if mask == 15 then
        -- Full block
        local block_type = material
        local is_full = true
        local width, height = cell_size, cell_size

        local new_block = {
            x = x, y = y, sub_x = 0, sub_y = 0,
            width = width, height = height,
            type = block_type, is_full_block = is_full,
            collider = nil
        }

        local sub_grid_blocks
        if material == 'steel' then
            sub_grid_blocks = Map.BreakSteel(new_block)
        else
            sub_grid_blocks = {new_block}
        end

        map_objects[x_cell] = map_objects[x_cell] or {}
        map_objects[x_cell][y_cell] = sub_grid_blocks
    else
        -- Partial block — place individual quarter blocks
        local sub_grid_blocks = {}
        for _, q in ipairs(quadrants) do
            if mask % (q.bit * 2) >= q.bit then
                local qtype
                if material == 'brick' then
                    qtype = 'brick_quarter'
                elseif material == 'steel' then
                    qtype = 'steel_quarter'
                elseif material == 'water' then
                    qtype = 'water'
                elseif material == 'ice' then
                    qtype = 'ice'
                elseif material == 'grass' then
                    qtype = 'grass'
                end
                table.insert(sub_grid_blocks, {
                    x = x, y = y, sub_x = q.sub_x, sub_y = q.sub_y,
                    width = half, height = half,
                    type = qtype, is_full_block = false,
                    collider = nil
                })
            end
        end
        if #sub_grid_blocks > 0 then
            map_objects[x_cell] = map_objects[x_cell] or {}
            map_objects[x_cell][y_cell] = sub_grid_blocks
        end
    end
end

function Map.createMapFromStageData(stage_number)
    local StageData = require('stage_data')
    local stage_data = StageData[stage_number]
    if not stage_data then return false end

    local map_rows = stage_data.map
    -- Original Battle City: 13x13 grid
    -- Our grid: 15x15, with row 0 for spawns and row 14 for players
    -- Map rows 1-13 correspond to y_cell 1-13, x_cell 1-13
    -- Offset: place at cells 1..13 (centered in the 15-cell grid)
    local x_offset = 0
    local y_offset = 0

    for row_idx, row in ipairs(map_rows) do
        for col_idx, tile_code in ipairs(row) do
            local material, mask = parseTileCode(tile_code)
            local x_cell = (col_idx - 1) + x_offset
            local y_cell = (row_idx - 1) + y_offset
            placeBlockFromTile(x_cell, y_cell, material, mask)
        end
    end

    return true
end

function Map.createMap(gx, gy, world_width_in_cells, world_height_in_cells)

    local world_width = world_width_in_cells * cell_size
    local world_height = world_height_in_cells * cell_size

    local cells_to_check = {
       {x = start_cell_x, y = start_cell_y},
       {x = player_start_cell_x, y = player_start_cell_y},
        unpack(spawn_locations)
       }

    for x_cell = 0, world_width_in_cells - 1 do
        for y_cell = 0, world_height_in_cells - 1 do
            local is_in_clear_zone = false

            for _, cell in ipairs(cells_to_check) do
                if Map.check_in_clear_zone(x_cell, y_cell, cell.x, cell.y, clear_radius_x, clear_radius_y) then
                    is_in_clear_zone = true
                    break
                end
            end

            if not is_in_clear_zone then
                local block_type, is_full, width, height = Map.chooseRandomBlock()

                if block_type ~= 'none' then
                    local x = gx * world_width + x_cell * cell_size
                    local y = gy * world_height + y_cell * cell_size

                    -- Create map object WITHOUT collider (lazy loading will add it)
                    local new_block = {
                        x = x,
                        y = y,
                        sub_x = 0,
                        sub_y = 0,
                        width = width,
                        height = height,
                        type = block_type,
                        is_full_block = is_full,
                        collider = nil  -- Will be created on demand
                    }
                    local sub_grid_blocks

                    if block_type == 'steel' then
                        sub_grid_blocks = Map.BreakSteel(new_block)

                    elseif block_type == 'brick_left' or block_type == 'brick_right'
                        or block_type == 'brick_top' or block_type == 'brick_bottom' then
                        sub_grid_blocks = Map.BreakHalfBrickBlock(new_block)

                    else
                        sub_grid_blocks = {new_block}
                    end

                    local grid_x = gx * world_width_in_cells + x_cell
                    local grid_y = gy * world_height_in_cells + y_cell

                    map_objects[grid_x] = map_objects[grid_x] or {}
                    map_objects[grid_x][grid_y] = sub_grid_blocks

                end
            end
        end
    end
end


function Map.updateActiveColliders()
    local player_x, player_y = player.x, player.y

    -- Check which grid cells are in activation range
    local start_x = math.floor((player_x - ACTIVATION_DISTANCE) / cell_size)
    local end_x = math.floor((player_x + ACTIVATION_DISTANCE) / cell_size)
    local start_y = math.floor((player_y - ACTIVATION_DISTANCE) / cell_size)
    local end_y = math.floor((player_y + ACTIVATION_DISTANCE) / cell_size)

    -- Clamp to world bounds
    start_x = math.max(0, start_x)
    end_x = math.min(world_width_in_cells - 1, end_x)
    start_y = math.max(0, start_y)
    end_y = math.min(world_height_in_cells - 1, end_y)

    -- Activate colliders for objects in range
    for x = start_x, end_x do
        if map_objects[x] then
            for y = start_y, end_y do
                local sub_grid_blocks = map_objects[x][y]
                if sub_grid_blocks then
                    for _, obj in ipairs(map_objects[x][y]) do
                        --local obj = map_objects[x][y]
                        if obj and not obj.collider then

                            -- Create collider on demand
                            obj.collider = world:newRectangleCollider(
                                obj.x + obj.sub_x,
                                obj.y + obj.sub_y,
                                obj.width,
                                obj.height
                            )
                            obj.collider:setType('static')

                            local objtype = obj.type
                            local prefix = objtype:match("([^_]+)")
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

                            obj.collider:setCollisionClass(collision_class)
                            obj.collider:setObject(obj)
                            if obj.type == 'ice' then
                                obj.collider:setSensor(true)
                            end
                            active_colliders[obj] = true
                        end
                    end
                end
            end
        end
    end

    -- Deactivate distant colliders
    for obj in pairs(active_colliders) do
        local distance = math.sqrt((obj.x - player_x)^2 + (obj.y - player_y)^2)
        if distance > DEACTIVATION_DISTANCE then
            if obj.collider and not obj.collider:isDestroyed() then
                obj.collider:destroy()
                obj.collider = nil
            end
            active_colliders[obj] = nil
        end
    end
end


function Map.expandWorld()
    local expand_size = 3  -- This is now manageable with lazy loading
    local orig_width_in_cells = world_width_in_cells
    local orig_height_in_cells = world_height_in_cells
    local orig_width = world_width
    local orig_height = world_height

    -- New world size: x in each dimension
    world_width_in_cells = orig_width_in_cells * expand_size
    world_height_in_cells = orig_height_in_cells * expand_size
    world_width = world_width_in_cells * cell_size
    world_height = world_height_in_cells * cell_size

    local shift_x = orig_width * (expand_size - 1) / 2
    local shift_y = orig_height * (expand_size - 1) / 2

    -- Shift player
    player.x = player.x + shift_x
    player.y = player.y + shift_y
    player.collider:setPosition(player.x, player.y)

    -- Shift player2 if exists
    if player2 then
        player2.x = player2.x + shift_x
        player2.y = player2.y + shift_y
        player2.collider:setPosition(player2.x, player2.y)
    end

    -- shift base
    base.x = base.x + shift_x
    base.y = base.y + shift_y
    base.collider:setPosition(base.x, base.y)

    -- shift base walls
    --[[
    --for _, block in ipairs(base_walls) do
        print('before', block.x, block.y)
        block.x = block.x + shift_x
        block.y = block.y + shift_y
        print('after', block.x, block.y)
        block.collider:setPosition(block.x, block.y)
    end
    --]]

    -- Shift enemies
    for _, e in ipairs(enemies) do
        e.x = e.x + shift_x
        e.y = e.y + shift_y
        e.collider:setPosition(e.x, e.y)
    end

    -- Shift bullets
    for _, b in ipairs(bullets) do
        b.x = b.x + shift_x
        b.y = b.y + shift_y
        b.collider:setPosition(b.x, b.y)
    end

    for _, b in ipairs(enemy_bullets) do
        b.x = b.x + shift_x
        b.y = b.y + shift_y
        b.collider:setPosition(b.x, b.y)
    end

    -- Shift pickups
    for _, p in ipairs(pickups) do
        p.x = p.x + shift_x
        p.y = p.y + shift_y
        p.collider:setPosition(p.x, p.y)
    end

    -- Shift camera
    camera.x = camera.x + shift_x
    camera.y = camera.y + shift_y

    -- shift particles
    for i = #active_particle_systems, 1, -1 do
        local ps_data = active_particle_systems[i]
        local ps_x, ps_y = ps_data.system:getPosition()
        ps_data.system:setPosition(ps_x + shift_x, ps_y + shift_y)
    end

    local function shiftTrack(track_points)
        for i = 1, #track_points do
            local current_point = track_points[i]
            current_point.x = current_point.x + shift_x
            current_point.y = current_point.y + shift_y
        end
    end

    -- shift player trails
    shiftTrack(tank_trails.player_trail.left_track)
    shiftTrack(tank_trails.player_trail.right_track)

    -- shift enemy trails
    for _, enemy_trail in pairs(tank_trails.enemy_trails) do
        shiftTrack(enemy_trail.left_track)
        shiftTrack(enemy_trail.right_track)
    end

    -- Shift spawn locations
    --for _, loc in ipairs(spawn_locations) do
        --loc.x = loc.x + orig_width_in_cells * (expand_size - 1) / 2
        --loc.y = loc.y + orig_height_in_cells * (expand_size - 1) / 2
    --end

    -- Shift existing map objects and clear their colliders for lazy loading
    local function shiftCentralRegion(orig_width_in_cells, orig_height_in_cells)
        local new_grid = {}
        for x_cell, col in pairs(map_objects) do
            for y_cell, sub_grid_blocks in pairs(col) do

                local new_x_cell = x_cell + orig_width_in_cells * (expand_size - 1) / 2
                local new_y_cell = y_cell + orig_height_in_cells * (expand_size - 1) / 2

                for _, block in ipairs(sub_grid_blocks) do

                    block.x = block.x + shift_x
                    block.y = block.y + shift_y

                    -- Keep existing colliders active for now, lazy system will manage them
                    if block.collider then
                        block.collider:setPosition(block.x + cell_size / 2, block.y + cell_size / 2)
                    end
                end
                new_grid[new_x_cell] = new_grid[new_x_cell] or {}
                new_grid[new_x_cell][new_y_cell] = sub_grid_blocks
            end
        end
        map_objects = new_grid
    end

    shiftCentralRegion(orig_width_in_cells, orig_height_in_cells)

    -- Clear old borders, add new
    top_border:destroy()
    bottom_border:destroy()
    left_border:destroy()
    right_border:destroy()
    Map.addBorder()



    -- add spawn points to new expanded worlds
    local new_spawn_locations = {}
    for gx = 0, expand_size - 1 do
        for gy = 0, expand_size - 1 do
            if not (gx == (expand_size - 1) / 2 and gy == (expand_size - 1) / 2) then
                for _, old_loc in ipairs(spawn_locations) do
                    local new_x = gx * orig_width_in_cells + old_loc.x
                    local new_y = gy * orig_height_in_cells + old_loc.y
                    table.insert(new_spawn_locations, {x = new_x, y = new_y})
                end
            end
        end
    end
    spawn_locations = new_spawn_locations

    -- Generate new map data WITHOUT creating colliders immediately
    for gx = 0, expand_size - 1 do
        for gy = 0, expand_size - 1 do
            if not (gx == (expand_size - 1) / 2 and gy == (expand_size - 1) / 2) then
                Map.createMap(gx, gy, orig_width_in_cells, orig_height_in_cells)
            end
        end
    end


    -- Initialize active colliders system
    active_colliders = {}
    Map.updateActiveColliders()
end


function Map.BreakBrick(bullet, block)
    if not block then return end

    local grid_x = block.x / cell_size
    local grid_y = block.y / cell_size

    local axis, from_side, third

    --local vx, vy = bullet.collider:getLinearVelocity()
    local vx = bullet.vx
    local vy = bullet.vy

    if math.abs(vx) > math.abs(vy) then
        axis = 'x'
        if bullet.x > block.x + block.sub_x + block.width / 2 then
            from_side = 'pos'
        else
            from_side = 'neg'
        end

        if bullet.y <= block.y + block.height / 3 then
            third = 1
        elseif bullet.y > block.y + block.height * 2 / 3 then
            third = 3
        else
            third = 2
        end
    else
        axis = 'y'
        if bullet.y > block.y + block.sub_y + block.height / 2 then
            from_side = 'pos'
        else
            from_side = 'neg'
        end

        if bullet.x <= block.x + block.width / 3 then
            third = 1
        elseif bullet.x > block.x + block.width * 2 / 3 then
            third = 3
        else
            third = 2
        end
    end

    local function getSubBrick(x, y, sub_x, sub_y, type)

        local width, height

        if type == 'brick_quarter' then
            width = cell_size / 2
            height = cell_size / 2
        elseif type == 'brick_quarter_top' then
            width = cell_size / 2
            height = cell_size / 4
        elseif type == 'brick_quarter_bottom' then
            width = cell_size / 2
            height = cell_size / 4
        elseif type == 'brick_quarter_left' then
            width = cell_size / 4
            height = cell_size / 2
        elseif type == 'brick_quarter_right' then
            width = cell_size / 4
            height = cell_size / 2
        end

        local new_block = {
            x = x,
            y = y,
            sub_x = sub_x,
            sub_y = sub_y,
            width = width,
            height = height,
            type = type,
            is_full_block = false,
            collider = nil  -- Will be created on demand
        }

        return new_block
    end


    local sub_grid_blocks = map_objects[grid_x][grid_y]

    if block.is_full_block then
        local new_sub_grid_blocks = {}

        -- break into 4 quarters
        if axis == 'x' and from_side == 'pos' then

            local new_block = getSubBrick(block.x, block.y, 0, 0, 'brick_quarter')
            table.insert(new_sub_grid_blocks, new_block)

            local new_block = getSubBrick(block.x, block.y, 0, cell_size / 2, 'brick_quarter')
            table.insert(new_sub_grid_blocks, new_block)

            if third == 1 then
                local new_block = getSubBrick(block.x, block.y, cell_size / 2, 0, 'brick_quarter_left')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 2, 'brick_quarter')
                table.insert(new_sub_grid_blocks, new_block)

            elseif third == 2 then

                local new_block = getSubBrick(block.x, block.y, cell_size / 2, 0, 'brick_quarter_left')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 2, 'brick_quarter_left')
                table.insert(new_sub_grid_blocks, new_block)

            elseif third == 3 then

                local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 2, 'brick_quarter_left')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, cell_size / 2, 0, 'brick_quarter')
                table.insert(new_sub_grid_blocks, new_block)
            end

        elseif axis == 'x' and from_side == 'neg' then

            local new_block = getSubBrick(block.x, block.y, cell_size / 2, 0, 'brick_quarter')
            table.insert(new_sub_grid_blocks, new_block)

            local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 2, 'brick_quarter')
            table.insert(new_sub_grid_blocks, new_block)

            if third == 1 then
                local new_block = getSubBrick(block.x, block.y, cell_size / 4, 0, 'brick_quarter_right')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, 0, cell_size / 2, 'brick_quarter')
                table.insert(new_sub_grid_blocks, new_block)

            elseif third == 2 then

                local new_block = getSubBrick(block.x, block.y, cell_size / 4, 0, 'brick_quarter_right')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, cell_size / 4, cell_size / 2, 'brick_quarter_right')
                table.insert(new_sub_grid_blocks, new_block)

            elseif third == 3 then

                local new_block = getSubBrick(block.x, block.y, cell_size / 4, cell_size / 2, 'brick_quarter_right')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, 0, 0, 'brick_quarter')
                table.insert(new_sub_grid_blocks, new_block)
            end

        elseif axis == 'y' and from_side == 'neg' then

            local new_block = getSubBrick(block.x, block.y, 0, cell_size / 2, 'brick_quarter')
            table.insert(new_sub_grid_blocks, new_block)

            local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 2, 'brick_quarter')
            table.insert(new_sub_grid_blocks, new_block)

            if third == 1 then
                local new_block = getSubBrick(block.x, block.y, 0, cell_size / 4, 'brick_quarter_bottom')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, cell_size / 2, 0, 'brick_quarter')
                table.insert(new_sub_grid_blocks, new_block)

            elseif third == 2 then

                local new_block = getSubBrick(block.x, block.y, 0, cell_size / 4, 'brick_quarter_bottom')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 4, 'brick_quarter_bottom')
                table.insert(new_sub_grid_blocks, new_block)

            elseif third == 3 then

                local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 4, 'brick_quarter_bottom')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, 0, 0, 'brick_quarter')
                table.insert(new_sub_grid_blocks, new_block)

            end


        elseif axis == 'y' and from_side == 'pos' then

            local new_block = getSubBrick(block.x, block.y, 0, 0, 'brick_quarter')
            table.insert(new_sub_grid_blocks, new_block)

            local new_block = getSubBrick(block.x, block.y, cell_size / 2, 0, 'brick_quarter')
            table.insert(new_sub_grid_blocks, new_block)

            if third == 1 then
                local new_block = getSubBrick(block.x, block.y, 0, cell_size / 2, 'brick_quarter_top')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 2, 'brick_quarter')
                table.insert(new_sub_grid_blocks, new_block)

            elseif third == 2 then

                local new_block = getSubBrick(block.x, block.y, 0, cell_size / 2, 'brick_quarter_top')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 2, 'brick_quarter_top')
                table.insert(new_sub_grid_blocks, new_block)

            elseif third == 3 then

                local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 2, 'brick_quarter_top')
                table.insert(new_sub_grid_blocks, new_block)

                local new_block = getSubBrick(block.x, block.y, 0, cell_size / 2, 'brick_quarter')
                table.insert(new_sub_grid_blocks, new_block)

            end
        end

        block.collider:destroy()
        map_objects[grid_x][grid_y] = new_sub_grid_blocks


    else
        -- not full block

        if block.type == 'brick_quarter' then

            local sub_x, sub_y

            -- find this sub block, del it
            for j = #sub_grid_blocks, 1, -1 do
                local subj = sub_grid_blocks[j]
                if subj == block then
                    sub_x = subj.sub_x
                    sub_y = subj.sub_y
                    table.remove(sub_grid_blocks, j)
                    break
                end
            end

            -- replace it with a half sized
            if axis == 'x' and from_side == 'pos' then
                local new_block = getSubBrick(block.x, block.y, sub_x, sub_y, 'brick_quarter_left')
                table.insert(sub_grid_blocks, new_block)

            elseif axis == 'x' and from_side == 'neg' then
                local new_block = getSubBrick(block.x, block.y, sub_x + cell_size / 4, sub_y, 'brick_quarter_right')
                table.insert(sub_grid_blocks, new_block)

            elseif axis == 'y' and from_side == 'pos' then
                local new_block = getSubBrick(block.x, block.y, sub_x, sub_y, 'brick_quarter_top')
                table.insert(sub_grid_blocks, new_block)

            elseif axis == 'y' and from_side == 'neg' then
                local new_block = getSubBrick(block.x, block.y, sub_x, sub_y + cell_size / 4, 'brick_quarter_bottom')
                table.insert(sub_grid_blocks, new_block)

            end

            block.collider:destroy()
            map_objects[grid_x][grid_y] = sub_grid_blocks

        end

    end
end


function Map.BreakSteel(block)

    local function getSubBrick(x, y, sub_x, sub_y)

        local width, height
        local new_block = {
            x = x,
            y = y,
            sub_x = sub_x,
            sub_y = sub_y,
            width = cell_size / 2,
            height = cell_size / 2,
            type = 'steel_quarter',
            is_full_block = false,
            collider = nil  -- Will be created on demand
        }

        return new_block
    end

    if block.is_full_block then
        local new_sub_grid_blocks = {}

        -- break into 4 quarters
        local new_block = getSubBrick(block.x, block.y, 0, 0)
        table.insert(new_sub_grid_blocks, new_block)

        local new_block = getSubBrick(block.x, block.y, 0, cell_size / 2)
        table.insert(new_sub_grid_blocks, new_block)

        local new_block = getSubBrick(block.x, block.y, cell_size / 2, 0)
        table.insert(new_sub_grid_blocks, new_block)

        local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 2)
        table.insert(new_sub_grid_blocks, new_block)

        return new_sub_grid_blocks

    end
end


function Map.BreakHalfBrickBlock(block)

    local function getSubBrick(x, y, sub_x, sub_y)

        local width, height
        local new_block = {
            x = x,
            y = y,
            sub_x = sub_x,
            sub_y = sub_y,
            width = cell_size / 2,
            height = cell_size / 2,
            type = 'brick_quarter',
            is_full_block = false,
            collider = nil  -- Will be created on demand
        }

        return new_block
    end

    local new_sub_grid_blocks = {}

    if block.type == 'brick_right' then

        -- break into 2 quarters
        local new_block = getSubBrick(block.x, block.y, cell_size / 2, 0)
        table.insert(new_sub_grid_blocks, new_block)

        local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 2)
        table.insert(new_sub_grid_blocks, new_block)

    elseif block.type == 'brick_left' then

        local new_block = getSubBrick(block.x, block.y, 0, 0)
        table.insert(new_sub_grid_blocks, new_block)

        local new_block = getSubBrick(block.x, block.y, 0, cell_size / 2)
        table.insert(new_sub_grid_blocks, new_block)

    elseif block.type == 'brick_top' then

        local new_block = getSubBrick(block.x, block.y, 0, 0)
        table.insert(new_sub_grid_blocks, new_block)

        local new_block = getSubBrick(block.x, block.y, cell_size / 2, 0)
        table.insert(new_sub_grid_blocks, new_block)

    elseif block.type == 'brick_bottom' then

        local new_block = getSubBrick(block.x, block.y, 0, cell_size / 2)
        table.insert(new_sub_grid_blocks, new_block)

        local new_block = getSubBrick(block.x, block.y, cell_size / 2, cell_size / 2)
        table.insert(new_sub_grid_blocks, new_block)
    end

    return new_sub_grid_blocks
end


function Map.destroyBlock(block)
    if not block then return end

    local x_cell = math.floor(block.x / cell_size)
    local y_cell = math.floor(block.y / cell_size)
    if map_objects[x_cell] then
        if map_objects[x_cell][y_cell] then
            local sub_grid_blocks = map_objects[x_cell][y_cell]
            if #sub_grid_blocks == 0 then
                map_objects[x_cell][y_cell] = nil
            end

            for i = #sub_grid_blocks, 1, -1 do
                local subi = sub_grid_blocks[i]
                if subi == block then
                    table.remove(sub_grid_blocks, i)
                end
            end
        end
    end
    if block.collider and not block.collider:isDestroyed() then
        block.collider:destroy()
    end
end


return Map
