local Audio = {}

function Audio.setupSound()
    sounds = {}
    sounds.player_shoot = love.audio.newSource("assets/cannon_fire.ogg", "static")
    sounds.enemy_shoot = love.audio.newSource("assets/cannon_fire.ogg", "static")
    --sounds.explosion = love.audio.newSource("assets/DeathFlash.flac", "static")
    sounds.score_tick = love.audio.newSource("assets/Battle City SFX (1).wav", "static")
    sounds.explosion = love.audio.newSource("assets/Battle City SFX (7).wav", "static")
    --sounds.metal_hit = love.audio.newSource("assets/blacksmith_1.wav", "static")
    sounds.metal_hit = love.audio.newSource("assets/Battle City SFX (2).wav", "static")
    sounds.brick_hit = love.audio.newSource("assets/Battle City SFX (6).wav", "static")
    sounds.pick_up = love.audio.newSource("assets/Battle City SFX (12).wav", "static")
    sounds.bonus = love.audio.newSource("assets/Battle City SFX (10).wav", "static")
    --sounds.player_hit = love.audio.newSource("assets/sounds/player_hit.wav", "static")
    --sounds.enemy_hit = love.audio.newSource("assets/sounds/enemy_hit.wav", "static")
    --sounds.enemy_spawn = love.audio.newSource("assets/sounds/enemy_spawn.wav", "static")
    --sounds.game_over = love.audio.newSource("assets/sounds/game_over.wav", "static")
    --sounds.victory = love.audio.newSource("assets/sounds/victory.wav", "static")
    -- Engine sounds for player tank
    sounds.tank_idle = love.audio.newSource("assets/Battle City SFX (17).wav", "stream")
    sounds.tank_moving = love.audio.newSource("assets/Battle City SFX (16).wav", "stream")
    sounds.life_pick_up = love.audio.newSource("assets/Battle City SFX (15).wav", "stream")
    sounds.enemy_tank_idle = love.audio.newSource("assets/Battle City SFX (17).wav", "stream")
    sounds.enemy_tank_moving = love.audio.newSource("assets/Battle City SFX (16).wav", "stream")
    sounds.stage_start = love.audio.newSource("assets/stage_start.mp3", "static")
    --
    -- Set volumes for sound effects
    sounds.player_shoot:setVolume(0.4)
    sounds.enemy_shoot:setVolume(0.4)
    sounds.explosion:setVolume(0.5)
    sounds.brick_hit:setVolume(0.5)
    sounds.metal_hit:setVolume(0.5)
    sounds.pick_up:setVolume(0.5)
    sounds.life_pick_up:setVolume(0.5)
    sounds.stage_start:setVolume(0.5)

    -- Configure engine sounds
    sounds.tank_idle:setLooping(true)
    sounds.tank_moving:setLooping(true)
    sounds.tank_idle:setVolume(0.3)
    sounds.tank_moving:setVolume(0.4)

    sound_manager = {
    active_sounds = {},
    last_played = {},
    max_concurrent = {
        player_shoot = 3,
        enemy_shoot = 4,
        explosion = 4,
        metal_hit = 4,
        brick_hit = 2,
        enemy_hit = 4,
        player_hit = 1
    },
    cooldowns = {
        metal_hit = 0.03,
        enemy_hit = 0.02,
        brick_hit = 0.05
    },
    volume_scaling = true
    }


    audio_config = {
        max_hearing_distance = 400,  -- Maximum distance to hear sounds
        min_volume = 0.0,           -- Minimum volume at max distance
        max_volume = 1.0,           -- Maximum volume at source
        falloff_curve = 2           -- How quickly volume drops (1=linear, 2=quadratic, etc.)
    }
end

