
function love.load()

    -- load libs
    wf = require 'windfield'
    TextScroller = require('textscroller')

    -- load game modules (as globals so they can cross-reference each other)
    Assets = require('assets')
    Audio = require('audio')
    VFX = require('vfx')
    Map = require('map')
    Draw = require('draw')
    Editor = require('editor')
    Title = require('title')
    Stages = require('stages')
    Combat = require('combat')
    Entities = require('entities')
    Network = require('network')

    love.graphics.setDefaultFilter("nearest", "nearest") -- For pixel art

    -- global parameters
    debug = false
    bullet_speed = 450
    border_thickness = 10
    clear_radius_x = 2
    clear_radius_y = 2

    -- power-up timers
    shield_time = 5
    steel_wall_time = 10
    freeze_time = 5

    -- World and camera setup
    cell_size = 50
    tank_size = cell_size - 6
    world_width_in_cells = 13
    world_height_in_cells = 13
    world_width = world_width_in_cells * cell_size
    world_height = world_height_in_cells * cell_size
    window_width = love.graphics.getWidth()
    window_height = love.graphics.getHeight()

    love.window.setMode(window_width, window_height, {resizable=true})

    start_cell_x = math.floor(world_width_in_cells / 2)
    start_cell_y = world_height_in_cells - 1

    player_start_cell_x = start_cell_x - 2
    player_start_cell_y = start_cell_y

    player2_start_cell_x = start_cell_x + 1
    player2_start_cell_y = start_cell_y

    num_players = 1
    player2 = nil

    -- Engine sound state tracking
    engine_state = {
        current = "idle",  -- "idle", "moving", or "stopped"
        fade_duration = 0.3,  -- Time to fade between sounds
        fade_timer = 0,
        target_idle_volume = 0.3,
        target_moving_volume = 0.4,
        is_fading = false
    }

    -- Visual effects tables
    active_particle_systems = {}
    muzzle_flashes = {}
    damage_numbers = {}
    score_numbers = {}
    explosions = {}

    -- Game entity tables (re-initialized in resetGame, but client never calls that)
    bullets = {}
    enemy_bullets = {}
    enemies = {}
    pickups = {}
    spawn_effects = {}
    map_objects = {}
    p1_kill_counts = {}
    p2_kill_counts = {}
    enemy_color = 'silver'
    enemies_defeated = 0
    total_enemies_to_spawn = 0
    enemies_spawned = 0
    world_expanded = false
    is_freeze = false
    is_steel_wall = false
    game_over = false
    game_won = false

    scheduledShots = {}
    shields = {}

    -- Tank trail system configuration
    tank_trails = {
        player_trail = {left_track = {}, right_track = {}},
        enemy_trails = {},
        max_trail_points = 25000,        -- Maximum number of trail points per track
        trail_spacing = 6,            -- Minimum distance between trail points
        trail_duration = 30.0,         -- How long each trail point lasts (in seconds)
        trail_width = 4,              -- Width of each track line
        trail_alpha_start = 0.9,      -- Starting alpha for new trail points
        trail_alpha_end = 0.1,        -- Ending alpha for old trail points
        min_speed_threshold = 30,     -- Minimum speed to create trail points
        track_width = 20              -- Distance between left and right tracks
    }


    -- UI margin setup
    ui_margin_width = cell_size * 2
    --game_area_width = window_width - ui_margin_width  -- Available width for game viewport
    game_area_width = world_width

    camera = {
        x = 0,
        y = 0,
        width = game_area_width,  -- Use game area width instead of full window
        height = window_height,
        scroll_margin = cell_size * 5, -- Distance from edge before scrolling
        -- Screen shake properties
        shake_duration = 0,
        shake_magnitude = 0,
        shake_x = 0,
        shake_y = 0
    }

    retry_button = {x = game_area_width/2 - 75, y = window_height/2 - 75, width = 150, height = 50}

    -- player levels
    player_levels = {
        [1] = {
            move_speed = 100,
            bullet_speed = bullet_speed,
            bullet_count = 1,
            hp = 3,
            fire_timer = 1,
            max_fuel = 100
            },
        [2] = {
            move_speed = 110,
            bullet_speed = bullet_speed+10,
            bullet_count = 1,
            hp = 3,
            fire_timer = 0.8,
            max_fuel = 120
            },
        [3] = {
            move_speed = 110,
            bullet_speed = bullet_speed+10,
            bullet_count = 1,
            hp = 3,
            fire_timer = 0.6,
            max_fuel = 130
            },
        [4] = {
            move_speed = 100,
            bullet_speed = bullet_speed+20,
            bullet_count = 2,
            hp = 3,
            fire_timer = 0.3,
            max_fuel = 150
            }
    }

    -- enemy levels
    enemy_levels = {
        [1] = {
            move_speed = 100,
            bullet_speed = bullet_speed,
            bullet_count = 1,
            hp = 1,
            max_fuel = 100,
            score = 100
            },
        [2] = {
            move_speed = 150,
            bullet_speed = bullet_speed,
            bullet_count = 1,
            hp = 1,
            max_fuel = 110,
            score = 200
            },
        [3] = {
            move_speed = 120,
            bullet_speed = bullet_speed+10,
            bullet_count = 1,
            hp = 1,
            max_fuel = 120,
            score = 300
            },
        [4] = {
            move_speed = 110,
            bullet_speed = bullet_speed+20,
            bullet_count = 2,
            hp = 4,
            max_fuel = 130,
            score = 400
            }
    }


    pickup_types = {
        {type = 'shield',
         chance = 2,
        },
        {type = 'freeze',
         chance = 2,
        },
        {type = 'steel_wall',
         chance = 2,
        },
        {type = 'star',
         chance = 2,
        },
        {type = 'bomb',
         chance = 2,
        },
        {type = 'life',
         chance = 2,
        },
        {type = 'gun',
         chance = 1,
        },
    }

    stage_settings = {
        [1] = {
            total_enemies_to_spawn = 10,
            spawn_timer = 4,
            enemy_level_chances = {[1] = 2, [2] = 1, [3] = 0, [4] = 0}
        },
        [2] = {
            total_enemies_to_spawn = 12,
            spawn_timer = 4,
            enemy_level_chances = {[1] = 2, [2] = 1, [3] = 1, [4] = 0}
        },
        [3] = {
            total_enemies_to_spawn = 14,
            spawn_timer = 4,
            enemy_level_chances = {[1] = 2, [2] = 2, [3] = 1, [4] = 0}
        },
        [4] = {
            total_enemies_to_spawn = 16,
            spawn_timer = 3,
            enemy_level_chances = {[1] = 2, [2] = 2, [3] = 1, [4] = 1}
        },
        [5] = {
            total_enemies_to_spawn = 18,
            spawn_timer = 3,
            enemy_level_chances = {[1] = 2, [2] = 2, [3] = 2, [4] = 2}
        },
        [6] = {
            total_enemies_to_spawn = 20,
            spawn_timer = 3,
            enemy_level_chances = {[1] = 1, [2] = 2, [3] = 3, [4] = 3}
        },
    }

    pickup_weights = {}
    pickup_counts = {}

    for i, p in ipairs(pickup_types) do
        table.insert(pickup_weights, p.chance)
        pickup_counts[p.type] = 0
    end

    -- Game assets
    Assets.loadImages()

    -- Load sound effects
    Audio.setupSound()

    -- Initialize particle systems
    VFX.initializeParticleSystems()

    -- Lazy loading system for physics bodies
    -- Only create colliders for objects near the player
    active_colliders = {}
    ACTIVATION_DISTANCE = math.max(window_height, window_width) * 1.5 -- pixels
    DEACTIVATION_DISTANCE = ACTIVATION_DISTANCE * 1.5 -- slightly larger to prevent thrashing

    Map.initializeFuelSystem()

    font = love.graphics.newFont("assets/04B_21__.TTF", 32)

    -- scroller initialization
    newsScroller = TextScroller.new({
        texts = {},
        font = love.graphics.newFont(18),
        color = {0, 1, 0, 1}, -- green
        speed = 100,
        repetitions = 1,
        y = 15
    })

    stage = 1

    game_state = "game"  -- "title" or "game"
    game_state = "title"  -- "title" or "game"
    playing_custom_map = false

    stage_intro = {
        timer = 0,
        duration = 5,  -- Show for 2.5 seconds
        current_stage = 1
    }

    stage_end = {
        timer = 0,
        current_row = 0,  -- Which row is currently being shown (0 = none, 1-5 = rows)
        row_duration = 1.0,  -- Time to show each row
        pause_duration = 4.0,  -- Pause after all rows shown
        total_duration = 0,
        is_pausing = false,
        score_tick_duration = 0.15,

        -- Score data for the completed stage
        scores = {
            hi_score = 0,
            stage_number = 1,
            player1_score = 0,
            player2_score = 0,

            -- Tank kill counts and scores for each type
            tank_data = {
                {kills_p1 = 0, kills_p2 = 0, points = 100, level = 1, color = 'silver'},  -- Basic tank
                {kills_p1 = 0, kills_p2 = 0, points = 200, level = 2, color = 'silver'},   -- Fast tank
                {kills_p1 = 0, kills_p2 = 0, points = 300, level = 3, color = 'silver'},     -- Power tank
                {kills_p1 = 0, kills_p2 = 0, points = 400, level = 4, color = 'silver'}     -- Armor tank
            },

            bonus_points = 1000
        },
        durations = {},
        counts = {},
        has_bonus = false
    }

    construction = {
        cursor_x = 0,  -- Grid position
        cursor_y = 0,
        selected_block_index = 1,
        available_blocks = {
            "steel", "steel_bottom", "steel_right", "steel_left", "steel_top",
            "brick", "brick_right", "brick_left",
            "brick_top", "brick_bottom", "water", "ice", "grass"
        },
        preview_block = nil,  -- Block shown under cursor
        is_active = false,
        save_prompt = {
            active = false,
            text = "",
            cursor_blink = 0,
            cursor_visible = true
        }
    }

    title_screen = {
        image_y = 0,
        image_target_y = 0,
        image_speed = 200,
        menu_visible = false,
        menu_alpha = 0,
        cursor_position = 1,  -- 1, 2, 3, or 4
        menu_options = {
            "1 PLAYER",
            "2 PLAYERS",
            "HOST LAN",
            "JOIN LAN",
            "CONSTRUCTION",
            "CUSTOM MAP"
        },
        cursor_blink_timer = 0,
        cursor_visible = true
    }

    lan_menu = {
        active = false,
        mode = nil,            -- "host", "ip_entry", "client", "error"
        ip_text = "",
        cursor_blink_timer = 0,
        cursor_visible = true
    }

    -- Add new state for custom map selection
    custom_map_menu = {
        active = false,
        cursor_position = 1,
        cursor_blink_timer = 0,
        cursor_visible = true,
        available_maps = {},
        scroll_offset = 0,
        max_visible = 10  -- Maximum maps to show at once
    }

    starting_player_level = 2
    --resetGame(stage, starting_player_level)
    Title.loadTitlePage()

