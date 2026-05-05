local Draw = {}

function Draw.drawCustomMapMenu()
    love.graphics.setBackgroundColor(0, 0, 0)  -- Black background

    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(font)
    local title_text = "SELECT CUSTOM MAP"
    local title_width = font:getWidth(title_text)
    love.graphics.print(title_text, (window_width - title_width) / 2, 100)

    local font = love.graphics.newFont(24)
    love.graphics.setFont(font)

    if #custom_map_menu.available_maps == 0 then
        -- No maps available
        love.graphics.setColor(1, 0.5, 0.5, 1)
        local no_maps_text = "NO CUSTOM MAPS FOUND"
        local no_maps_width = font:getWidth(no_maps_text)
        love.graphics.print(no_maps_text, (window_width - no_maps_width) / 2, window_height / 2)

        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        local instruction_text = "Press ESC to return"
        local instruction_width = font:getWidth(instruction_text)
        love.graphics.print(instruction_text, (window_width - instruction_width) / 2, window_height / 2 + 50)
        return
    end

    -- Draw map list
    local menu_start_y = 200
    local menu_x = window_width * 0.3
    local line_height = 40
    local cursor_x = menu_x - 30

    -- Draw visible maps
    for i = 1, math.min(custom_map_menu.max_visible, #custom_map_menu.available_maps) do
        local map_index = custom_map_menu.scroll_offset + i
        if map_index <= #custom_map_menu.available_maps then
            local map_name = custom_map_menu.available_maps[map_index]
            local y = menu_start_y + (i - 1) * line_height

            -- Highlight selected map
            if map_index == custom_map_menu.cursor_position then
                love.graphics.setColor(1, 1, 0, 1)  -- Yellow for selected
            else
                love.graphics.setColor(1, 1, 1, 1)  -- White for others
            end

            love.graphics.print(map_name, menu_x, y)
        end
    end

    -- Draw cursor
    if custom_map_menu.cursor_visible and #custom_map_menu.available_maps > 0 then
        local visible_cursor_pos = custom_map_menu.cursor_position - custom_map_menu.scroll_offset
        if visible_cursor_pos >= 1 and visible_cursor_pos <= custom_map_menu.max_visible then
            local cursor_y = menu_start_y + (visible_cursor_pos - 1) * line_height

            love.graphics.setColor(1, 1, 0, 1)  -- Yellow color
            if player_quads and player_quads[1] and player_quads[1][0] then
                love.graphics.draw(spritesheet, player_quads[1][0], cursor_x, cursor_y, math.pi / 2, 1.5, 1.5)
            else
                -- Fallback: draw a simple triangle cursor
                love.graphics.polygon('fill', cursor_x + 8, cursor_y + 3, cursor_x, cursor_y + 12, cursor_x + 16, cursor_y + 12)
            end
        end
    end

    -- Draw scroll indicators
    if custom_map_menu.scroll_offset > 0 then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print("↑ More maps above", menu_x, menu_start_y - 30)
    end

    if custom_map_menu.scroll_offset + custom_map_menu.max_visible < #custom_map_menu.available_maps then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        local bottom_y = menu_start_y + math.min(custom_map_menu.max_visible, #custom_map_menu.available_maps) * line_height
        love.graphics.print("↓ More maps below", menu_x, bottom_y + 10)
    end

    -- Draw instructions
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    local instruction_text = "ESC: Back    ENTER: Select Map"
    local instruction_width = font:getWidth(instruction_text)
    love.graphics.print(instruction_text, (window_width - instruction_width) / 2, window_height - 60)

    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

function Draw.drawLANMenu()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(font)

    local title_text
    if lan_menu.mode == "host" then
        title_text = "HOST LAN"
    elseif lan_menu.mode == "ip_entry" then
        title_text = "ENTER HOST IP"
    elseif lan_menu.mode == "client" then
        title_text = "JOIN LAN"
    else
        title_text = "LAN"
    end
    local tw = font:getWidth(title_text)
    love.graphics.print(title_text, (window_width - tw) / 2, window_height * 0.25)

    -- Status / IP entry
    local body_y = window_height * 0.45
    if lan_menu.mode == "ip_entry" then
        local prompt = lan_menu.ip_text
        if lan_menu.cursor_visible then prompt = prompt .. "_" end
        local pw = font:getWidth(prompt)
        love.graphics.print(prompt, (window_width - pw) / 2, body_y)
    else
        local msg = network_status_msg or ""
        for line in msg:gmatch("[^\n]+") do
            local lw = font:getWidth(line)
            love.graphics.print(line, (window_width - lw) / 2, body_y)
            body_y = body_y + 40
        end
    end

    local hint = "ESC to cancel"
    if lan_menu.mode == "ip_entry" then
        hint = "ENTER to connect    BACKSPACE to edit    ESC to cancel"
    end
    love.graphics.setColor(0.7, 0.7, 0.7)
    local hw = font:getWidth(hint)
    love.graphics.print(hint, (window_width - hw) / 2, window_height - 60)
    love.graphics.setColor(1, 1, 1, 1)
end

function Draw.drawTitleScreen()
    love.graphics.setBackgroundColor(0, 0, 0)  -- Black background

    if custom_map_menu.active then
        Draw.drawCustomMapMenu()
        return
    end

    if lan_menu and lan_menu.active then
        Draw.drawLANMenu()
        return
    end

    -- Draw title image
    local image_width = title_image:getWidth()
    local image_height = title_image:getHeight()
    local image_x = (window_width - image_width) / 2

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(title_image, image_x, title_screen.image_y)

    -- Draw menu options if visible
    if title_screen.menu_visible then
        local menu_start_y = window_height * 0.6
        local menu_x = window_width * 0.4
        local line_height = 50
        local cursor_x = menu_x - 40

        -- Set menu alpha
        love.graphics.setColor(1, 1, 1, title_screen.menu_alpha)

        -- Draw menu options
        for i, option in ipairs(title_screen.menu_options) do
            local y = menu_start_y + (i - 1) * line_height
            love.graphics.setFont(font)
            love.graphics.print(option, menu_x, y)
        end

        -- Draw cursor (tank icon)
        if title_screen.cursor_visible then
            local cursor_y = menu_start_y + (title_screen.cursor_position - 1) * line_height

            -- Draw a simple tank cursor using the player tank sprite
            love.graphics.setColor(1, 1, 0, title_screen.menu_alpha)  -- Yellow color
            if player_quads and player_quads[1] and player_quads[1][0] then
                love.graphics.draw(spritesheet, player_quads[1][0], cursor_x, cursor_y, math.pi / 2, 2, 2)
            else
                -- Fallback: draw a simple triangle cursor
                love.graphics.polygon('fill', cursor_x + 10, cursor_y + 5, cursor_x, cursor_y + 15, cursor_x + 20, cursor_y + 15)
            end
        end

        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end
end

function Draw.drawStageIntro()
    -- Fill screen with gray background
    love.graphics.setBackgroundColor(0.4, 0.4, 0.4)
    --love.graphics.clear()

    -- Set white color for drawing
    love.graphics.setColor(1, 1, 1, 1)

    -- Calculate center positions
    local center_x = window_width / 2
    local center_y = window_height / 2

    -- Draw "STAGE" quad
    if ui_quads and ui_quads['stage'] then
        local stage_quad = ui_quads['stage']
        --local _, _, stage_width, stage_height = stage_quad:getViewport()
        local stage_width = cell_size * 2.5
        local stage_height = cell_size

        -- Draw the stage label centered horizontally, slightly above center
        local stage_x = center_x - stage_width * 0.75
        local stage_y = center_y - 60

        love.graphics.draw(spritesheet, stage_quad, stage_x, stage_y, 0, cell_size / full_sprite_width, cell_size / full_sprite_height)

        -- Draw the stage number (2 digits)
        local stage_num = stage_intro.current_stage
        local tens = math.floor(stage_num / 10)
        local ones = stage_num % 10

        -- Get digit quad dimensions (assuming all digit quads are same size)
        local digit_quad = ui_quads[tostring(ones)]
        --local _, _, digit_width, digit_height = digit_quad:getViewport()
        local digit_width = cell_size / 2
        local digit_height = cell_size / 2

        -- Position digits after the "STAGE" text
        local digits_y = stage_y
        --local total_digits_width = digit_width * 2  -- 2 digits
        local digits_start_x = stage_x + stage_width + cell_size / 2

        -- Draw tens digit
        if ui_quads[tostring(tens)] then
            love.graphics.draw(spritesheet, ui_quads[tostring(tens)], digits_start_x, digits_y, 0, cell_size / full_sprite_width, cell_size / full_sprite_height)
        end

        -- Draw ones digit
        if ui_quads[tostring(ones)] then
            love.graphics.draw(spritesheet, ui_quads[tostring(ones)], digits_start_x + digit_width, digits_y, 0, cell_size / full_sprite_width, cell_size / full_sprite_height)
        end
    else
        -- Fallback text rendering if quads aren't available
        love.graphics.setFont(font)
        local stage_text = "STAGE " .. string.format("%02d", stage_intro.current_stage)
        local text_width = font:getWidth(stage_text)
        love.graphics.print(stage_text, center_x - text_width / 2, center_y - 20)
    end
end

function Draw.drawStageEnd()

    love.graphics.setBackgroundColor(0, 0, 0)

    local data = stage_end.scores
    local center_x = window_width / 2
    local start_y = 50
    local current_y

    -- Draw HI-SCORE and current hi-score
    love.graphics.setColor(1, 0.3, 0, 1)  -- red color
    love.graphics.setFont(font)
    local hi_score_text = "HI-SCORE"
    local hi_score_width = font:getWidth(hi_score_text)
    current_y = start_y
    love.graphics.print(hi_score_text, center_x - 10 - hi_score_width, current_y)
    love.graphics.setColor(1, 0.65, 0.3, 1)  -- Orange color
    love.graphics.print(tostring(data.hi_score), center_x + 50, current_y)
    current_y = current_y + font:getHeight(hi_score_text) + 20

    -- Draw STAGE number
    love.graphics.setColor(1, 1, 1, 1)  -- White
    local stage_text = "STAGE " .. string.format("%02d", data.stage_number)
    local stage_width = font:getWidth(stage_text)
    love.graphics.print(stage_text, center_x - stage_width/2, current_y)
    current_y = current_y + font:getHeight(stage_text) + 20

    -- Draw player scores
    love.graphics.setColor(1, 0.3, 0, 1)  -- red
    local p1_score_text_width = font:getWidth("I-PLAYER")
    local p2_score_text_width = font:getWidth("II-PLAYER")

    -- align texts about these x locations
    local left_side_x_right = center_x - 150
    local right_side_x_right = center_x + 150 + p2_score_text_width

    love.graphics.print("I-PLAYER", left_side_x_right - p1_score_text_width, current_y)
    love.graphics.print("II-PLAYER", right_side_x_right - p2_score_text_width, current_y)
    current_y = current_y + font:getHeight("I") + 20

    love.graphics.setColor(1, 0.65, 0.3, 1)  -- Orange color
    love.graphics.print(tostring(data.player1_score), left_side_x_right - font:getWidth(tostring(data.player1_score)), current_y)
    love.graphics.print(tostring(data.player2_score), right_side_x_right - font:getWidth(tostring(data.player2_score)), current_y)
    current_y = current_y + font:getHeight("I") + 30

    -- Draw tank breakdown rows (only up to current_row)
    local row_start_y = current_y
    local row_height = 60
    local tank_count_x_offset = 80
    local p1_stage_score = 0
    local p2_stage_score = 0


    for i = 1, stage_end.current_row do

        local tank_info = data.tank_data[i]
        local y = row_start_y + (i - 1) * row_height

        -- Draw P1 score (left side)
        love.graphics.setColor(1, 1, 1, 1)  -- White
        local p1_score_text = "  PTS"
        local p1_score_text_width = font:getWidth(p1_score_text)

        love.graphics.print(p1_score_text, left_side_x_right - p1_score_text_width, y)

        -- Draw tank sprite in center
        if enemy_quads and enemy_quads[tank_info.color] and enemy_quads[tank_info.color][tank_info.level] then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(spritesheet, enemy_quads[tank_info.color][tank_info.level][0],
                             center_x - full_sprite_width / 2, y, 0, 3.0, 3.0)  -- Scale up 2x
        end

        love.graphics.draw(arrow_image, center_x - 30, y + row_height / 3, -math.pi/2, 1.5, 1.5, 8, 8)
        love.graphics.draw(arrow_image, center_x + 50, y + row_height / 3, math.pi/2, 1.5, 1.5, 8, 8)

        local p2_score_text = "  PTS"
        local p2_score_text_width = font:getWidth(p2_score_text)
        love.graphics.print(p2_score_text, right_side_x_right - p2_score_text_width, y)

    end


    for i = 1, stage_end.current_row do

        local tank_info = data.tank_data[i]
        local y = row_start_y + (i - 1) * row_height

        -- Calculate scores
        local p1_score = tank_info.kills_p1 * tank_info.points
        local p2_score = tank_info.kills_p2 * tank_info.points

        p1_stage_score = p1_stage_score + p1_score
        p2_stage_score = p2_stage_score + p2_score

        -- Draw P1 score (left side)
        love.graphics.setColor(1, 1, 1, 1)  -- White
        local p1_score_text = tostring(p1_score) .. "  PTS"
        local p1_score_text_width = font:getWidth(p1_score_text)

        love.graphics.print(p1_score_text, left_side_x_right - p1_score_text_width, y)

        -- Draw P1 kill count
        love.graphics.print(tostring(tank_info.kills_p1_current),
            center_x - tank_count_x_offset - font:getWidth(tostring(tank_info.kills_p1_current)), y)

        -- Draw P2 kill count
        love.graphics.print(tostring(tank_info.kills_p2_current), center_x + tank_count_x_offset, y)

        local p2_score_text = tostring(p2_score) .. "  PTS"
        local p2_score_text_width = font:getWidth(p2_score_text)
        love.graphics.print(p2_score_text, right_side_x_right - p2_score_text_width, y)
    end


    -- Draw TOTAL row if all tank rows are shown
    if stage_end.current_row >= #data.tank_data then
        local total_y = row_start_y + #data.tank_data * row_height

        -- Draw line above total
        love.graphics.setLineWidth(4)
        love.graphics.line(center_x - tank_count_x_offset - 20, total_y,
            center_x + tank_count_x_offset + 20, total_y)

        local total_text_width = font:getWidth("TOTAL")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("TOTAL", left_side_x_right - font:getWidth("TOTAL"), total_y + 2)

        -- Calculate totals
        local total_p1 = 0
        local total_p2 = 0
        for _, tank_info in ipairs(data.tank_data) do
            total_p1 = total_p1 + tank_info.kills_p1
            total_p2 = total_p2 + tank_info.kills_p2
        end

        love.graphics.print(tostring(total_p1), center_x - tank_count_x_offset - font:getWidth(tostring(total_p1)), total_y+2)
        love.graphics.print(tostring(total_p2), center_x + tank_count_x_offset, total_y + 2)

        -- Draw bonus
        --if stage_end.is_pausing then
        current_y = total_y + 60
        if stage_end.is_pausing and stage_end.has_bonus then
            if total_p1 >= 10 then
                love.graphics.setColor(1, 0.3, 0, 1)  -- red
                love.graphics.print("BONUS!", left_side_x_right - p1_score_text_width, current_y)
                love.graphics.setColor(1, 1, 1, 1)  -- white
                love.graphics.print(tostring(data.bonus_points) .. "  PTS",
                    left_side_x_right - p1_score_text_width, current_y + font:getHeight(' ') + 5)
            end
            if total_p2 >= 10 then
                love.graphics.setColor(1, 0.3, 0, 1)  -- red
                love.graphics.print("BONUS!", right_side_x_right - p2_score_text_width, total_y + 60)
                love.graphics.setColor(1, 1, 1, 1)  -- white
                love.graphics.print(tostring(data.bonus_points) .. "  PTS",
                    right_side_x_right - p2_score_text_width, current_y + font:getHeight(' ') + 5)
            end
        end
    end
end

function Draw.drawBorder()
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle('fill', -border_thickness, -border_thickness, world_width+border_thickness, border_thickness)
    love.graphics.rectangle('fill', -border_thickness, world_height, world_width+border_thickness, border_thickness)
    love.graphics.rectangle('fill', -border_thickness, -border_thickness, border_thickness, world_height+border_thickness)
    love.graphics.rectangle('fill', world_width, -border_thickness, border_thickness, world_height+2*border_thickness)
    love.graphics.setColor(1, 1, 1)
end

function Draw.drawBase()

    local quad
    if base.hp > 0 then
        quad = base_quads[0]
        --quad = base_image
    else
        quad = base_quads[1]
        --quad = base_lose_image
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(spritesheet, quad, base.x, base.y, 0,
        0.8 * cell_size / full_sprite_width, 0.8 * cell_size / full_sprite_height, full_sprite_width / 2, full_sprite_height / 2)
    --love.graphics.draw(quad, base.x, base.y, 0,
        --0.9 * cell_size / quad:getWidth(),
        --0.9 * cell_size / quad:getHeight(),
        --quad:getWidth() / 2,
        --quad:getHeight() / 2)
end


function Draw.drawFuelBar(tank)
    if not tank.fuel then return end

    local bar_x = tank.x - fuel_config.bar_width / 2
    local bar_y = tank.y + fuel_config.bar_offset_y
    local fuel_percentage = tank.fuel / fuel_config.max_fuel
    local fuel_width = fuel_config.bar_width * fuel_percentage

    -- Background bar (dark gray)
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", bar_x, bar_y, fuel_config.bar_width, fuel_config.bar_height)

    -- Fuel bar color logic
    local r, g, b = 1, 1, 0  -- yellow by default

    if tank.fuel <= fuel_config.critical_fuel_threshold then
        -- Critical fuel - blinking red
        local blink = math.sin(tank.fuel_warning_timer * 8) > 0  -- 8 blinks per second
        if blink then
            r, g, b = 1, 0, 0  -- Red
        else
            r, g, b = 1, 1, 1  -- Dark red
        end
    elseif tank.fuel <= fuel_config.low_fuel_threshold then
        -- Low fuel - yellow/orange
        r, g, b = 1, 0.5, 0
    end

    -- Draw fuel bar
    if fuel_width > 0 then
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.rectangle("fill", bar_x, bar_y, fuel_width, fuel_config.bar_height)
    end

    -- Border
    love.graphics.setColor(0.6, 0.6, 0.6, 0.9)
    love.graphics.rectangle("line", bar_x, bar_y, fuel_config.bar_width, fuel_config.bar_height)
end

function Draw.drawPlayerTanks()

    local all_tanks = {player}
    if player2 then
        table.insert(all_tanks, player2)
    end

    for _, tank in ipairs(all_tanks) do
        if tank.hp > 0 then
            love.graphics.setColor(1, 1, 1)

            local quads = (tank.player_number == 2) and player2_quads or player_quads
            local quad = quads[tank.level][tank.frame]

            love.graphics.draw(spritesheet, quad, tank.x, tank.y, tank.angle,
                0.8 * cell_size / full_sprite_width, 0.8 * cell_size / full_sprite_height, full_sprite_width / 2, full_sprite_height / 2)

            if tank.has_shield then
                local animation_speed = 16
                local shield_frame = math.floor(love.timer.getTime() * animation_speed) % 2

                local old_blend_mode = love.graphics.getBlendMode()
                love.graphics.setBlendMode("add")
                love.graphics.setColor(1, 1, 1, 1)
                local quad2 = shield_quads[shield_frame]
                love.graphics.draw(spritesheet, quad2, tank.x, tank.y, 0,
                    0.8 * cell_size / full_sprite_width, 0.8 * cell_size / full_sprite_height, full_sprite_width / 2, full_sprite_height / 2)
                love.graphics.setBlendMode(old_blend_mode)
            end
        end
    end

    -- Draw player fuel bars
    if world_expanded then
        Draw.drawFuelBar(player)
        if player2 then
            Draw.drawFuelBar(player2)
        end
    end

end


function Draw.drawEnemyTanks()

    -- Draw enemy tanks
    for _, enemy in ipairs(enemies) do
        Draw.drawEnemyTank(enemy)
    end
end

function Draw.drawInterpolatedQuads(quad1, quad2, tank, t)
    -- t should be between 0 and 1
    -- t = 0 shows only quad1, t = 1 shows only quad2

    -- Draw first quad with decreasing alpha
    love.graphics.setColor(1, 1, 1, 1 - t)
    --love.graphics.draw(spritesheet, quad1, x, y)
    love.graphics.draw(spritesheet, quad1, tank.x, tank.y, tank.angle,
        0.8 * cell_size / full_sprite_width, 0.8 * cell_size / full_sprite_height, full_sprite_width / 2, full_sprite_height / 2)

    -- Draw second quad with increasing alpha
    love.graphics.setColor(1, 1, 1, t)
    --love.graphics.draw(spritesheet, quad2, x, y)
    love.graphics.draw(spritesheet, quad2, tank.x, tank.y, tank.angle,
        0.8 * cell_size / full_sprite_width, 0.8 * cell_size / full_sprite_height, full_sprite_width / 2, full_sprite_height / 2)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function Draw.drawEnemyTank(tank)

    local quad

    if tank.hp == 0 then
        r, g, b = 0.6, 0.5, 0.5
        love.graphics.setColor(r, g, b)
        quad = enemy_quads[enemy_color][tank.level][tank.frame]
        love.graphics.draw(spritesheet, quad, tank.x, tank.y, tank.angle,
            0.8 * cell_size / full_sprite_width,
            0.8 * cell_size / full_sprite_height,
            full_sprite_width / 2, full_sprite_height / 2)

    else
        r, g, b = 1, 1, 1
        love.graphics.setColor(r, g, b)

        if tank.has_pickup == true then
            local animation_speed = 1
            local t = (love.timer.getTime() * animation_speed) % 1
            t = math.floor(t+0.5)  -- round to nearest int
            local quad1 = enemy_quads['red'][tank.level][tank.frame]
            local quad2 = enemy_quads['silver'][tank.level][tank.frame]
            Draw.drawInterpolatedQuads(quad1, quad2, tank, t)

        else
            if tank.level == 4 then
                local t = (4 - tank.hp) / 4
                local quad1 = enemy_quads['gold'][tank.level][tank.frame]
                local quad2 = enemy_quads['silver'][tank.level][tank.frame]
                Draw.drawInterpolatedQuads(quad1, quad2, tank, t)

            else
                quad = enemy_quads[enemy_color][tank.level][tank.frame]
                love.graphics.draw(spritesheet, quad, tank.x, tank.y, tank.angle,
                    0.8 * cell_size / full_sprite_width,
                    0.8 * cell_size / full_sprite_height,
                    full_sprite_width / 2, full_sprite_height / 2)
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)

    -- Draw enemy fuel bar
    if world_expanded then
        Draw.drawFuelBar(tank)
    end