function Audio.calculateDistanceVolume(source_x, source_y, listener_x, listener_y, base_volume)
    -- Calculate distance between source and listener
    local dx = source_x - listener_x
    local dy = source_y - listener_y
    local distance = math.sqrt(dx * dx + dy * dy)

    -- If beyond max hearing distance, return 0
    if distance >= audio_config.max_hearing_distance then
        return 0
    end

    -- Calculate volume falloff
    local distance_ratio = distance / audio_config.max_hearing_distance
    local volume_multiplier = 1.0 - math.pow(distance_ratio, audio_config.falloff_curve)

    -- Apply to base volume
    local final_volume = base_volume * volume_multiplier
    return math.max(audio_config.min_volume, final_volume)
end

function Audio.playSound(sound_name, x, y, force_play, base_volume_override)
    if not sounds[sound_name] then return end

    -- LAN: replicate this sound to the client
    if Network and Network.isHost() then
        Network.queueEvent({t = "snd", s = sound_name, x = x, y = y, f = force_play})
    end

    -- Use player position as listener
    if not player then return end
    local listener_x = player.x
    local listener_y = player.y

    -- If no position provided, play at full volume (UI sounds, etc.)
    local volume
    if x and y then
        local base_volume = base_volume_override or sounds[sound_name]:getVolume()
        volume = Audio.calculateDistanceVolume(x, y, listener_x, listener_y, base_volume)

        -- Don't play if volume would be too quiet
        if volume < 0.01 then
            return
        end
    else
        volume = sounds[sound_name]:getVolume()
    end

    -- Apply existing sound management logic
    local manager = sound_manager
    local now = love.timer.getTime()

    -- Check cooldown
    local cooldown = manager.cooldowns[sound_name] or 0
    if not force_play and manager.last_played[sound_name] and
       (now - manager.last_played[sound_name]) < cooldown then
        return
    end

    -- Clean up and limit concurrent instances (same as before)
    if manager.active_sounds[sound_name] then
        for i = #manager.active_sounds[sound_name], 1, -1 do
            if not manager.active_sounds[sound_name][i]:isPlaying() then
                table.remove(manager.active_sounds[sound_name], i)
            end
        end
    else
        manager.active_sounds[sound_name] = {}
    end

    local max_concurrent = manager.max_concurrent[sound_name] or 3
    if #manager.active_sounds[sound_name] >= max_concurrent then
        manager.active_sounds[sound_name][1]:stop()
        table.remove(manager.active_sounds[sound_name], 1)
    end

    -- Create sound with distance-based volume
    local sound_clone = sounds[sound_name]:clone()

    -- Apply volume scaling for multiple instances if needed
    if manager.volume_scaling and x and y then
        local active_count = #manager.active_sounds[sound_name] + 1
        volume = volume / math.sqrt(active_count)
    end

    sound_clone:setVolume(volume)
    sound_clone:play()

    table.insert(manager.active_sounds[sound_name], sound_clone)
    manager.last_played[sound_name] = now
end

function Audio.updateEngineSound(dt)
    -- Determine if player is moving
    local vx, vy = player.collider:getLinearVelocity()
    local is_moving = math.abs(vx) > 10 or math.abs(vy) > 10
    local target_state = is_moving and "moving" or "idle"

    -- Check if we need to change engine sound state
    if target_state ~= engine_state.current and not engine_state.is_fading then
        Audio.startEngineTransition(target_state)
    end

    -- Handle fading between engine sounds
    if engine_state.is_fading then
        engine_state.fade_timer = engine_state.fade_timer + dt
        local fade_progress = engine_state.fade_timer / engine_state.fade_duration

        if fade_progress >= 1.0 then
            -- Fade complete
            Audio.completeEngineTransition()
        else
            -- Update volumes during fade
            Audio.updateEngineFade(fade_progress)
        end
    end
end

function Audio.startEngineTransition(new_state)
    engine_state.is_fading = true
    engine_state.fade_timer = 0
    engine_state.next_state = new_state

    -- Start the new engine sound if it's not playing
    if new_state == "idle" and not sounds.tank_idle:isPlaying() then
        sounds.tank_idle:setVolume(0)
        sounds.tank_idle:play()
    elseif new_state == "moving" and not sounds.tank_moving:isPlaying() then
        sounds.tank_moving:setVolume(0)
        sounds.tank_moving:play()
    end
