local Title = {}

function Title.loadTitlePage()

    game_state = "title"

    -- Initialize title screen state
    title_screen.image_y = window_height  -- Start from bottom
    title_screen.image_target_y = 50      -- Stop near top
    title_screen.menu_visible = false
    title_screen.menu_alpha = 0
    title_screen.cursor_position = 1
    title_screen.cursor_blink_timer = 0
    title_screen.cursor_visible = true

end

function Title.handleTitleInput(key)

    if custom_map_menu.active then
        Editor.handleCustomMapInput(key)
        return
    end

    if lan_menu and lan_menu.active then
        Title.handleLANInput(key)
        return
    end

    if not title_screen.menu_visible or title_screen.menu_alpha < 1 then
        return  -- Don't handle input until menu is fully visible
    end

    if key == "up" then
        title_screen.cursor_position = title_screen.cursor_position - 1
        if title_screen.cursor_position < 1 then
            title_screen.cursor_position = #title_screen.menu_options
        end
        title_screen.cursor_blink_timer = 0
        title_screen.cursor_visible = true

    elseif key == "down" then
        title_screen.cursor_position = title_screen.cursor_position + 1
        if title_screen.cursor_position > #title_screen.menu_options then
            title_screen.cursor_position = 1
        end
        title_screen.cursor_blink_timer = 0
        title_screen.cursor_visible = true

    elseif key == "return" or key == "space" then
        local opt = title_screen.menu_options[title_screen.cursor_position]
        if opt == "1 PLAYER" then
            num_players = 1
            stage = 1
            Stages.loadStageIntro(stage)
        elseif opt == "2 PLAYERS" then
            num_players = 2
            stage = 1
            Stages.loadStageIntro(stage)
        elseif opt == "HOST LAN" then
            Title.startHosting()
        elseif opt == "JOIN LAN" then
            Title.startJoining()
        elseif opt == "CONSTRUCTION" then
            Editor.initConstructionMode()
        elseif opt == "CUSTOM MAP" then
            Editor.initCustomMapMenu()
        end
    end
end

function Title.startHosting()
    lan_menu.active = true
    lan_menu.mode = "host"
    lan_menu.ip_text = ""
    if not Network.startHost() then
        lan_menu.mode = "error"
    end
end

function Title.startJoining()
    lan_menu.active = true
    lan_menu.mode = "ip_entry"
    lan_menu.ip_text = lan_menu.ip_text ~= "" and lan_menu.ip_text or "127.0.0.1"
    lan_menu.cursor_blink_timer = 0
    lan_menu.cursor_visible = true
end

function Title.handleLANInput(key)
    if key == "escape" then
        Network.shutdown()
        lan_menu.active = false
        lan_menu.mode = nil
        return
    end

    if lan_menu.mode == "ip_entry" then
        if key == "backspace" then
            lan_menu.ip_text = lan_menu.ip_text:sub(1, -2)
        elseif key == "return" or key == "space" then
            if #lan_menu.ip_text > 0 then
                lan_menu.mode = "client"
                if not Network.startClient(lan_menu.ip_text) then
                    lan_menu.mode = "error"
                end
            end
        end
    end
end

function Title.handleLANTextInput(text)
    if not (lan_menu and lan_menu.active and lan_menu.mode == "ip_entry") then return end
    -- accept digits and dots only
    if text:match("[%d%.]") then
        lan_menu.ip_text = lan_menu.ip_text .. text
    end
end

function Title.updateTitleScreen(dt)

    -- LAN menu pulses cursor and polls network
    if lan_menu and lan_menu.active then
        lan_menu.cursor_blink_timer = lan_menu.cursor_blink_timer + dt
        if lan_menu.cursor_blink_timer >= 0.5 then
            lan_menu.cursor_visible = not lan_menu.cursor_visible
            lan_menu.cursor_blink_timer = 0
        end
        Network.poll()
        -- when host or client transitions out of "off", and Stages is loaded, the
        -- network module itself will trigger Stages.loadStageIntro on connect
        return
    end

   -- Handle custom map menu updates
    if custom_map_menu.active then
        -- Animate cursor blinking
        custom_map_menu.cursor_blink_timer = custom_map_menu.cursor_blink_timer + dt
        if custom_map_menu.cursor_blink_timer >= 0.5 then
            custom_map_menu.cursor_visible = not custom_map_menu.cursor_visible
            custom_map_menu.cursor_blink_timer = 0
        end
        return
    end

    -- Animate title image moving up
    if title_screen.image_y > title_screen.image_target_y then
        title_screen.image_y = title_screen.image_y - title_screen.image_speed * dt
        if title_screen.image_y <= title_screen.image_target_y then
            title_screen.image_y = title_screen.image_target_y
            title_screen.menu_visible = true
        end
    end

    -- Fade in menu when image reaches target
    if title_screen.menu_visible and title_screen.menu_alpha < 1 then
        title_screen.menu_alpha = title_screen.menu_alpha + dt * 2  -- Fade in over 0.5 seconds
        if title_screen.menu_alpha > 1 then
            title_screen.menu_alpha = 1
        end
    end

    -- Animate cursor blinking
    title_screen.cursor_blink_timer = title_screen.cursor_blink_timer + dt
    if title_screen.cursor_blink_timer >= 0.5 then
        title_screen.cursor_visible = not title_screen.cursor_visible
        title_screen.cursor_blink_timer = 0
    end
end

return Title
