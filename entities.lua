local Entities = {}

function Entities.resetGame(stage, player_level)

    world = wf.newWorld(0, 0, true)
    Map.initCollisionClasses()
    Map.addBorder()

    map_objects = {}

    enemies_spawned = 0
    enemies_defeated = 0
    enemy_color = 'silver'
    if stage == 2 then
        enemy_color = 'green'
    end

    local settings = stage_settings[stage] or stage_settings[#stage_settings]
    total_enemies_to_spawn = settings.total_enemies_to_spawn
    spawn_timer = settings.spawn_timer
    ori_spawn_timer = 5
    game_over = false
    game_won = false


    -- add base
    base = {}
    base.x = start_cell_x * cell_size + cell_size / 2
    base.y = start_cell_y * cell_size + cell_size / 2
    base.hp = 1
    base.collider = world:newRectangleCollider(base.x - cell_size / 2, base.y - cell_size / 2, cell_size, cell_size)
    base.collider:setFixedRotation(true)
    base.collider:setType('static')
    base.collider:setCollisionClass('Base')
    base.collider:setObject(base)


    player = Entities.spawnPlayer(false, player_level, 1)

    if num_players == 2 then
        player2 = Entities.spawnPlayer(false, player_level, 2)
    else
        player2 = nil
    end

    -- Reset and start engine sound
    Audio.stopEngineSound()
    engine_state.current = "idle"
    engine_state.is_fading = false
    engine_state.fade_timer = 0

    -- Start engine sound after a brief delay
    love.timer.sleep(0.1)  -- Small delay to ensure everything is set up
    Audio.startEngineSound()

    -- Create a table to track enemy engine states
    enemy_engine_states = {}


    bullets = {}
    enemy_bullets = {}
    enemies = {}
    spawn_effects = {}

    -- Reset visual effects
    active_particle_systems = {}
    damage_numbers = {}
    score_numbers = {}
    p1_kill_counts = {}
    p2_kill_counts = {}

    for ll in pairs(enemy_levels) do
        p1_kill_counts[ll] = 0
        p2_kill_counts[ll] = 0
    end

    spawn_locations = {
        {x = 0, y = 0},
        {x = math.floor(world_width_in_cells / 2), y = 0},
        {x = world_width_in_cells - 1, y = 0}
    }

    -- Try to load original stage data, fall back to random
    if not Map.createMapFromStageData(stage) then
        Map.createMap(0, 0, world_width_in_cells, world_height_in_cells)
    end

    -- build wall around base
    Map.buildBaseWalls()
    --loadCustomMap("t")

    -- clear tank trails
    tank_trails.player_trail = {left_track = {}, right_track = {}}
    tank_trails.player2_trail = {left_track = {}, right_track = {}}
    tank_trails.enemy_trails = {}

    pickups = {}
    drop_pickup_rate = 0.4

    is_freeze = false
    is_steel_wall = false

    you_win_timer = 5
    world_expanded = false

    gameover_label = {quad = ui_quads['gameover'],
        x = window_width / 2 - cell_size * 2,
        y = window_height,
        min_y = window_height * 0.4,
        vy = -250}

end


function Entities.spawnPlayer(is_respawn, player_level, player_number)
    player_number = player_number or 1

    local existing_tank = (player_number == 1) and player or player2
    local previous_hp

    if is_respawn and existing_tank then
        previous_hp = existing_tank.hp
        if existing_tank.collider and not existing_tank.collider:isDestroyed() then
            existing_tank.collider:destroy()
        end
    end

    local tank = {}
    tank.player_number = player_number
    tank.player = 'player'
    tank.angle = 0
    tank.level = player_level
    tank.frame = 0

    if player_number == 1 then
        tank.x = player_start_cell_x * cell_size + cell_size / 2
        tank.y = player_start_cell_y * cell_size + cell_size / 2
    else
        tank.x = player2_start_cell_x * cell_size + cell_size / 2
        tank.y = player2_start_cell_y * cell_size + cell_size / 2
    end

    tank.speed = player_levels[tank.level].move_speed
    tank.bullet_count = player_levels[tank.level].bullet_count
    tank.fire_timer = 0

    Entities.addShieldToPlayer(tank)

    tank.on_ice = false
    tank.ice_velocity = {x = 0, y = 0}
    tank.ice_friction = 0.85
    tank.fuel = fuel_config.max_fuel
    tank.fuel_warning_timer = 0

    if is_respawn then
        tank.hp = previous_hp
    else
        tank.hp = player_levels[tank.level].hp
    end

    tank.collider = world:newBSGRectangleCollider(tank.x, tank.y, tank_size, tank_size, 5)
    tank.collider:setFixedRotation(true)
    tank.collider:setCollisionClass('Player')
    tank.collider:setObject(tank)

    return tank
end

-- Key bindings for each player
local player_keys = {
    [1] = {up = 'up', down = 'down', left = 'left', right = 'right'},
    [2] = {up = 'w', down = 's', left = 'a', right = 'd'}
}

-- Returns true if the given direction key is currently held for the given tank.
-- For player2 on a LAN host, source from remote_keys instead of local keyboard.
local function isPlayerInputDown(tank, direction)
    if Network and Network.isHost() and tank.player_number == 2 then
        return remote_keys and remote_keys[direction] or false
    end
    local kmap = player_keys[tank.player_number] or player_keys[1]
    return love.keyboard.isDown(kmap[direction])
end

local function updateSinglePlayerMovement(tank, keys, dt)
    if tank.hp <= 0 then
        tank.collider:setLinearVelocity(0, 0)
        return
    end

    local vx = 0
    local vy = 0
    local is_trying_to_move = false

    -- Check if player is on ice
    local on_ice_now = false
    if tank.collider:enter('Ice') then
        on_ice_now = true
    end
    if tank.collider:stay('Ice') then
        on_ice_now = true
    end
    if tank.collider:exit('Ice') then
        on_ice_now = false
    end

    if isPlayerInputDown(tank, 'right') then
        vx = tank.speed
        tank.angle = math.pi/2
        is_trying_to_move = true
    end
    if isPlayerInputDown(tank, 'left') then
        vx = -1 * tank.speed
        tank.angle = -math.pi/2
        is_trying_to_move = true
    end
    if isPlayerInputDown(tank, 'down') then
        vy = tank.speed
        tank.angle = math.pi
        is_trying_to_move = true
    end
    if isPlayerInputDown(tank, 'up') then
        vy = -1 * tank.speed
        tank.angle = 0
        is_trying_to_move = true
    end

    -- Ice physics
    if on_ice_now then
        if is_trying_to_move then
            local ice_acceleration = 0.3
            tank.ice_velocity.x = tank.ice_velocity.x + vx * (1+ice_acceleration * dt)
            tank.ice_velocity.y = tank.ice_velocity.y + vy * (1+ice_acceleration * dt)

            local max_ice_speed = tank.speed * 2.5
            local ice_speed = math.sqrt(tank.ice_velocity.x^2 + tank.ice_velocity.y^2)
            if ice_speed > max_ice_speed then
                local scale = max_ice_speed / ice_speed
                tank.ice_velocity.x = tank.ice_velocity.x * scale
                tank.ice_velocity.y = tank.ice_velocity.y * scale
            end
        end

        tank.ice_velocity.x = tank.ice_velocity.x * tank.ice_friction
        tank.ice_velocity.y = tank.ice_velocity.y * tank.ice_friction

        if tank.fuel > 0 then
            tank.collider:setLinearVelocity(tank.ice_velocity.x, tank.ice_velocity.y)
        else
            tank.collider:setLinearVelocity(tank.ice_velocity.x * 0.1, tank.ice_velocity.y * 0.1)
        end
    else
        tank.ice_velocity.x = 0
        tank.ice_velocity.y = 0

        if tank.fuel > 0 then
            if is_trying_to_move then
                tank.fuel = math.max(0, tank.fuel - fuel_config.consumption_rate * dt)
                tank.collider:setLinearVelocity(vx, vy)
            else
                tank.fuel = math.max(0, tank.fuel - fuel_config.idle_consumption * dt)
                tank.collider:setLinearVelocity(0, 0)
            end
        else
            tank.collider:setLinearVelocity(vx * 0.1, vy * 0.1)
        end
    end

    tank.on_ice = on_ice_now
    tank.x = tank.collider:getX()
    tank.y = tank.collider:getY()

    if tank.fuel <= fuel_config.critical_fuel_threshold then
        tank.fuel_warning_timer = (tank.fuel_warning_timer + dt) % 1.0
    end

    tank.frame = math.floor((tank.frame + math.max(vx, vy) * dt) % 2)
    tank.fire_timer = tank.fire_timer - dt
end

function Entities.updatePlayerMovement(dt)

    if game_over then return end
    if game_state == 'stage_end' or game_state == 'stage_intro' then return end

    updateSinglePlayerMovement(player, player_keys[1], dt)

    if player2 then
        updateSinglePlayerMovement(player2, player_keys[2], dt)
    end

    -- LAN host: process remote fire requests for player2
    if Network and Network.isHost() and player2 and player2.hp > 0 then
        if Network.consumeRemoteFire() then
            Combat.playerFire(player2)
        end
    end

    for i = #scheduledShots, 1, -1 do
        local shot = scheduledShots[i]
        shot.delay = shot.delay - dt
        if shot.delay <= 0 then
            Combat.spawnBullet(shot.shooter, 'PlayerBullet')
            VFX.addMuzzleFlash(shot.shooter.x, shot.shooter.y, shot.shooter.angle)
            Audio.playSound("player_shoot")
            table.remove(scheduledShots, i)
        end
    end

    -- Update engine sound based on movement
    Audio.updateEngineSound(dt)
end

function Entities.updateEnemyMovement(dt)
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        if enemy.hp <= -1 then
            enemy.collider:destroy()
            table.remove(enemies, i)
        end
    end

    for _, enemy in ipairs(enemies) do

        enemy.x = enemy.collider:getX()
        enemy.y = enemy.collider:getY()

        if enemy.hp == 0 then
            -- Dead enemy - no movement, no fuel consumption
            enemy.collider:setType('static')
            enemy.collider:setLinearVelocity(0, 0)
        else

            if is_freeze then
                enemy.collider:setLinearVelocity(0, 0)
            else
                -- Consume idle fuel
                enemy.fuel = math.max(0, enemy.fuel - fuel_config.idle_consumption * dt)

                if enemy.fuel > 0 then
                    enemy.move_timer = (enemy.move_timer or 0) - dt
                    if enemy.move_timer <= 0 then
                        enemy.angle = math.random(0, 3) * (math.pi / 2)
                        enemy.move_timer = math.random(1, 3)
                    end

                    local move_speed = enemy.speed
                    local evx = math.cos(enemy.angle - math.pi/2) * move_speed
                    local evy = math.sin(enemy.angle - math.pi/2) * move_speed

                    -- Consume movement fuel
                    enemy.fuel = math.max(0, enemy.fuel - fuel_config.consumption_rate * dt)
                    enemy.collider:setLinearVelocity(evx, evy)
                    enemy.frame = math.floor((enemy.frame + math.max(evx, evy) * dt) % 2)
                else
                    -- Out of fuel - can't move
                    local move_speed = enemy.speed
                    local evx = math.cos(enemy.angle - math.pi/2) * move_speed
                    local evy = math.sin(enemy.angle - math.pi/2) * move_speed
                    enemy.collider:setLinearVelocity(evx * 0.1, evy * 0.1)
                    enemy.frame = math.floor((enemy.frame + math.max(evx, evy) * dt) % 2)
                end

                -- Shooting logic (enemies can still shoot without fuel)
                enemy.shoot_timer = (enemy.shoot_timer or 0) - dt
                if enemy.shoot_timer <= 0 then
                    --spawnBullet(enemy.x, enemy.y, enemy.angle, 'EnemyBullet')
                    Combat.spawnBullet(enemy, 'EnemyBullet')
                    Audio.playSound("enemy_shoot", enemy.x, enemy.y)
                    VFX.addMuzzleFlash(enemy.x, enemy.y, enemy.angle)
                    enemy.shoot_timer = math.random(1, 2)
                end

                -- Update fuel warning timer
                if enemy.fuel <= fuel_config.critical_fuel_threshold then
                    enemy.fuel_warning_timer = (enemy.fuel_warning_timer + dt) % 1.0
                end
            end
        end
    end

    Audio.updateEnemyEngineSounds(dt)
end

function Entities.updatePickups(dt)
    for i = #pickups, 1, -1 do
        local p = pickups[i]
        p.timer = p.timer - dt

        -- Player collision
        if p.collider:enter('Player') then
            -- Determine which player picked it up
            local collision_data = p.collider:getEnterCollisionData('Player')
            local picking_player = player
            local kill_counts = p1_kill_counts
            local score_key = 'player1_score'
            if collision_data and collision_data.collider:getObject() then
                local obj = collision_data.collider:getObject()
                if obj.player_number == 2 then
                    picking_player = player2
                    kill_counts = p2_kill_counts
                    score_key = 'player2_score'
                end
            end

            if p.type == 'FUEL' then
                local fuel_gained = math.min(fuel_config.refuel_rate, fuel_config.max_fuel - picking_player.fuel)
                picking_player.fuel = picking_player.fuel + fuel_gained
                VFX.addFuelGainNumber(picking_player.x, picking_player.y - 20, fuel_gained)

            elseif p.type == 'star' then
                Stages.changePlayerLevel(picking_player, 1)
                Audio.playSound('pick_up', picking_player.x, picking_player.y, true)

            elseif p.type == 'gun' then
                Stages.changePlayerLevel(picking_player, 4)
                Audio.playSound('pick_up', picking_player.x, picking_player.y, true)

            elseif p.type == 'life' then
                picking_player.hp = picking_player.hp + 1
                Audio.playSound('life_pick_up', picking_player.x, picking_player.y, true)

            elseif p.type == 'bomb' then
                for j = #enemies, 1, -1 do
                    local enemy = enemies[j]
                    Entities.addEnemyDeadEffects(enemy)
                    kill_counts[enemy.level] = kill_counts[enemy.level] + 1
                    stage_end.scores[score_key] = stage_end.scores[score_key] + enemy.score
                end

            elseif p.type == 'shield' then
                Entities.addShieldToPlayer(picking_player)

            elseif p.type == 'freeze' then
                is_freeze = true
                last_freeze_time = love.timer.getTime()

            elseif p.type == 'steel_wall' then
                if base_walls then
                    for j = #base_walls, 1, -1 do
                        local block = base_walls[j]
                        if block.collider and not block.collider:isDestroyed() then
                            block.collider:destroy()
                        end
                        table.remove(base_walls, j)
                    end
                end
                Map.buildBaseWalls()
                for j, block in ipairs(base_walls) do
                    local new_type = string.gsub(block.type, 'brick', 'steel')
                    block.type = new_type
                    block.collider:setCollisionClass('Steel')
                end
                is_steel_wall = true
                last_steel_wall_time = love.timer.getTime()
            end

            pickup_counts[p.type] = pickup_counts[p.type] + 1

            p.collider:destroy()
            table.remove(pickups, i)
        elseif p.timer <= 0 then
            p.collider:destroy()
            table.remove(pickups, i)
        end
    end
end

function Entities.updateShields(dt)
    for i = #shields, 1, -1 do
        local shield = shields[i]
        local owner = shield.owner
        if shield.timer <= 0 then
            owner.has_shield = nil
            table.remove(shields, i)
        end

        shield.timer = shield.timer - dt
    end
end

function Entities.updateEnemySpawners(dt)
    for i = #spawn_effects, 1, -1 do
        local effect = spawn_effects[i]; effect.timer = effect.timer - dt

        -- Update animation
        effect.animation_timer = effect.animation_timer + dt
        local frame_duration = 0.05  -- 4 frames over 1 second = 0.25 seconds per frame
        if effect.animation_timer >= frame_duration then
            effect.animation_timer = effect.animation_timer - frame_duration
            effect.current_frame = effect.current_frame + 1
            if effect.current_frame > 4 then
                effect.current_frame = 1  -- Loop animation
            end
        end

        if effect.timer < 0 then
            -- check if enemies is present
            for i = #enemies, 1, -1 do
                local e = enemies[i]
                if math.abs(e.x - effect.x) <= cell_size and
                    math.abs(e.y - effect.y) <= cell_size then
                    if e.hp == 0 then
                        e.collider:destroy()
                        table.remove(enemies, i)
                    else
                        -- delay spawn
                        effect.timer = effect.timer + 1
                    end
                end
            end

            local new_enemy = Entities.createEnemyWithFuel(effect.x, effect.y)
            table.insert(enemies, new_enemy)
            table.remove(spawn_effects, i)
        end
    end
end

function Entities.updateFreeze(dt)
    if is_freeze then
        local new_time = love.timer.getTime()
        if new_time - last_freeze_time >= freeze_time then
            last_freeze_time = new_time
            is_freeze = false
        end
    end
end

function Entities.updateSteelWall(dt)
    if is_steel_wall then
        local new_time = love.timer.getTime()

        -- blink effect
        local blink_seconds = 2

        if steel_wall_time > blink_seconds and
            new_time - last_steel_wall_time >= steel_wall_time - blink_seconds then
            local tt = new_time - last_steel_wall_time - steel_wall_time - blink_seconds
            local frame = math.floor(tt * 3) % 2   --- 3 fps

            for i, block in ipairs(base_walls) do
                local new_type = block.type
                if frame == 0 and string.sub(block.type, 1, #'brick') == 'brick' then
                    new_type = string.gsub(block.type, 'brick', 'steel')
                elseif frame == 1 and string.sub(block.type, 1, #'steel') == 'steel' then
                    new_type = string.gsub(block.type, 'steel', 'brick')
                end
                block.type = new_type
                block.collider:setCollisionClass('Steel')
            end
        end

        if new_time - last_steel_wall_time >= steel_wall_time then
            last_steel_wall_time = new_time
            is_steel_wall = false

            for i, block in ipairs(base_walls) do
                local new_type = string.gsub(block.type, 'steel', 'brick')
                block.type = new_type
                block.collider:setCollisionClass('Brick')
            end
        end
    end
end


function Entities.updateGameover(dt)
    gameover_label.y = math.max(gameover_label.min_y, gameover_label.y + gameover_label.vy * dt)
end


function Entities.addShieldToPlayer(player)
    local shield = {owner = player, timer = shield_time}
    table.insert(shields, shield)
    player.has_shield = true
end


function Entities.addEnemyDeadEffects(enemy)

    enemy.hp = 0
    enemies_defeated = enemies_defeated + 1
    --print('defeated', enemies_defeated, 'total', total_enemies_to_spawn)

    --addParticleEffect(enemy.x, enemy.y, "explosion")
    VFX.addParticleEffect(enemy.x, enemy.y, "smoke")
    VFX.addExplosion(enemy.x, enemy.y, 5)
    VFX.addScreenShake(0.3, 8)
    Audio.playSound("explosion", enemy.x, enemy.y, true)
    if enemy.has_pickup then
        Combat.dropPickup(enemy.x, enemy.y)
    end
end

function Entities.createEnemyWithFuel(x, y)

    local total_weight = 0
    local settings = stage_settings[stage] or stage_settings[#stage_settings]
    local level_chances = settings.enemy_level_chances
    local enemy_level

    for _, weight in ipairs(level_chances) do
        total_weight = total_weight + weight
    end

    local random_value = math.random() * total_weight
    local cumulative_weight = 0

    for i, weight in ipairs(level_chances) do
        cumulative_weight = cumulative_weight + weight
        if random_value <= cumulative_weight then
            enemy_level = i
            break
        end
    end

    --local enemy_level = math.random(1, #enemy_levels)
    local has_pickup = math.random() < drop_pickup_rate
    local new_enemy = {
        x = x,
        y = y,
        angle = math.pi,
        speed = enemy_levels[enemy_level].move_speed,
        hp = enemy_levels[enemy_level].hp,
        fuel = enemy_levels[enemy_level].max_fuel,
        fuel_warning_timer = 0,
        level = enemy_level,
        frame = 0,
        has_pickup = has_pickup,
        score = enemy_levels[enemy_level].score
    }

    new_enemy.on_ice = false
    new_enemy.ice_velocity = {x = 0, y = 0}
    new_enemy.ice_friction = 0.85

    new_enemy.collider = world:newBSGRectangleCollider(new_enemy.x, new_enemy.y, cell_size-3, cell_size-3, 5)
    new_enemy.collider:setFixedRotation(true)
    new_enemy.collider:setCollisionClass('Enemy')
    new_enemy.collider:setObject(new_enemy)

    return new_enemy
end


function Entities.spawnEnemies(dt)
    spawn_timer = spawn_timer - dt
    if spawn_timer < 0 and enemies_spawned < total_enemies_to_spawn then
        local spawn_point = spawn_locations[math.random(1, #spawn_locations)]

        -- check if enemies is present
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            if math.abs(e.x - spawn_point.x) <= cell_size and
                math.abs(e.y - spawn_point.y) <= cell_size then
                spawn_timer = spawn_timer + 1
                break
            end
        end

        table.insert(spawn_effects, {
            x = spawn_point.x * cell_size,
            y = spawn_point.y * cell_size,
            timer = 1,
            animation_timer = 0,        -- Add animation timing
            current_frame = 1           -- Add current frame tracking
        })
        enemies_spawned = enemies_spawned + 1
        --print('enemies_spawned',enemies_spawned,total_enemies_to_spawn)
        --spawn_timer = math.random(1, 3)
        spawn_timer = ori_spawn_timer

        --showGameMessage("new enemy", {1, 1, 0, 1}, 150, 1)
    end
end

return Entities
