local Combat = {}

function Combat.playerFire(player)

    if player.fire_timer <= 0 then
        Combat.spawnBullet(player, 'PlayerBullet')
        VFX.addMuzzleFlash(player.x, player.y, player.angle)
        Audio.playSound("player_shoot")
        -- reset timer
        player.fire_timer = player_levels[player.level].fire_timer

        -- schedule a second shot with a small delay (e.g. 0.15s)
        if player.bullet_count > 1 then
            table.insert(scheduledShots, {
                delay = 0.05,  -- seconds until second shot
                shooter = player
            })
        end
    end
end

function Combat.updatePlayerBullets(dt)

    -- Update player bullets
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        if bullet.destroyed or bullet.collider:isDestroyed() then
            if not bullet.collider:isDestroyed() then
                bullet.collider:destroy()
            end
            table.remove(bullets, i)
            -- reset timer for the bullet's owner
            local owner = bullet.tank
            if owner then owner.fire_timer = 0 end
        else
            bullet.x, bullet.y = bullet.collider:getPosition()

            if bullet.collider:enter('Enemy') then
                local collision_data = bullet.collider:getEnterCollisionData('Enemy')
                if collision_data then
                    local enemy = collision_data.collider:getObject()
                    if enemy and enemy.hp > -1 then
                        enemy.hp = enemy.hp - 1

                        -- Visual effects for enemy hit
                        VFX.addParticleEffect(bullet.x, bullet.y, "spark")
                        VFX.addExplosion(bullet.x, bullet.y, 3)
                        VFX.addDamageNumber(enemy.x, enemy.y - 20, 1)
                        VFX.addScreenShake(0.2, 5)

                        if enemy.hp == 0 then
                            Entities.addEnemyDeadEffects(enemy)
                            VFX.addScoreNumber(enemy.x - cell_size / 2, enemy.y - 20, enemy.score)
                            -- Credit kill to correct player
                            local owner = bullet.tank
                            if owner and owner.player_number == 2 then
                                p2_kill_counts[enemy.level] = p2_kill_counts[enemy.level] + 1
                                stage_end.scores['player2_score'] = stage_end.scores['player2_score'] + enemy.score
                            else
                                p1_kill_counts[enemy.level] = p1_kill_counts[enemy.level] + 1
                                stage_end.scores['player1_score'] = stage_end.scores['player1_score'] + enemy.score
                            end
                        elseif enemy.hp == -1 and world_expanded then
                            Combat.dropPickup(enemy.x, enemy.y)
                        else
                            Audio.playSound("metal_hit", enemy.x, enemy.y, true)
                            Combat.applyBulletPush(bullet, enemy)
                        end
                    end
                    Combat.destroyBullet(bullet)
                end
            end

            if bullet.collider:enter('Brick') then
                local collision_data = bullet.collider:getEnterCollisionData('Brick')
                if collision_data then
                    local block = collision_data.collider:getObject()
                    if block then
                        Map.BreakBrick(bullet, block)

                        VFX.addParticleEffect(bullet.x, bullet.y, "dust")
                        VFX.addScreenShake(0.15, 3)
                        Map.destroyBlock(block)
                        Combat.destroyBullet(bullet)
                        Audio.playSound("brick_hit", bullet.x, bullet.y, true)
                        if world_expanded then
                            Combat.dropPickup(block.x + cell_size / 2, block.y + cell_size / 2)
                        end
                    end
                end
            end

            if bullet.collider:enter('Steel') then
                local bullet_owner = bullet.tank
                if bullet_owner and bullet_owner.level >= 4 then
                    local collision_data = bullet.collider:getEnterCollisionData('Steel')
                    if collision_data then
                        local block = collision_data.collider:getObject()
                        if block then
                            VFX.addParticleEffect(bullet.x, bullet.y, "spark")
                            VFX.addScreenShake(0.15, 3)
                            Map.destroyBlock(block)
                            Combat.destroyBullet(bullet)
                            Audio.playSound("metal_hit", bullet.x, bullet.y, true)
                            if world_expanded then
                                Combat.dropPickup(block.x + cell_size / 2, block.y + cell_size / 2)
                            end
                        end
                    end
                else
                    VFX.addParticleEffect(bullet.x, bullet.y, "spark")
                    VFX.addScreenShake(0.1, 2)
                    Combat.destroyBullet(bullet)
                    Audio.playSound("metal_hit", bullet.x, bullet.y, true)
                end
            end

            if bullet.collider:enter('Border') then
                VFX.addParticleEffect(bullet.x, bullet.y, "spark")
                Audio.playSound("metal_hit", bullet.x, bullet.y, true)
                Combat.destroyBullet(bullet)
            end

            if bullet.collider:enter('Base') then
                local collision_data = bullet.collider:getEnterCollisionData('Base')
                if collision_data and base and base.hp and base.hp > 0 then
                    base.hp = base.hp - 1
                    VFX.addParticleEffect(base.x, base.y, "explosion")
                    VFX.addExplosion(base.x, base.y, 5)
                    VFX.addScreenShake(0.25, 8)
                    Audio.playSound("explosion", base.x, base.y, true)
                    VFX.addExplosion(bullet.x, bullet.y, 3)
                    Combat.destroyBullet(bullet)
                    if base.collider and not base.collider:isDestroyed() then
                        base.collider:setSensor(true)
                    end
                end
            end

            if bullet.collider:enter('PlayerBullet') then
                local collision_data = bullet.collider:getEnterCollisionData('PlayerBullet')
                if collision_data then
                    local other_bullet = collision_data.collider:getObject()
                    if other_bullet then
                        VFX.addParticleEffect(bullet.x, bullet.y, "spark")
                        VFX.addScreenShake(0.1, 3)
                        Combat.destroyBullet(other_bullet)
                        Combat.destroyBullet(bullet)
                    end
                end
            end

            if bullet.x < -100 or bullet.x > world_width + 100 or
               bullet.y < -100 or bullet.y > world_height + 100 then
                Combat.destroyBullet(bullet)
            end
        end
    end