end


function Draw.drawBullets()

    local function drawBullet(bullet)
        love.graphics.draw(bullet_image, bullet.x, bullet.y, bullet.angle,
            cell_size / bullet_image:getWidth() *0.4,
            cell_size / bullet_image:getHeight() *0.4,
            bullet_image:getWidth()/2, bullet_image:getHeight()/2)
    end

    for _, b in ipairs(bullets) do
        drawBullet(b)
    end
    for _, b in ipairs(enemy_bullets) do
        drawBullet(b)
    end
    love.graphics.setColor(1, 1, 1)
end

function Draw.drawMapObjects(is_foreground)

    local cam_x, cam_y = camera.x, camera.y
    local cam_w, cam_h = camera.width, camera.height

    -- Convert camera bounds to cell coordinates with small buffer
    local buffer = 2 -- cells outside view for smooth scrolling
    local start_cell_x = math.floor(cam_x / cell_size) - buffer
    local end_cell_x   = math.floor((cam_x + cam_w) / cell_size) + buffer
    local start_cell_y = math.floor(cam_y / cell_size) - buffer
    local end_cell_y   = math.floor((cam_y + cam_h) / cell_size) + buffer

    -- Clamp to actual world bounds
    start_cell_x = math.max(0, start_cell_x)
    start_cell_y = math.max(0, start_cell_y)
    end_cell_x   = math.min(world_width_in_cells - 1, end_cell_x)
    end_cell_y   = math.min(world_height_in_cells - 1, end_cell_y)

    for x_cell = start_cell_x, end_cell_x do
        if map_objects[x_cell] then
            for y_cell = start_cell_y, end_cell_y do
                local sub_grid_blocks = map_objects[x_cell][y_cell]

                if sub_grid_blocks then
                    for _, obj in ipairs(sub_grid_blocks) do

                        if obj then
                            local img

                            if is_foreground and obj.type ~= 'grass' then
                                img = nil
                            --elseif is_foreground == false and obj.type == 'grass' then
                                --img = nil
                            else
                                img = map_objects_quads[obj.type]
                            end

                            if img then
                                local objtype = obj.type
                                if string.sub(objtype, 1, #'brick') == 'brick' then
                                    love.graphics.draw(spritesheet, img,
                                        obj.x + obj.sub_x, obj.y + obj.sub_y, 0,
                                        cell_size / full_sprite_width,
                                        cell_size / full_sprite_height)

                                elseif string.sub(objtype, 1, #'steel') == 'steel' then
                                    love.graphics.draw(spritesheet, img,
                                        obj.x + obj.sub_x, obj.y + obj.sub_y, 0,
                                        cell_size / full_sprite_width,
                                        cell_size / full_sprite_height)

                                elseif objtype == 'water' then
                                    local animation_speed = 1  -- 1 fps
                                    local water_frames = {'water', 'water2', 'water3', 'water2'}
                                    local water_frame = math.floor(love.timer.getTime() * animation_speed) % #water_frames
                                    local water_frame = water_frames[water_frame+1]
                                    img = watergrassice_quads[water_frame]
                                    love.graphics.draw(spritesheet, img,
                                        obj.x + obj.sub_x, obj.y + obj.sub_y, 0,
                                        cell_size / full_sprite_width,
                                        cell_size / full_sprite_height)

                                elseif objtype == 'water_quarter' then
                                    local animation_speed = 1  -- 1 fps
                                    local water_frames = {'water_quarter', 'water_quarter2', 'water_quarter3'}
                                    local water_frame = math.floor(love.timer.getTime() * animation_speed) % #water_frames
                                    local water_frame = water_frames[water_frame+1]
                                    img = watergrassice_quads[water_frame]
                                    love.graphics.draw(spritesheet, img,
                                        obj.x + obj.sub_x, obj.y + obj.sub_y, 0,
                                        cell_size / full_sprite_width,
                                        cell_size / full_sprite_height)

                                elseif objtype == 'grass' or objtype == 'ice' then
                                    if objtype == 'grass' and is_foreground then
                                        love.graphics.setColor(1, 1, 1, 0.65)
                                    end
                                    love.graphics.draw(spritesheet, img,
                                        obj.x + obj.sub_x, obj.y + obj.sub_y, 0,
                                        cell_size / full_sprite_width,
                                        cell_size / full_sprite_height)
                                else
                                    love.graphics.draw(spritesheet, img,
                                        obj.x + obj.sub_x, obj.y + obj.sub_y, 0,
                                        cell_size / full_sprite_width,
                                        cell_size / full_sprite_height)
                                    --love.graphics.draw(img, obj.x + obj.sub_x, obj.y + obj.sub_y, 0,
                                        --cell_size / img:getWidth(),
                                        --cell_size / img:getHeight())
                                end
                                love.graphics.setColor(1, 1, 1)
                            end
                        end
                    end
                end
            end
        end
    end
end

function Draw.drawUI()

    -- UI Background
    --love.graphics.setColor(0.4, 0.4, 0.4)
    --love.graphics.rectangle("fill", game_area_width, 0, ui_margin_width, window_height)

    -- UI Border line
    --love.graphics.setColor(0.5, 0.5, 0.5)
    --love.graphics.line(game_area_width, 0, game_area_width, window_height)

    --love.graphics.setColor(1, 1, 1); love.graphics.setFont(font)

    --[[
    -- Position UI elements in the right margin
    local ui_x = game_area_width + 20
    local ui_y = 20

    love.graphics.print("HP: " .. player.hp, ui_x, ui_y)
    -- Fuel display with color coding
    local fuel_color = {1, 1, 1}  -- White by default
    if player.fuel <= fuel_config.critical_fuel_threshold then
        fuel_color = {1, 0, 0}  -- Red
    elseif player.fuel <= fuel_config.low_fuel_threshold then
        fuel_color = {1, 0.5, 0}  -- Orange
    end

    love.graphics.setColor(fuel_color)
    love.graphics.print("Fuel: " .. math.floor(player.fuel), ui_x, ui_y + 30)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Enemies: " .. (total_enemies_to_spawn - enemies_defeated), ui_x, ui_y + 60)

    love.graphics.print("Controls:", ui_x, ui_y + 100)
    love.graphics.print("HJKL - Move", ui_x, ui_y + 130)
    love.graphics.print("F - Shoot", ui_x, ui_y + 160)

    love.graphics.print("Pickups:", ui_x, ui_y + 200)
    for i, p in ipairs(pickup_types) do
        local p_type = p.type
        local count = pickup_counts[p_type]
        love.graphics.print(p_type .. ": " .. count, ui_x, ui_y + 200 + i*30)
    end

    --love.graphics.print("A: " .. pickup_counts.A, ui_x, ui_y + 230)
    --love.graphics.print("B: " .. pickup_counts.B, ui_x, ui_y + 260)
    --love.graphics.print("C: " .. pickup_counts.C, ui_x, ui_y + 290)
    --love.graphics.print("D: " .. pickup_counts.D, ui_x, ui_y + 320)

    -- Show fuel pickups count if you want to track them
    pickup_counts.FUEL = pickup_counts.FUEL or 0
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("Fuel: " .. pickup_counts.FUEL, ui_x, ui_y + 350)
    love.graphics.setColor(1, 1, 1)
    --]]

    local quad = ui_quads['panel']
    love.graphics.draw(spritesheet, quad, game_area_width, 0, 0,
        ui_margin_width / full_sprite_width / 2, world_height / full_sprite_height / 15)

    Draw.drawEnemyLabelGrid()

    Draw.drawPlayerHP()

    Draw.drawStageNumber()

end

function Draw.drawPickups()
    for _, pi in ipairs(pickups) do
        local p = pi
        if p.type == 'FUEL' then
            -- Draw fuel pickup with gas can icon or special color
            love.graphics.setColor(1, 1, 0, 0.9)  -- Yellow for fuel
            love.graphics.rectangle("fill", p.x - full_sprite_width, p.y - full_sprite_height, 32, 32)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print("F", p.x - 4, p.y - 8)
        else
            local quad = pickup_quads[p.type]
            love.graphics.draw(spritesheet, quad, p.x, p.y, 0,
                0.8 * cell_size / full_sprite_width, 0.8 * cell_size / full_sprite_height, 8, 8)
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function Draw.drawEnemyLabelGrid()
    local total = 20
    local enemy_num = total_enemies_to_spawn - enemies_defeated
    local ncols = 2
    local x0 = game_area_width + cell_size / 2
    --local y0 = cell_size + cell_size / 2
    local y0 = cell_size
    local grid_size = cell_size / 2
    local quad

    for i = 0, total-1 do
        col = i % ncols
        row = math.floor(i / ncols)
        local x = x0 + col * grid_size
        local y = y0 + row * grid_size

        if i <= enemy_num - 1 then
            quad = ui_quads['tank']
        else
            quad = ui_quads['empty']
        end
        love.graphics.draw(spritesheet, quad, x, y, 0, cell_size / full_sprite_width, cell_size / full_sprite_height)
    end
end


function Draw.drawPlayerHP()

    -- draw player 1
    local hp = player.hp
    local x = game_area_width + cell_size
    local y = cell_size * 7.75
    local quad = ui_quads[tostring(hp)]
    love.graphics.draw(spritesheet, quad, x, y, 0, cell_size / full_sprite_width, cell_size / full_sprite_height)

    -- draw player 2
    local x2 = game_area_width + cell_size
    local y2 = cell_size * 9.05
    if player2 then
        local hp2 = player2.hp
        local quad2 = ui_quads[tostring(hp2)]
        if quad2 then
            love.graphics.draw(spritesheet, quad2, x2, y2, 0, cell_size / full_sprite_width, cell_size / full_sprite_height)
        end
    else
        local quad2 = ui_quads['empty']
        love.graphics.draw(spritesheet, quad2, x2, y2, 0, cell_size / 8, cell_size / 8)
    end

end


function Draw.drawStageNumber()

    local digits = string.format('%02d', stage)
    local digit1 = string.sub(digits, 1, 1)
    local digit2 = string.sub(digits, 2, 2)

    local x = game_area_width + cell_size / 2
    local y = cell_size * 10.8
    local quad = ui_quads[digit1]
    love.graphics.draw(spritesheet, quad, x, y, 0, cell_size / full_sprite_width, cell_size / full_sprite_height)

    local x = game_area_width + cell_size
    local y = cell_size * 10.8
    local quad = ui_quads[digit2]
    love.graphics.draw(spritesheet, quad, x, y, 0, cell_size / full_sprite_width, cell_size / full_sprite_height)

end


function Draw.drawGameOver()

    local x = gameover_label.x
    local y = gameover_label.y
    local quad = gameover_label.quad
    love.graphics.draw(spritesheet, quad, x, y, 0, cell_size / full_sprite_width, cell_size / full_sprite_height)

end

return Draw
