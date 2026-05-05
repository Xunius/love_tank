local VFX = {}

function VFX.initializeParticleSystems()

    -- Create particle textures
    particle_texture = love.graphics.newCanvas(8, 8)
    love.graphics.setCanvas(particle_texture)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", 4, 4, 4)
    love.graphics.setCanvas()

    -- Spark effect for metal hits and enemy damage
    spark_system = love.graphics.newParticleSystem(particle_texture, 32)
    spark_system:setParticleLifetime(0.01, 0.1)
    spark_system:setEmissionRate(0)
    spark_system:setSizeVariation(1)
    spark_system:setLinearAcceleration(-50, -50, 50, 50)
    spark_system:setColors(1, 1, 0, 1, 1, 0.8, 0, 0.8, 1, 0.5, 0, 0) -- Yellow to red fade
    spark_system:setSpeed(120, 200)
    spark_system:setSpread(math.pi * 2)
    spark_system:setSizes(0.5, 1, 0.2)

    -- Explosion effect for enemy destruction
    explosion_system = love.graphics.newParticleSystem(particle_texture, 64)
    explosion_system:setParticleLifetime(0.1, 1.4)
    explosion_system:setEmissionRate(2)
    explosion_system:setSizeVariation(1)
    explosion_system:setLinearAcceleration(-10, 10, -10, 10) -- Gravity effect
    explosion_system:setTangentialAcceleration(0, 100)
    explosion_system:setColors(1, 0.8, 0, 1, 1, 0.4, 0, 0.8, 0.5, 0.2, 0.1, 0.4, 0, 0, 0, 0) -- Orange to black
    explosion_system:setSpeed(80, 100)
    explosion_system:setSpread(math.pi * 2)
    explosion_system:setSizes(0.8, 1.5, 0.1)
    explosion_system:setRadialAcceleration(10, 30) -- Expand outward then slow

    -- smoke effect for enemy destruction
    smoke_system = love.graphics.newParticleSystem(particle_texture, 80)
    smoke_system:setEmitterLifetime(60)
    smoke_system:setParticleLifetime(3.4, 6.0)
    smoke_system:setEmissionRate(2)
    smoke_system:setSizeVariation(1)
    smoke_system:setLinearAcceleration(0, 0, 0, 0) -- Light gravity
    smoke_system:setColors(0.9, 0.6, 0.6, 0.8, 0.7, 0.6, 0.7, 0.5, 0.5, 0.4, 0.4, 0.4) -- Brown to transparent
    smoke_system:setSpeed(2, 4)
    smoke_system:setSpread(2*math.pi)
    smoke_system:setRadialAcceleration(2, 4) -- Expand outward then slow
    smoke_system:setSizes(1.6, 2.6, 2.0, 1) -- Grow then shrink

    -- Dust effect for brick destruction
    dust_system = love.graphics.newParticleSystem(particle_texture, 24)
    dust_system:setParticleLifetime(0.4, 2.0)
    dust_system:setEmissionRate(0)
    dust_system:setSizeVariation(1)
    dust_system:setLinearAcceleration(-20, 20, 20, 20) -- Light gravity
    dust_system:setColors(0.7, 0.6, 0.5, 0.8, 0.5, 0.4, 0.3, 0.4, 0.3, 0.2, 0.1, 0) -- Brown to transparent
    dust_system:setSpeed(10, 20)
    dust_system:setSpread(2*math.pi)
    dust_system:setSizes(1.6, 2.6, 2.0, 1) -- Grow then shrink

    -- Muzzle flash effect
    muzzle_system = love.graphics.newParticleSystem(particle_texture, 16)
    muzzle_system:setParticleLifetime(0.05, 0.15)
    muzzle_system:setEmissionRate(300)
    muzzle_system:setSizeVariation(1)
    muzzle_system:setColors(1, 1, 0.8, 1, 1, 0.8, 0.4, 0.8, 1, 0.5, 0, 0) -- Bright yellow-white
    muzzle_system:setSpeed(20, 100)
    muzzle_system:setSpread(math.pi / 4) -- Narrow cone
    muzzle_system:setSizes(0.3, 0.8, 0.1)
    muzzle_system:setLinearDamping(5) -- Quick slowdown
end