end

function Audio.updateEngineFade(progress)
    local fade_out_volume = (1.0 - progress)
    local fade_in_volume = progress

    if engine_state.current == "idle" and engine_state.next_state == "moving" then
        -- Fading from idle to moving
        sounds.tank_idle:setVolume(engine_state.target_idle_volume * fade_out_volume)
        sounds.tank_moving:setVolume(engine_state.target_moving_volume * fade_in_volume)
    elseif engine_state.current == "moving" and engine_state.next_state == "idle" then
        -- Fading from moving to idle
        sounds.tank_moving:setVolume(engine_state.target_moving_volume * fade_out_volume)
        sounds.tank_idle:setVolume(engine_state.target_idle_volume * fade_in_volume)
    end
end

function Audio.completeEngineTransition()
    -- Stop the old engine sound
    if engine_state.current == "idle" then
        sounds.tank_idle:stop()
    elseif engine_state.current == "moving" then
        sounds.tank_moving:stop()
    end

    -- Set the new engine sound to full volume
    if engine_state.next_state == "idle" then
        sounds.tank_idle:setVolume(engine_state.target_idle_volume)
    elseif engine_state.next_state == "moving" then
        sounds.tank_moving:setVolume(engine_state.target_moving_volume)
    end

    -- Update state
    engine_state.current = engine_state.next_state
    engine_state.is_fading = false
    engine_state.fade_timer = 0
end

function Audio.startEngineSound()
    -- Start with idle engine sound
    engine_state.current = "idle"
    sounds.tank_idle:setVolume(engine_state.target_idle_volume)
    sounds.tank_idle:play()
end

function Audio.stopEngineSound()
    sounds.tank_idle:stop()
    sounds.tank_moving:stop()
    engine_state.current = "stopped"
    engine_state.is_fading = false
end

function Audio.updateEnemyEngineSounds(dt)
    for i, enemy in ipairs(enemies) do
        -- Initialize enemy engine state if needed
        if not enemy_engine_states[i] then
            enemy_engine_states[i] = {
                idle_sound = sounds.enemy_tank_idle:clone(),
                moving_sound = sounds.enemy_tank_moving:clone(),
                current_state = "idle"
            }
            enemy_engine_states[i].idle_sound:setLooping(true)
            enemy_engine_states[i].moving_sound:setLooping(true)
        end

        local enemy_state = enemy_engine_states[i]
        local vx, vy = enemy.collider:getLinearVelocity()
        local is_moving = math.abs(vx) > 10 or math.abs(vy) > 10

        -- Calculate distance-based volume
        local lx, ly = player.x, player.y
        if player2 then
            lx = (player.x + player2.x) / 2
            ly = (player.y + player2.y) / 2
        end
        local distance_volume = Audio.calculateDistanceVolume(enemy.x, enemy.y, lx, ly, 0.2)

        if is_moving and enemy_state.current_state ~= "moving" then
            enemy_state.idle_sound:stop()
            enemy_state.moving_sound:setVolume(distance_volume)
            enemy_state.moving_sound:play()
            enemy_state.current_state = "moving"
        elseif not is_moving and enemy_state.current_state ~= "idle" then
            enemy_state.moving_sound:stop()
            enemy_state.idle_sound:setVolume(distance_volume * 0.5)  -- Idle quieter
            enemy_state.idle_sound:play()
            enemy_state.current_state = "idle"
        else
            -- Update volume for current sound
            if enemy_state.current_state == "moving" then
                enemy_state.moving_sound:setVolume(distance_volume)
            else
                enemy_state.idle_sound:setVolume(distance_volume * 0.5)
            end
        end
    end

    -- Clean up engine states for destroyed enemies
    for i = #enemy_engine_states, 1, -1 do
        if not enemies[i] then
            if enemy_engine_states[i] then
                enemy_engine_states[i].idle_sound:stop()
                enemy_engine_states[i].moving_sound:stop()
            end
            table.remove(enemy_engine_states, i)
        end
    end
end

return Audio
