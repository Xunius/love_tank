local Network = {}

local enet = nil
local ehost = nil  -- enet host object
local epeer = nil  -- on client: server peer; on host: most recent client peer

local SNAPSHOT_INTERVAL = 1/30
local snapshot_send_timer = 0

-- Track last-sent input state on the client so we send only on change (reliable).
local last_sent_keys = {up = false, down = false, left = false, right = false}

network_state = "off"  -- off, host_waiting, host_connected, client_connecting, client_connected
network_status_msg = ""

remote_keys = {up = false, down = false, left = false, right = false}
remote_fire_pending = false
client_fire_pending = false
last_snapshot = nil

local event_queue = {}

local function safeRequireEnet()
    local ok, mod = pcall(require, 'enet')
    if not ok then return nil end
    return mod
end

function Network.isOn()      return network_state ~= "off" end
function Network.isHost()    return network_state == "host_waiting" or network_state == "host_connected" end
function Network.isClient()  return network_state == "client_connecting" or network_state == "client_connected" end
function Network.isConnected() return network_state == "host_connected" or network_state == "client_connected" end

function Network.startHost(port)
    enet = safeRequireEnet()
    if not enet then network_status_msg = "enet not available"; return false end
    port = port or 22122
    local ok, err = pcall(function()
        ehost = enet.host_create("*:" .. port, 4, 2)
    end)
    if not ok or not ehost then
        network_status_msg = "Failed to bind: " .. tostring(err)
        return false
    end
    network_state = "host_waiting"
    network_status_msg = "HOSTING ON PORT " .. port .. "\nWAITING FOR PLAYER 2..."
    return true
end

function Network.startClient(ip, port)
    enet = safeRequireEnet()
    if not enet then network_status_msg = "enet not available"; return false end
    port = port or 22122
    local ok, err = pcall(function()
        ehost = enet.host_create()
        epeer = ehost:connect(ip .. ":" .. port, 2)
    end)
    if not ok or not ehost or not epeer then
        network_status_msg = "Failed: " .. tostring(err)
        ehost = nil; epeer = nil
        return false
    end
    network_state = "client_connecting"
    network_status_msg = "CONNECTING TO " .. ip .. "..."
    return true
end

function Network.shutdown()
    if epeer then pcall(function() epeer:disconnect() end) end
    if ehost then pcall(function() ehost:flush() end) end
    ehost = nil
    epeer = nil
    network_state = "off"
    network_status_msg = ""
    last_snapshot = nil
    client_fire_pending = false
    remote_fire_pending = false
    event_queue = {}
    remote_keys.up, remote_keys.down, remote_keys.left, remote_keys.right = false, false, false, false
    last_sent_keys.up, last_sent_keys.down, last_sent_keys.left, last_sent_keys.right = false, false, false, false
end