function VFX.updateCamera(dt)
    -- Update screen shake
    if camera.shake_duration > 0 then
        camera.shake_duration = camera.shake_duration - dt
        camera.shake_x = (math.random() - 0.5) * camera.shake_magnitude
        camera.shake_y = (math.random() - 0.5) * camera.shake_magnitude

        camera.shake_magnitude = camera.shake_magnitude * 0.9

        if camera.shake_duration <= 0 then
            camera.shake_x = 0
            camera.shake_y = 0
        end
    end

    -- Normal camera following
    if world_expanded then
        if player.x < camera.x + camera.scroll_margin then camera.x = player.x - camera.scroll_margin
        elseif player.x > camera.x + camera.width - camera.scroll_margin then camera.x = player.x - camera.width + camera.scroll_margin end
        if player.y < camera.y + camera.scroll_margin then camera.y = player.y - camera.scroll_margin
        elseif player.y > camera.y + camera.height - camera.scroll_margin then camera.y = player.y - camera.height + camera.scroll_margin end
    end
    --camera.x = math.max(0, math.min(camera.x, world_width - camera.width))
    --camera.y = math.max(0, math.min(camera.y, world_height - camera.height))
end

function VFX.updateVisualEffects(dt)
    -- Update active particle systems
    for i = #active_particle_systems, 1, -1 do
        local ps_data = active_particle_systems[i]
        ps_data.system:update(dt)
        ps_data.timer = ps_data.timer - dt

        -- Remove system if timer expired AND no particles are left
        if ps_data.timer <= 0 or ps_data.system:getCount() == 0 then
            table.remove(active_particle_systems, i)
        end
    end

    -- Update damage numbers
    for i = #damage_numbers, 1, -1 do
        local number = damage_numbers[i]
        number.timer = number.timer - dt
        number.y = number.y + number.vy * dt
        if number.timer <= 0 then
            table.remove(damage_numbers, i)
        end
    end

    -- Update score numbers
    for i = #score_numbers, 1, -1 do
        local number = score_numbers[i]
        number.timer = number.timer - dt
        number.y = number.y + number.vy * dt
        if number.timer <= 0 then
            table.remove(score_numbers, i)
        end
    end
end

function VFX.updateExplosions(dt)

    local animation_speed = 7

    for i = #explosions, 1, -1 do
        local exp = explosions[i]
        exp.timer = exp.timer + dt
        local frame = math.floor(exp.timer / exp.frame_duration) + 1

        if frame > exp.size then
            table.remove(explosions, i)
        else
            exp.frame = frame
        end
    end
end

function VFX.updateTankTrails(dt)
    -- Update player trail
    VFX.updateDualTrackTrail(player, tank_trails.player_trail, dt)

    -- Update enemy trails
    for i, enemy in ipairs(enemies) do
        -- Initialize enemy trail if it doesn't exist
        if not tank_trails.enemy_trails[i] then
            tank_trails.enemy_trails[i] = {left_track = {}, right_track = {}}
        end
        VFX.updateDualTrackTrail(enemy, tank_trails.enemy_trails[i], dt)
    end

    -- Clean up trails for destroyed enemies
    --for i = #tank_trails.enemy_trails, 1, -1 do
    --    if not enemies[i] then
    --        table.remove(tank_trails.enemy_trails, i)
    --    end
    --end
end