end

function Combat.updateEnemyBullets(dt)
    -- Update enemy bullets
    for i = #enemy_bullets, 1, -1 do
        local bullet = enemy_bullets[i]
        if bullet.destroyed or bullet.collider:isDestroyed() then
            if not bullet.collider:isDestroyed() then
                bullet.collider:destroy()
            end
            table.remove(enemy_bullets, i)
        else
            bullet.x, bullet.y = bullet.collider:getPosition()

            if bullet.collider:enter('Player') then
                local collision_data = bullet.collider:getEnterCollisionData('Player')
                local hit_player = player
                if collision_data and collision_data.collider:getObject() then
                    hit_player = collision_data.collider:getObject()
                end

                if not hit_player then
                    Combat.destroyBullet(bullet)
                elseif hit_player.has_shield then
                    Combat.destroyBullet(bullet)
                else
                    Stages.changePlayerLevel(hit_player, -3)
                    VFX.addParticleEffect(bullet.x, bullet.y, "spark")
                    VFX.addExplosion(bullet.x, bullet.y, 3)
                    VFX.addDamageNumber(hit_player.x, hit_player.y - 20, 1)

                    if hit_player.level <= 0 then
                        VFX.addExplosion(hit_player.x, hit_player.y, 5)
                        VFX.addScreenShake(0.25, 6)
                        Audio.playSound("explosion", hit_player.x, hit_player.y, true)

                        hit_player.hp = hit_player.hp - 1
                        hit_player.collider:destroy()
                        local pnum = hit_player.player_number or 1
                        local respawned = Entities.spawnPlayer(true, starting_player_level, pnum)
                        if pnum == 1 then
                            player = respawned
                        else
                            player2 = respawned
                        end
                    else
                        VFX.addExplosion(hit_player.x, hit_player.y, 3)
                        VFX.addScreenShake(0.10, 3)
                        Audio.playSound("metal_hit", hit_player.x, hit_player.y, true)
                        Combat.applyBulletPush(bullet, hit_player)
                    end

                    Combat.destroyBullet(bullet)
                end
            end

            if bullet.collider:enter('Enemy') then
                local collision_data = bullet.collider:getEnterCollisionData('Enemy')
                if collision_data then
                    local enemy = collision_data.collider:getObject()
                    if enemy then
                        local firing_tank = bullet.tank
                        local vx, vy = bullet.collider:getLinearVelocity()
                        if firing_tank ~= enemy then
                            Audio.playSound("metal_hit", enemy.x, enemy.y, false)
                            Combat.applyBulletPush(bullet, enemy)
                            Combat.destroyBullet(bullet)
                            --if enemy and enemy.hp > -1 then
                                --enemy.hp = enemy.hp - 1
                            --end
                        end
                    end
                end
            end

            if bullet.collider:enter('Brick') then
                local collision_data = bullet.collider:getEnterCollisionData('Brick')
                if collision_data then
                    local block = collision_data.collider:getObject()
                    if block then
                        Map.BreakBrick(bullet, block)
                        VFX.addParticleEffect(bullet.x, bullet.y, "dust")
                        Map.destroyBlock(block)
                        Combat.destroyBullet(bullet)
                        Audio.playSound('brick_hit', bullet.x, bullet.y, false)
                    end
                end
            end

            if bullet.collider:enter('Steel') then
                VFX.addParticleEffect(bullet.x, bullet.y, "spark")
                Combat.destroyBullet(bullet)
                Audio.playSound('metal_hit', bullet.x, bullet.y, false)
            end

            if bullet.collider:enter('Base') then
                local collision_data = bullet.collider:getEnterCollisionData('Base')
                if collision_data and base and base.hp and base.hp > 0 then
                    base.hp = base.hp - 1
                    VFX.addParticleEffect(base.x, base.y, "explosion")
                    VFX.addExplosion(base.x, base.y, 5)
                    VFX.addScreenShake(0.25, 8)
                    Audio.playSound("explosion", base.x, base.y, true)
                    Combat.destroyBullet(bullet)
                    if base.collider and not base.collider:isDestroyed() then
                        base.collider:setSensor(true)
                    end
                end
            end

            if bullet.collider:enter('Border') then
                VFX.addParticleEffect(bullet.x, bullet.y, "spark")
                Audio.playSound("metal_hit", bullet.x, bullet.y, true)
                Combat.destroyBullet(bullet)
            end

            if bullet.collider:enter('PlayerBullet') then
                local collision_data = bullet.collider:getEnterCollisionData('PlayerBullet')
                if collision_data then
                    local other_bullet = collision_data.collider:getObject()
                    if other_bullet then
                        VFX.addParticleEffect(bullet.x, bullet.y, "spark")
                        VFX.addScreenShake(0.1, 3)
                        Combat.destroyBullet(other_bullet)
                        Combat.destroyBullet(bullet)
                    end
                end
            end

            if bullet.collider:enter('EnemyBullet') then
                local collision_data = bullet.collider:getEnterCollisionData('EnemyBullet')
                if collision_data then
                    local other_bullet = collision_data.collider:getObject()
                    if other_bullet then
                        VFX.addParticleEffect(bullet.x, bullet.y, "spark")
                        VFX.addScreenShake(0.1, 3)
                        Combat.destroyBullet(other_bullet)
                        Combat.destroyBullet(bullet)
                    end
                end
            end

            if bullet.x < -100 or bullet.x > world_width + 100 or
               bullet.y < -100 or bullet.y > world_height + 100 then
                Combat.destroyBullet(bullet)
            end
        end
    end