end

function love.update(dt)

    if game_state == "title" then
        Title.updateTitleScreen(dt)
        return
    elseif game_state == "construction" then
        Editor.updateConstruction(dt)
        return
    end

    -- LAN: poll networking every frame regardless of game state
    if Network.isOn() then
        Network.poll()
    end

    -- LAN client: render-only mode. Apply latest snapshot, send input.
    if Network.isClient() then
        Network.applySnapshot()
        Network.sendInput(dt)
        VFX.updateCamera(dt)
        VFX.updateVisualEffects(dt)
        VFX.updateExplosions(dt)
        -- Skip tank trails: they read collider velocity, which the client doesn't have
        newsScroller:update(dt)
        return
    end

    if game_state == "stage_intro" then
        Stages.updateStageIntro(dt)
        return
    elseif game_state == "stage_end" then
        Stages.updateStageEnd(dt)
        return
    end

    if game_won then
        you_win_timer = you_win_timer - dt
    end

    if base.hp <= 0 then
        game_over = true
    end

    if game_won and not world_expanded and you_win_timer <= 0 then
        Stages.completeStage()
        return
    end

    if game_over then
        -- Stop engine sounds when game ends
        if engine_state.current ~= "stopped" then
            Audio.stopEngineSound()
        end
        Entities.updateGameover(dt)
    end

    if not world then return end
    world:update(dt)

    -- player movement
    Entities.updatePlayerMovement(dt)

    -- enemies movement
    Entities.updateEnemyMovement(dt)

    -- bullets
    Combat.updatePlayerBullets(dt)
    Combat.updateEnemyBullets(dt)

    -- update pickups
    Entities.updatePickups(dt)

    -- Update active colliders every few frames to reduce overhead
    if love.timer.getTime() % 0.1 < dt then -- Update ~10 times per second
        Map.updateActiveColliders()
    end

    -- spawn enemies
    Entities.spawnEnemies(dt)

    -- update shield power-up
    Entities.updateShields(dt)

    -- update freeze power-up
    Entities.updateFreeze(dt)

    -- update steel wall power-up
    Entities.updateSteelWall(dt)

    -- camera
    VFX.updateCamera(dt)

    -- visuals
    Entities.updateEnemySpawners(dt)
    VFX.updateVisualEffects(dt)
    VFX.updateExplosions(dt)
    VFX.updateTankTrails(dt)
    --

    -- check game over
    if player.hp <= 0 then
        if num_players == 1 or (player2 and player2.hp <= 0) then
            game_over = true
        end
    end
    if enemies_defeated == total_enemies_to_spawn then game_won = true end

    -- Add scroller updates
    --gameScroller:update(dt)
    newsScroller:update(dt)

    -- LAN host: broadcast world state to client
    if Network.isHost() then
        Network.broadcastSnapshot(dt)
    end

