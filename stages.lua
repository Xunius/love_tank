local Stages = {}

function Stages.loadStageIntro(stage_number)
    game_state = "stage_intro"
    stage_intro.timer = 0
    stage_intro.current_stage = stage_number

    local sound = sounds['stage_start']
    if sound then
        local volume = sound:getVolume()
        sound_clone = sound:clone()
        sound_clone:setVolume(volume)
        sound_clone:play()
    end
end

function Stages.loadStageEnd(stage_number, kill_counts_p1, kill_counts_p2)

    game_state = "stage_end"
    stage_end.timer = 0
    stage_end.current_row = 0
    stage_end.is_pausing = false

    local p1_stage_score = 0
    local p2_stage_score = 0
    local p1_count = 0
    local p2_count = 0

    -- Update stage end data
    stage_end.scores.stage_number = stage_number
    --stage_end.scores.player1_score = scores['player1_score']
    --stage_end.scores.player2_score = scores['player2_score']

    -- Update tank kill counts if provided
    if kill_counts_p1 then
        for i = 1, #stage_end.scores.tank_data do
            stage_end.scores.tank_data[i].kills_p1 = kill_counts_p1[i] or 0

            local tank_info = stage_end.scores.tank_data[i]
            local p1_score = tank_info.kills_p1 * tank_info.points
            p1_count = p1_count + tank_info.kills_p1
            p1_stage_score = p1_stage_score + p1_score
        end
    end

    if kill_counts_p2 then
        for i = 1, #stage_end.scores.tank_data do
            stage_end.scores.tank_data[i].kills_p2 = kill_counts_p2[i] or 0

            local tank_info = stage_end.scores.tank_data[i]
            local p2_score = tank_info.kills_p2 * tank_info.points
            p2_stage_score = p2_stage_score + p2_score
            p2_count = p2_count + tank_info.kills_p2
        end
    end

    if p1_count >= 10 or p2_count >= 10 then
        stage_end.has_bonus = true
    end
    if p1_count >= 10 then
        p1_stage_score = p1_stage_score + stage_end.scores.bonus_points
    end
    if p2_count >= 10 then
        p2_stage_score = p2_stage_score + stage_end.scores.bonus_points
    end
    stage_end.scores.player1_score = p1_stage_score
    stage_end.scores.player2_score = p2_stage_score

    local total_duration = 0
    local row_duration = 0
    for i = 1, #stage_end.scores.tank_data do
        local p1 = stage_end.scores.tank_data[i].kills_p1
        local p2 = stage_end.scores.tank_data[i].kills_p2
        row_duration = stage_end.row_duration + stage_end.score_tick_duration * math.max(p1, p2)
        total_duration = total_duration + row_duration
        stage_end.durations[i] = total_duration
        stage_end.counts[i] = math.max(p1, p2)
        --print('!!!!!!!', i, p1, p2, total_duration)
    end

    stage_end.total_duration = total_duration + stage_end.pause_duration
    stage_end.tick_records = {}

    local hi_score = stage_end.scores.hi_score + math.max(p1_stage_score, p2_stage_score)
    stage_end.scores.hi_score = hi_score

end

function Stages.updateStageIntro(dt)
    stage_intro.timer = stage_intro.timer + dt

    if stage_intro.timer >= stage_intro.duration then
        -- Time's up, start the actual game
        game_state = "game"

        local player_level

        if player == nil then
            player_level = starting_player_level
        else
            player_level = player.level
        end

        Entities.resetGame(stage_intro.current_stage, player_level)
    end
end

function Stages.completeStage()
    --loadStageEnd(stage, p1_kill_counts, p2_kill_counts)
    -- Check if we're playing a custom map (you can track this with a flag)
    if playing_custom_map then
        -- Return to title screen after custom map
        Title.loadTitlePage()
        playing_custom_map = false
    else
        -- Normal stage progression
        Stages.loadStageEnd(stage, p1_kill_counts, p2_kill_counts)
    end
end

function Stages.updateStageEnd(dt)
    stage_end.timer = stage_end.timer + dt

    if not stage_end.is_pausing then
        -- Show rows one by one
        local new_row = 1
        local count = 0
        local total_duration = 0
        local total_duration_next = 0
        local tick_count = 0
        local kills_p1_current = 0
        local kills_p2_current = 0
        local tick_records = stage_end.tick_records

        for i = 1, #stage_end.scores.tank_data do

            if i == 1 then
                total_duration = 0
                total_duration_next = stage_end.durations[i]
            else
                total_duration = stage_end.durations[i-1]
                total_duration_next = stage_end.durations[i]
            end

            if stage_end.timer >= total_duration and stage_end.timer < total_duration_next then
                new_row = i
                count = stage_end.counts[i]
                tick_records[new_row] = tick_records[new_row] or {}

                tick_count = math.floor((stage_end.timer - total_duration - stage_end.row_duration) / stage_end.score_tick_duration) + 1
                tick_count = math.min(tick_count, count)
                --print('$$$$', i, new_row, count, tick_count)

                if tick_count >= 0 then
                    kills_p1_current = math.min(stage_end.scores.tank_data[i].kills_p1, tick_count)
                    kills_p2_current = math.min(stage_end.scores.tank_data[i].kills_p2, tick_count)

                    local ticked = tick_records[new_row][tick_count]
                    if ticked == nil then
                        Audio.playSound('score_tick')
                        tick_records[new_row][tick_count] = true
                    end

                    stage_end.scores.tank_data[i].kills_p1_current = kills_p1_current
                    stage_end.scores.tank_data[i].kills_p2_current = kills_p2_current
                    stage_end.tick_records = tick_records
                else
                    stage_end.scores.tank_data[i].kills_p1_current = 0
                    stage_end.scores.tank_data[i].kills_p2_current = 0
                end
                break
            else
                new_row = #stage_end.scores.tank_data + 1   -- end loop
            end
        end

        if new_row <= #stage_end.scores.tank_data then
            stage_end.current_row = new_row
        else
            -- All rows shown, start pause
            stage_end.current_row = #stage_end.scores.tank_data
            stage_end.is_pausing = true
            --print('#############', stage_end.is_paussing, stage_end.has_bonus)
            if stage_end.is_pausing and stage_end.has_bonus then
                Audio.playSound('bonus')
            end
            stage_end.timer = 0  -- Reset timer for pause duration
        end
    else
        -- Pausing after all rows shown
        if stage_end.timer >= stage_end.pause_duration then
            -- Transition to next stage
            stage = stage + 1
            Stages.loadStageIntro(stage)
        end
    end
end

function Stages.changePlayerLevel(player, change_level)

    local max_level = 4
    player.level = math.min(max_level, player.level + change_level)
    --player.hp = player_levels[player.level].hp
    if player.level > 0 then
        player.fire_timer = player_levels[player.level].fire_timer
        player.bullet_count = player_levels[player.level].bullet_count
        player.speed = player_levels[player.level].move_speed
    end
end

return Stages