function VFX.updateDualTrackTrail(tank, trail_data, dt)
    local vx, vy = tank.collider:getLinearVelocity()
    local speed = math.sqrt(vx * vx + vy * vy)

    -- Only add trail points if tank is moving fast enough
    if speed > tank_trails.min_speed_threshold then
        -- Calculate the positions for left and right tracks
        local left_track_pos, right_track_pos = VFX.calculateTrackPositions(tank)

        -- Check if we need to add new trail points
        local should_add_point = true

        if #trail_data.left_track > 0 then
            local last_left = trail_data.left_track[#trail_data.left_track]
            local distance = math.sqrt((left_track_pos.x - last_left.x)^2 + (left_track_pos.y - last_left.y)^2)
            should_add_point = (distance >= tank_trails.trail_spacing) and (distance <= tank_trails.trail_spacing * 4)
        end

        if should_add_point then
            -- Add new trail points for both tracks
            table.insert(trail_data.left_track, {
                x = left_track_pos.x,
                y = left_track_pos.y,
                timer = tank_trails.trail_duration
            })

            table.insert(trail_data.right_track, {
                x = right_track_pos.x,
                y = right_track_pos.y,
                timer = tank_trails.trail_duration
            })

            -- Remove excess trail points
            while #trail_data.left_track > tank_trails.max_trail_points do
                table.remove(trail_data.left_track, 1)
                table.remove(trail_data.right_track, 1)
            end
        end
    end

    -- Update existing trail points for both tracks
    VFX.updateSingleTrackPoints(trail_data.left_track, dt)
    VFX.updateSingleTrackPoints(trail_data.right_track, dt)
end

function VFX.calculateTrackPositions(tank)
    -- Calculate perpendicular offset from tank center to track positions
    local track_offset = tank_trails.track_width / 2

    -- Get perpendicular direction to tank's facing direction
    local perp_angle = tank.angle
    local offset_x = math.cos(perp_angle) * track_offset
    local offset_y = math.sin(perp_angle) * track_offset

    -- Calculate left and right track positions
    local left_track = {
        x = tank.x - offset_x,
        y = tank.y - offset_y
    }

    local right_track = {
        x = tank.x + offset_x,
        y = tank.y + offset_y
    }

    return left_track, right_track
end

function VFX.updateSingleTrackPoints(track_points, dt)
    for i = #track_points, 1, -1 do
        track_points[i].timer = track_points[i].timer - dt
        if track_points[i].timer <= 0 then
            table.remove(track_points, i)
        end
    end
end

function VFX.showGameMessage(message, color, speed, repetitions)
    --newsScroller:setTexts({message})
    newsScroller:addText(message)
    if color then
        newsScroller:setColor(color[1], color[2], color[3], color[4] or 1)
    end
    if speed then
        newsScroller:setSpeed(speed)
    end
    if repetitions then
        newsScroller:setRepetitions(repetitions)
    end
    newsScroller:start()
end

function VFX.showMultipleMessages(messages, separator)
    if separator then
        newsScroller.separator = separator
    end
    newsScroller:setTexts(messages)
    newsScroller:start()
end

function VFX.addScreenShake(duration, magnitude)
    if Network and Network.isHost() then
        Network.queueEvent({t = "shk", d = duration, m = magnitude})
    end
    camera.shake_duration = duration
    camera.shake_magnitude = magnitude
end

function VFX.drawSpawnEffects()
    love.graphics.setColor(1, 1, 1, 1)
    for _, effect in ipairs(spawn_effects) do
        local quad = star_quads[effect.current_frame]

        -- Center the sprite on the spawn position
        local draw_x = effect.x + 3
        local draw_y = effect.y + 3

        -- Store current blend mode
        local old_blend_mode = love.graphics.getBlendMode()

        -- Set blend mode to make black pixels transparent
        love.graphics.setBlendMode("add")  -- or "screen" or "multiply"

        love.graphics.draw(spritesheet, quad, draw_x, draw_y, 0,
            0.7 * cell_size / full_sprite_width, 0.7 * cell_size / full_sprite_height)

        -- Restore original blend mode
        love.graphics.setBlendMode(old_blend_mode)
    end
end

function VFX.addParticleEffect(x, y, effect_type)
    if Network and Network.isHost() then
        Network.queueEvent({t = "par", x = x, y = y, k = effect_type})
    end

    local system
    local emit_count
    local timer

    if effect_type == "spark" then
        system = spark_system:clone()
        emit_count = 8
        timer = 0.2  -- Shorter timer for sparks
    elseif effect_type == "explosion" then
        system = explosion_system:clone()
        emit_count = 25
        timer = 0.25  -- Longer timer for explosions
    elseif effect_type == "dust" then
        system = dust_system:clone()
        emit_count = 12
        timer = 1.0  -- Longer timer for dust
    elseif effect_type == "smoke" then
        system = smoke_system:clone()
        emit_count = 9
        timer = 90  -- Longer timer for dust
    end

    if system then
        system:setPosition(x, y)
        system:emit(emit_count)

        table.insert(active_particle_systems, {
            system = system,
            timer = timer
        })
    end
end


function VFX.addExplosion(x, y, size)
    if Network and Network.isHost() then
        Network.queueEvent({t = "exp", x = x, y = y, sz = size})
    end
    -- size: 1, 2, 3, 4, 5
    table.insert(explosions, {x=x-cell_size/2,
        y=y-cell_size/2, size=size, frame=1, timer=0, frame_duration=0.08})
end


function VFX.addMuzzleFlash(x, y, angle)
    if Network and Network.isHost() then
        Network.queueEvent({t = "muz", x = x, y = y, a = angle})
    end
    local system = muzzle_system:clone()

    -- Calculate position at tank barrel
    local flash_x = x + math.cos(angle - math.pi/2) * (tank_size/2 + 5)
    local flash_y = y + math.sin(angle - math.pi/2) * (tank_size/2 + 5)

    system:setPosition(flash_x, flash_y)
    system:setDirection(angle - math.pi/2)
    system:emit(6)

    table.insert(active_particle_systems, {
        system = system,
        timer = 0.2
    })
end

function VFX.addDamageNumber(x, y, damage)
    if Network and Network.isHost() then
        Network.queueEvent({t = "dmg", x = x, y = y, n = damage})
    end
    local number = {
        x = x,
        y = y,
        damage = damage,
        timer = 1.0,
        vy = -50
    }
    table.insert(damage_numbers, number)
end

function VFX.addFuelGainNumber(x, y, fuel_amount)
    if Network and Network.isHost() then
        Network.queueEvent({t = "fue", x = x, y = y, n = fuel_amount})
    end
    local number = {
        x = x,
        y = y,
        fuel = fuel_amount,
        timer = 1.0,
        vy = -30,
        type = "fuel"
    }
    table.insert(damage_numbers, number)
end

function VFX.addScoreNumber(x, y, score)
    if Network and Network.isHost() then
        Network.queueEvent({t = "scr", x = x, y = y, n = score})
    end
    local number = {
        x = x,
        y = y,
        score = score,
        timer = 1.0,
        vy = -5
    }
    table.insert(score_numbers, number)
end

function VFX.drawParticleEffects()
    love.graphics.setColor(1, 1, 1, 1)
    for _, ps_data in ipairs(active_particle_systems) do
        love.graphics.draw(ps_data.system)
    end
end


function VFX.drawExplosions()

    love.graphics.setColor(1, 1, 1, 1)
    -- Store current blend mode
    local old_blend_mode = love.graphics.getBlendMode()

    -- Set blend mode to make black pixels transparent
    love.graphics.setBlendMode("add")  -- or "screen" or "multiply"

    for _, exp in ipairs(explosions) do
        local frame = exp.frame
        local x = exp.x
        local y = exp.y
        local offset_x, offset_y
        if frame <= 3 then
            offset_x = 0
            offset_y = 0
        else
            offset_x = cell_size / 8
            offset_y = cell_size / 8
        end

        local quad = explosion_quads[frame]
        love.graphics.draw(spritesheet, quad, x, y, 0, cell_size /
            full_sprite_width, cell_size / full_sprite_height, offset_x,
            offset_y)

    end
    -- Restore original blend mode
    love.graphics.setBlendMode(old_blend_mode)
end


function VFX.drawDamageNumbers()

    love.graphics.setFont(love.graphics.newFont(10))

    for _, number in ipairs(damage_numbers) do
        local alpha = number.timer / 1.0
        --love.graphics.setColor(1, 0, 0, alpha)
        --love.graphics.print("-" .. number.damage, number.x - 10, number.y)

        if number.type == "fuel" then
            love.graphics.setColor(1, 1, 0, alpha)  -- Yellow for fuel
            love.graphics.print("+" .. math.floor(number.fuel), number.x - 10, number.y)
        else
            love.graphics.setColor(1, 0, 0, alpha)  -- Red for damage
            love.graphics.print("-" .. number.damage, number.x - 10, number.y)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end


function VFX.drawScoreNumbers()
    for _, number in ipairs(score_numbers) do
        love.graphics.setColor(1, 1, 1)
        local s = tostring(number.score)
        local quad = ui_quads[s]
        love.graphics.draw(spritesheet, quad, number.x, number.y, 0,
            0.8 * cell_size / 16, 0.8 * cell_size / 16)
    end
end


function VFX.drawTankTrails()
    love.graphics.setLineWidth(tank_trails.trail_width)

    -- Draw player trails (both tracks)
    VFX.drawDualTrackTrail(tank_trails.player_trail, {0.6, 0.5, 0.5}) -- Green trails

    -- Draw enemy trails (both tracks)
    for _, enemy_trail in pairs(tank_trails.enemy_trails) do
        VFX.drawDualTrackTrail(enemy_trail, {0.6, 0.6, 0.5}) -- Red trails
    end

    -- Reset line width and color
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function VFX.drawDualTrackTrail(trail_data, base_color)
    -- Draw left track
    VFX.drawSingleTrackTrail(trail_data.left_track, base_color)
    -- Draw right track
    VFX.drawSingleTrackTrail(trail_data.right_track, base_color)
end

function VFX.drawSingleTrackTrail(track_points, base_color)
    if #track_points < 2 then return end

    -- Draw track as connected line segments with fading alpha
    for i = 1, #track_points - 1 do
        local current_point = track_points[i]
        local next_point = track_points[i + 1]

        -- Calculate alpha based on remaining time
        local alpha_progress = current_point.timer / tank_trails.trail_duration
        local alpha = tank_trails.trail_alpha_end +
                     (tank_trails.trail_alpha_start - tank_trails.trail_alpha_end) * alpha_progress

        love.graphics.setColor(base_color[1], base_color[2], base_color[3], alpha)
        love.graphics.line(current_point.x, current_point.y, next_point.x, next_point.y)
    end
end

return VFX