end

function love.textinput(text)
    if game_state == "title" then
        if Title.handleLANTextInput then
            Title.handleLANTextInput(text)
        end
    end
end

function love.draw()

    if game_state == "title" then
        Draw.drawTitleScreen()
        return
    elseif game_state == "construction" then
        Editor.drawConstruction()
        return
    elseif game_state == "stage_intro" then
        Draw.drawStageIntro()
        return
    elseif game_state == "stage_end" then
        Draw.drawStageEnd()
        return
    end

    love.graphics.setBackgroundColor(0.4, 0.4, 0.4)


    local world_screen_x = -camera.x + camera.shake_x
    local world_screen_y = -camera.y + camera.shake_y

    -- set scissor around the visible world area
    love.graphics.setScissor(world_screen_x, world_screen_y, world_width, world_height)

    -- fill that with black
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", world_screen_x, world_screen_y, world_width, world_height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setScissor()

    love.graphics.push()
    -- Apply screen shake
    love.graphics.translate(-camera.x + camera.shake_x, -camera.y + camera.shake_y)

    if world and debug then
        world:draw()
    end

    -- draw map borders
    Draw.drawBorder()

    -- draw base
    Draw.drawBase()

    -- draw background map objects
    Draw.drawMapObjects(false)

    -- draw tank trails
    VFX.drawTankTrails()

    -- draw tanks
    Draw.drawPlayerTanks()

    Draw.drawEnemyTanks()

    -- draw foreground map objects
    Draw.drawMapObjects(true)


    -- draw bullets
    Draw.drawBullets()

    -- Draw particle systems
    VFX.drawParticleEffects()

    VFX.drawExplosions()

    -- Draw damage numbers
    VFX.drawDamageNumbers()

    -- Draw score numbers
    VFX.drawScoreNumbers()

    -- draw pickups
    Draw.drawPickups()

    -- Draw spawn effects
    VFX.drawSpawnEffects()

    love.graphics.pop()

    -- Clear scissor test for UI
    love.graphics.setScissor()

    -- draw UI
    Draw.drawUI()

    -- draw game over
    if game_over then
        Draw.drawGameOver()
    elseif game_won then
        -- placeholder for win screen
    end

    --gameScroller:draw()
    newsScroller:draw()