-- ----- event queue (host-side, flushed in broadcastSnapshot) -----
function Network.queueEvent(ev)
    -- Only host should queue events for replication
    if network_state ~= "host_connected" then return end
    event_queue[#event_queue + 1] = ev
end

local function applyEvent(ev)
    local t = ev.t
    if t == "snd" then
        Audio.playSound(ev.s, ev.x, ev.y, ev.f)
    elseif t == "par" then
        VFX.addParticleEffect(ev.x, ev.y, ev.k)
    elseif t == "exp" then
        VFX.addExplosion(ev.x, ev.y, ev.sz)
    elseif t == "muz" then
        VFX.addMuzzleFlash(ev.x, ev.y, ev.a)
    elseif t == "shk" then
        VFX.addScreenShake(ev.d, ev.m)
    elseif t == "dmg" then
        VFX.addDamageNumber(ev.x, ev.y, ev.n)
    elseif t == "scr" then
        VFX.addScoreNumber(ev.x, ev.y, ev.n)
    elseif t == "fue" then
        VFX.addFuelGainNumber(ev.x, ev.y, ev.n)
    end
end

-- ----- compact serializer for nested tables of nil/bool/number/string/table -----
local function serialize(v)
    local t = type(v)
    if t == "nil" then return "n" end
    if t == "boolean" then return v and "t" or "f" end
    if t == "number" then return "#" .. tostring(v) .. "|" end
    if t == "string" then return "$" .. #v .. "|" .. v end
    if t == "table" then
        local parts = {"{"}
        local seen = {}
        local i = 1
        while v[i] ~= nil do
            parts[#parts+1] = "i"
            parts[#parts+1] = serialize(v[i])
            seen[i] = true
            i = i + 1
        end
        for k, val in pairs(v) do
            if not seen[k] then
                parts[#parts+1] = "k"
                parts[#parts+1] = serialize(k)
                parts[#parts+1] = serialize(val)
            end
        end
        parts[#parts+1] = "}"
        return table.concat(parts)
    end
    return "n"
end

local function deserialize(s, pos)
    pos = pos or 1
    local c = s:sub(pos, pos)
    if c == "n" then return nil, pos + 1 end
    if c == "t" then return true, pos + 1 end
    if c == "f" then return false, pos + 1 end
    if c == "#" then
        local stop = s:find("|", pos + 1, true)
        return tonumber(s:sub(pos + 1, stop - 1)), stop + 1
    end
    if c == "$" then
        local stop = s:find("|", pos + 1, true)
        local n = tonumber(s:sub(pos + 1, stop - 1))
        return s:sub(stop + 1, stop + n), stop + 1 + n
    end
    if c == "{" then
        pos = pos + 1
        local result = {}
        local arr_idx = 1
        while true do
            local k = s:sub(pos, pos)
            if k == "}" then return result, pos + 1 end
            if k == "i" then
                local val, np = deserialize(s, pos + 1)
                result[arr_idx] = val
                arr_idx = arr_idx + 1
                pos = np
            elseif k == "k" then
                local key, np = deserialize(s, pos + 1)
                local val, np2 = deserialize(s, np)
                result[key] = val
                pos = np2
            else
                error("bad table token: " .. tostring(k))
            end
        end
    end
    error("bad token: " .. tostring(c))
end

local function sendTo(target_peer, mtype, payload, mode)
    if not target_peer then return end
    local data = mtype .. serialize(payload or {})
    pcall(function() target_peer:send(data, 0, mode or "reliable") end)
end

local function broadcastAll(mtype, payload, mode)
    if not ehost then return end
    local data = mtype .. serialize(payload or {})
    pcall(function() ehost:broadcast(data, 0, mode or "reliable") end)
end

-- ----- message handling -----
local function handleMessage(mtype, payload)
    if mtype == "K" then
        -- Single key transition (reliable, ordered).
        if payload.k and remote_keys[payload.k] ~= nil then
            remote_keys[payload.k] = payload.v and true or false
        end
    elseif mtype == "F" then
        -- Fire request (reliable).
        remote_fire_pending = true
    elseif mtype == "T" then
        last_snapshot = payload
    elseif mtype == "S" then
        -- stage start (client receives)
        stage = payload.stage or 1
        num_players = 2
        if Stages and Stages.loadStageIntro then
            Stages.loadStageIntro(stage)
        end
    elseif mtype == "G" then
        game_state = payload.s or game_state
    elseif mtype == "E" then
        -- Batched events from host
        if payload and payload.evs then
            for _, ev in ipairs(payload.evs) do
                applyEvent(ev)
            end
        end
    end
end

function Network.poll()
    if not ehost then return end
    while true do
        local ok, event = pcall(function() return ehost:service(0) end)
        if not ok or not event then break end
        if event.type == "connect" then
            if Network.isHost() then
                epeer = event.peer
                network_state = "host_connected"
                network_status_msg = "PLAYER 2 CONNECTED"
                -- start a fresh game on host
                num_players = 2
                stage = 1
                if Stages and Stages.loadStageIntro then
                    Stages.loadStageIntro(stage)
                end
                sendTo(epeer, "S", {stage = stage})
            else
                network_state = "client_connected"
                network_status_msg = "CONNECTED"
            end
        elseif event.type == "disconnect" then
            local was_client = Network.isClient()
            if was_client then
                network_state = "off"
                network_status_msg = "DISCONNECTED"
                -- Client lost the host; bail to title screen
                if Title and Title.loadTitlePage then
                    Title.loadTitlePage()
                end
            else
                network_state = "host_waiting"
                network_status_msg = "PLAYER 2 DISCONNECTED\nWAITING..."
                epeer = nil
                remote_keys.up, remote_keys.down, remote_keys.left, remote_keys.right = false, false, false, false
                remote_fire_pending = false
            end
        elseif event.type == "receive" then
            local data = event.data
            if data and #data >= 1 then
                local mtype = data:sub(1, 1)
                local ok2, payload = pcall(deserialize, data, 2)
                if ok2 then handleMessage(mtype, payload) end
            end
        end
    end
end

-- ----- input transmission (client -> host) -----
-- Send each key transition reliably so the host can never miss a press/release.
-- Fire goes over reliable too; arrives once per actual press.
function Network.sendInput(dt)
    if network_state ~= "client_connected" or not epeer then return end

    local cur = {
        up    = love.keyboard.isDown('up')    or love.keyboard.isDown('w'),
        down  = love.keyboard.isDown('down')  or love.keyboard.isDown('s'),
        left  = love.keyboard.isDown('left')  or love.keyboard.isDown('a'),
        right = love.keyboard.isDown('right') or love.keyboard.isDown('d'),
    }
    for k, v in pairs(cur) do
        if v ~= last_sent_keys[k] then
            sendTo(epeer, "K", {k = k, v = v}, "reliable")
            last_sent_keys[k] = v
        end
    end

    if client_fire_pending then
        sendTo(epeer, "F", {}, "reliable")
        client_fire_pending = false
    end

    -- Force enet to dispatch immediately rather than batching to its next service tick.
    if ehost then pcall(function() ehost:flush() end) end
end

function Network.requestFire()
    client_fire_pending = true
end

function Network.consumeRemoteFire()
    if remote_fire_pending then
        remote_fire_pending = false
        return true
    end
    return false
end

-- ----- snapshot (host -> client) -----
local function packTank(t)
    if not t then return nil end
    return {
        x = t.x, y = t.y, a = t.angle, fr = t.frame, l = t.level,
        hp = t.hp, sh = t.has_shield and true or false, fu = t.fuel or 0,
        pn = t.player_number or 1
    }
end

local function packEnemy(e)
    return {x = e.x, y = e.y, a = e.angle, fr = e.frame or 0, l = e.level, hp = e.hp}
end

local function packBullet(b)
    return {x = b.x, y = b.y, a = b.angle}
end

local function packPickup(p)
    return {x = p.x, y = p.y, t = p.type, ti = p.timer}
end

function Network.broadcastSnapshot(dt)
    if network_state ~= "host_connected" then return end
    snapshot_send_timer = snapshot_send_timer + dt
    if snapshot_send_timer < SNAPSHOT_INTERVAL then return end
    snapshot_send_timer = 0

    -- Pack map_objects compactly
    local map_data = {}
    if map_objects then
        for x_cell, col in pairs(map_objects) do
            for y_cell, sub in pairs(col) do
                local blocks = {}
                for _, blk in ipairs(sub) do
                    blocks[#blocks+1] = {
                        x = blk.x, y = blk.y, sx = blk.sub_x, sy = blk.sub_y,
                        w = blk.width, h = blk.height, t = blk.type,
                        fb = blk.is_full_block and true or false
                    }
                end
                map_data[#map_data+1] = {xc = x_cell, yc = y_cell, b = blocks}
            end
        end
    end

    local snap = {
        gs = game_state,
        st = stage,
        p1 = packTank(player),
        p2 = packTank(player2),
        en = {}, bp = {}, be = {}, pk = {},
        b  = base and {x = base.x, y = base.y, hp = base.hp} or nil,
        sc = {p1 = stage_end.scores.player1_score, p2 = stage_end.scores.player2_score},
        ed = enemies_defeated or 0,
        te = total_enemies_to_spawn or 0,
        go = game_over and true or false,
        gw = game_won and true or false,
        fr = is_freeze and true or false,
        sw = is_steel_wall and true or false,
        mp = map_data,
        k1 = p1_kill_counts,
        k2 = p2_kill_counts,
    }
    if enemies      then for _, e in ipairs(enemies)      do snap.en[#snap.en+1] = packEnemy(e)  end end
    if bullets      then for _, b in ipairs(bullets)      do snap.bp[#snap.bp+1] = packBullet(b) end end
    if enemy_bullets then for _, b in ipairs(enemy_bullets) do snap.be[#snap.be+1] = packBullet(b) end end
    if pickups      then for _, p in ipairs(pickups)      do snap.pk[#snap.pk+1] = packPickup(p) end end

    -- Spawn effects (enemy spawn animation)
    snap.sp = {}
    if spawn_effects then
        for _, sf in ipairs(spawn_effects) do
            snap.sp[#snap.sp+1] = {x = sf.x, y = sf.y, fr = sf.current_frame or 1}
        end
    end

    broadcastAll("T", snap, "unreliable")

    -- Flush batched events reliably (sounds, particles, shake, numbers)
    if #event_queue > 0 then
        broadcastAll("E", {evs = event_queue}, "reliable")
        event_queue = {}
    end

    if ehost then pcall(function() ehost:flush() end) end
end

function Network.applySnapshot()
    local snap = last_snapshot
    if not snap then return end

    if snap.gs and snap.gs ~= game_state then
        game_state = snap.gs
    end
    stage = snap.st or stage

    if snap.p1 then
        player = player or {}
        player.x = snap.p1.x; player.y = snap.p1.y; player.angle = snap.p1.a
        player.frame = snap.p1.fr; player.level = snap.p1.l; player.hp = snap.p1.hp
        player.has_shield = snap.p1.sh; player.fuel = snap.p1.fu
        player.player_number = 1; player.player = 'player'
    end
    if snap.p2 then
        player2 = player2 or {}
        player2.x = snap.p2.x; player2.y = snap.p2.y
        player2.angle = snap.p2.a
        player2.frame = snap.p2.fr; player2.level = snap.p2.l; player2.hp = snap.p2.hp
        player2.has_shield = snap.p2.sh; player2.fuel = snap.p2.fu
        player2.player_number = 2; player2.player = 'player'
    else
        player2 = nil
    end

    enemies = {}
    for _, e in ipairs(snap.en or {}) do
        enemies[#enemies+1] = {
            x = e.x, y = e.y, angle = e.a, frame = e.fr, level = e.l, hp = e.hp,
            score = (enemy_levels and enemy_levels[e.l] and enemy_levels[e.l].score) or 0,
            fuel = 100, fuel_warning_timer = 0
        }
    end

    bullets = {}
    for _, b in ipairs(snap.bp or {}) do
        bullets[#bullets+1] = {x = b.x, y = b.y, angle = b.a}
    end
    enemy_bullets = {}
    for _, b in ipairs(snap.be or {}) do
        enemy_bullets[#enemy_bullets+1] = {x = b.x, y = b.y, angle = b.a}
    end

    pickups = {}
    for _, p in ipairs(snap.pk or {}) do
        pickups[#pickups+1] = {x = p.x, y = p.y, type = p.t, timer = p.ti}
    end

    spawn_effects = {}
    for _, sf in ipairs(snap.sp or {}) do
        spawn_effects[#spawn_effects+1] = {
            x = sf.x, y = sf.y, current_frame = sf.fr, animation_timer = 0, timer = 1
        }
    end

    if snap.b then
        base = base or {}
        base.x = snap.b.x; base.y = snap.b.y; base.hp = snap.b.hp
    end

    map_objects = {}
    for _, entry in ipairs(snap.mp or {}) do
        local sub = {}
        for _, blk in ipairs(entry.b) do
            sub[#sub+1] = {
                x = blk.x, y = blk.y, sub_x = blk.sx, sub_y = blk.sy,
                width = blk.w, height = blk.h, type = blk.t, is_full_block = blk.fb
            }
        end
        map_objects[entry.xc] = map_objects[entry.xc] or {}
        map_objects[entry.xc][entry.yc] = sub
    end

    if snap.sc then
        stage_end.scores.player1_score = snap.sc.p1 or 0
        stage_end.scores.player2_score = snap.sc.p2 or 0
    end
    enemies_defeated = snap.ed or 0
    total_enemies_to_spawn = snap.te or 0
    game_over = snap.go or false
    game_won = snap.gw or false
    is_freeze = snap.fr or false
    is_steel_wall = snap.sw or false
    p1_kill_counts = snap.k1 or p1_kill_counts
    p2_kill_counts = snap.k2 or p2_kill_counts
end

return Network