end

function Combat.spawnBullet(tank, collision_class)
    local x = tank.x
    local y = tank.y
    local angle = tank.angle

    local bullet = {}
    bullet.tank = tank
    bullet.x = x
    bullet.y = y
    bullet.angle = angle
    bullet.speed = bullet_speed
    bullet.is_bullet = true
    bullet.destroyed = false
    bullet.collision_class = collision_class

    bullet.collider = world:newCircleCollider(x, y, 4)
    bullet.collider:setCollisionClass(collision_class)
    bullet.collider:setBullet(true)
    bullet.collider:setObject(bullet)

    bullet.collider:setPreSolve(function(collider_1, collider_2, contact)
        local c1obj = collider_1:getObject()
        local c2obj = collider_2:getObject()
        if c1obj and c2obj == c1obj.tank then
            contact:setEnabled(false)
        else
            contact:setEnabled(true)
        end
    end)

    local vx = math.cos(angle - math.pi/2) * bullet.speed
    local vy = math.sin(angle - math.pi/2) * bullet.speed
    bullet.vx = vx
    bullet.vy = vy
    bullet.collider:setLinearVelocity(vx, vy)

    if collision_class == 'PlayerBullet' then
        table.insert(bullets, bullet)
    else
        table.insert(enemy_bullets, bullet)
    end

    return bullet
end

function Combat.spawnPickup(x, y, pick_type)
    local no_existing = true
    for _, p in ipairs(pickups) do
        if math.abs(p.x - x) <= cell_size / 2 or math.abs(p.y - y) <= cell_size / 2 then
            no_existing = false
            break
        end
    end
    if no_existing then
        local pickup = {
            x = x,
            y = y,
            type = pick_type,
            timer = 10 -- seconds before disappearing
        }
        pickup.collider = world:newRectangleCollider(x - 8, y - 8, full_sprite_width, full_sprite_height)
        pickup.collider:setCollisionClass('Pickup')
        pickup.collider:setType('static')
        pickup.collider:setObject(pickup)
        table.insert(pickups, pickup)
    end
end

function Combat.applyBulletPush(bullet, tank)

    --local vx, vy = bullet.collider:getLinearVelocity()
    local vx = bullet.vx
    local vy = bullet.vy
    if math.abs(vx) > math.abs(vy) then
        vy = 0
    else
        vx = 0
    end
    tank.collider:applyLinearImpulse(vx*10, vy*10)
end

function Combat.dropPickup(x, y)
    local total_weight = 0
    for _, weight in ipairs(pickup_weights) do
        total_weight = total_weight + weight
    end

    local random_value = math.random() * total_weight
    local cumulative_weight = 0

    for i, weight in ipairs(pickup_weights) do
        cumulative_weight = cumulative_weight + weight
        if random_value <= cumulative_weight then
            Combat.spawnPickup(x, y, pickup_types[i].type)
            break
        end
    end
end

function Combat.destroyBullet(bullet)
    if bullet and not bullet.destroyed then
        bullet.destroyed = true
    end
end

return Combat