end

function love.keypressed(key)

    if game_state == "title" then
        Title.handleTitleInput(key)
        return
    elseif game_state == "construction" then
        Editor.handleConstructionInput(key)
        return
    end

    if key == "escape" and stage_intro.timer > stage_intro.duration then
        Audio.stopEngineSound()
        if Network.isOn() then Network.shutdown() end
        Title.loadTitlePage()
        return
    end

    -- LAN client: send fire request to host instead of firing locally
    if Network.isClient() then
        if key == "return" or key == "space" or key == 'f' then
            Network.requestFire()
        end
        return
    end

    --if game_over and key == "r" then resetGame() end
    if game_over then return end

    --
    if key == "return" or key == "space" then
        if player ~= nil and player.hp > 0 then
            Combat.playerFire(player)
        end

    elseif key == 'f' then
        if player2 ~= nil and player2.hp > 0 then
            Combat.playerFire(player2)
        end

    elseif key == 'e' then
        for i, block in ipairs(base_walls) do
            local new_type = string.gsub(block.type, 'brick', 'steel')
            block.type = new_type
            block.collider:setCollisionClass('Steel')
        end
    elseif key == 'o' then
        game_won = true
    end

end

function love.mousepressed(x, y, button)
    if game_over and button == 1 and x > retry_button.x and x < retry_button.x + retry_button.width and y > retry_button.y and y < retry_button.y + retry_button.height then
        Entities.resetGame()
    end
end
