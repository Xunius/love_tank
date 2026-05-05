local Assets = {}

function Assets.removeBlackPixels(imageData)
    imageData:mapPixel(function(x, y, r, g, b, a)
        if x <= full_sprite_width * 16 and r == 0 and g == 0 and math.abs(b - 0.0039) <= 0.001 then
            return r, g, b, 0 -- Set alpha to 0
        elseif x > full_sprite_width * 18 and x <= full_sprite_width * 23 and y >= 10 * full_sprite_height and y <= 11 * full_sprite_height - 1 and r == 0 and g == 0 and math.abs(b - 0.0039) <= 0.001 then
            return r, g, b, 0 -- Set alpha to 0
        end
        return r, g, b, a
    end)
end

local function createBulletQuad()
    local row = 6
    local col = 20
    local sprite_width = 8
    local sprite_height = 8
    local x = col * full_sprite_width
    local y = row * full_sprite_height + 4

    local quad = love.graphics.newQuad(
            x, y,
            sprite_width, sprite_height,
            spritesheet
        )
    return quad
end


local function createStarQuads()
    local sprite_width = 16
    local sprite_height = 16
    local row = 6
    local start_col = 16

    local star_quads = {}

    for i = 0, 3 do
        local x = (start_col + i) * sprite_width
        local y = row * sprite_height

        star_quads[i + 1] = love.graphics.newQuad(
            x, y,
            sprite_width, sprite_height,
            spritesheet
        )
    end

    return star_quads
end


local function createPlayerQuads()
    local sprite_width = 16
    local sprite_height = 16
    local start_col = 0
    local start_row = 0

    local quads = {}

    for i = 1, 4 do
        for j = 0, 1 do
            quads[i] = quads[i] or {}
            local y = (start_row + i - 1) * sprite_height
            local x = (start_col + j) * sprite_width

            quads[i][j] = love.graphics.newQuad(
                x, y,
                sprite_width, sprite_height,
                spritesheet
            )
        end
    end

    return quads
end


local function create2ndPlayerQuads()
    local sprite_width = 16
    local sprite_height = 16
    local start_col = 0
    local start_row = 8

    local quads = {}

    for i = 1, 4 do
        for j = 0, 1 do
            quads[i] = quads[i] or {}
            local y = (start_row + i - 1) * sprite_height
            local x = (start_col + j) * sprite_width

            quads[i][j] = love.graphics.newQuad(
                x, y,
                sprite_width, sprite_height,
                spritesheet
            )
        end
    end

    return quads
end


local function createEnemyQuads()

    -- loop through levels
    local function createEnemyQuadsSingleColor(start_col, start_row)

        local sprite_width = 16
        local sprite_height = 16
        local quads = {}

        for i = 1, 4 do
            -- loop through 2 animation states
            for j = 0, 1 do
                quads[i] = quads[i] or {}

                local y = (start_row + i - 1) * sprite_height
                local x = (start_col + j) * sprite_width

                quads[i][j] = love.graphics.newQuad(
                    x, y,
                    sprite_width, sprite_height,
                    spritesheet)
            end
        end
        return quads
    end

    local quads = {}

    -- silver color
    local start_col = 8
    local start_row = 4
    quads['silver'] = createEnemyQuadsSingleColor(start_col, start_row)

    -- red color
    local start_col = 8
    local start_row = 12
    quads['red'] = createEnemyQuadsSingleColor(start_col, start_row)

    -- green color
    local start_col = 0
    local start_row = 12
    quads['green'] = createEnemyQuadsSingleColor(start_col, start_row)

    -- gold color
    local start_col = 0
    local start_row = 4
    quads['gold'] = createEnemyQuadsSingleColor(start_col, start_row)

    return quads
end


local function createPickupQuads()
    local sprite_width = 16
    local sprite_height = 16
    local row = 7
    local start_col = 16

    local quads = {}

    for i = 1, #pickup_types, 1 do

        local x = (start_col + i - 1) * sprite_width
        local y = row * sprite_height
        local pickup = pickup_types[i]

        quads[pickup.type] = love.graphics.newQuad(
            x, y,
            sprite_width, sprite_height,
            spritesheet
        )
    end

    return quads
end


local function createShieldQuads()
    local sprite_width = 16
    local sprite_height = 16
    local row = 9
    local start_col = 17

    local quads = {}

    for i = 0, 1 do

        local x = (start_col + i - 1) * sprite_width
        local y = row * sprite_height

        quads[i] = love.graphics.newQuad(
            x, y,
            sprite_width, sprite_height,
            spritesheet
        )
    end

    return quads
end


local function createBaseQuads()
    local sprite_width = 16
    local sprite_height = 16
    local row = 2
    local start_col = 19

    local quads = {}

    for i = 0, 1 do

        local x = (start_col + i) * sprite_width
        local y = row * sprite_height

        quads[i] = love.graphics.newQuad(
            x, y,
            sprite_width, sprite_height,
            spritesheet
        )
    end

    return quads
end


local function createBrickQuads()

    local row = 0
    local start_col = 16
    local quads = {}

    -- full block
    local x = start_col * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 16
    local sprite_height = 16

    quads['brick'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- right column wall
    local x = (start_col + 1) * full_sprite_width + full_sprite_width / 2
    local y = row * full_sprite_height
    local sprite_width = 8
    local sprite_height = 16

    quads['brick_right'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- bottom column wall
    local x = (start_col + 2) * full_sprite_width
    local y = row * full_sprite_height + full_sprite_width / 2
    local sprite_width = 16
    local sprite_height = 8

    quads['brick_bottom'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- left column wall
    local x = (start_col + 3) * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 8
    local sprite_height = 16

    quads['brick_left'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- top column wall
    local x = (start_col + 4) * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 16
    local sprite_height = 8

    quads['brick_top'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- quarter brick
    local x = start_col * full_sprite_width
    local y = 4 * full_sprite_height
    local sprite_width = 8
    local sprite_height = 8

    quads['brick_quarter'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- quarter right column
    local x = start_col * full_sprite_width + full_sprite_width * 3 / 4
    local y = 4 * full_sprite_height
    local sprite_width = 4
    local sprite_height = 8

    quads['brick_quarter_right'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)


    -- quarter bottom row
    local x = start_col * full_sprite_width + full_sprite_width
    local y = 4 * full_sprite_height + full_sprite_height / 4
    local sprite_width = 8
    local sprite_height = 4

    quads['brick_quarter_bottom'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)


    -- quarter left column
    local x = start_col * full_sprite_width + full_sprite_width * 1.5
    local y = 4 * full_sprite_height
    local sprite_width = 4
    local sprite_height = 8

    quads['brick_quarter_left'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)


    -- quarter top row
    local x = start_col * full_sprite_width + full_sprite_width * 2
    local y = 4 * full_sprite_height
    local sprite_width = 8
    local sprite_height = 4

    quads['brick_quarter_top'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    return quads
end


local function createSteelQuads()

    local row = 1
    local start_col = 16
    local quads = {}

    -- full block
    local x = start_col * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 16
    local sprite_height = 16

    quads['steel'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- right column wall
    local x = (start_col + 1) * full_sprite_width + full_sprite_width / 2
    local y = row * full_sprite_height
    local sprite_width = 8
    local sprite_height = 16

    quads['steel_right'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- bottom column wall
    local x = (start_col + 2) * full_sprite_width
    local y = row * full_sprite_height + full_sprite_width / 2
    local sprite_width = 16
    local sprite_height = 8

    quads['steel_bottom'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- left column wall
    local x = (start_col + 3) * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 8
    local sprite_height = 16

    quads['steel_left'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- top column wall
    local x = (start_col + 4) * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 16
    local sprite_height = 8

    quads['steel_top'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- quarter brick
    local x = start_col * full_sprite_width
    local y = 4 * full_sprite_height + full_sprite_height / 2
    local sprite_width = 8
    local sprite_height = 8

    quads['steel_quarter'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    return quads
end


local function createWaterGrassIceQuads()

    local row = 2
    local start_col = 16
    local quads = {}

    -- water block
    local x = start_col * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 16
    local sprite_height = 16

    quads['water'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- water block 2
    local x = start_col * full_sprite_width
    local y = (row + 1) * full_sprite_height
    local sprite_width = 16
    local sprite_height = 16

    quads['water2'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- water block 3
    local x = (start_col + 1) * full_sprite_width
    local y = (row + 1) * full_sprite_height
    local sprite_width = 16
    local sprite_height = 16

    quads['water3'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- grass block
    local x = (start_col + 1) * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 16
    local sprite_height = 16

    quads['grass'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)


    -- ice block
    local x = (start_col + 2) * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 16
    local sprite_height = 16

    quads['ice'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- water quater 1
    local x = start_col * full_sprite_width
    local y = 5 * full_sprite_height
    local sprite_width = 8
    local sprite_height = 8

    quads['water_quarter'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- water quater 2
    local x = start_col  * full_sprite_width + full_sprite_width * 0.5
    local y = 5 * full_sprite_height
    local sprite_width = 8
    local sprite_height = 8

    quads['water_quarter2'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- water quater 3
    local x = start_col * full_sprite_width + full_sprite_width
    local y = 5 * full_sprite_height
    local sprite_width = 8
    local sprite_height = 8

    quads['water_quarter3'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- grass quater
    local x = start_col * full_sprite_width + full_sprite_width / 2
    local y = 4 * full_sprite_height + full_sprite_height / 2
    local sprite_width = 8
    local sprite_height = 8

    quads['grass_quarter'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- ice quater
    local x = start_col * full_sprite_width + full_sprite_width
    local y = 4 * full_sprite_height + full_sprite_height / 2
    local sprite_width = 8
    local sprite_height = 8

    quads['ice_quarter'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    return quads
end



local function createUIQuads()

    local quads = {}

    -- panel
    local row = 0
    local start_col = 23
    local x = start_col * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 32
    local sprite_height = 15 * full_sprite_height

    quads['panel'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- tank label
    local x = 20 * full_sprite_width
    local y = 12 * full_sprite_height
    local sprite_width = 8
    local sprite_height = 8

    quads['tank'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)


    -- empty
    local row = 0
    local start_col = 23
    local x = start_col * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 8
    local sprite_height = 8

    quads['empty'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- stage
    local x = 20.5 * full_sprite_width + 1
    local y = 11 * full_sprite_height
    local sprite_width = 2.5 * full_sprite_width
    local sprite_height = full_sprite_height / 2

    quads['stage'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- gameover
    local x = 18 * full_sprite_width
    local y = 11.5 * full_sprite_height
    local sprite_width = 2 * full_sprite_width
    local sprite_height = full_sprite_height

    quads['gameover'] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- 0 - 9
    local start_row = 11.5 * full_sprite_width
    local start_col = 20.5 * full_sprite_height + 1
    local ncols = 5
    local sprite_width = 8
    local sprite_height = 8

    for i = 0, 9 do
        local ci = i % ncols
        local ri = math.floor(i / ncols)
        local x = start_col + ci * sprite_width
        local y = start_row + ri * sprite_height
        quads[tostring(i)] = love.graphics.newQuad(
            x, y,
            sprite_width, sprite_height,
            spritesheet)
    end

    -- 100 - 500
    local start_row = 9 * full_sprite_width
    local start_col = 18 * full_sprite_height
    local ncols = 5
    local sprite_width = 16
    local sprite_height = 16

    for i = 0, 4 do
        local x = start_col + i * sprite_width
        local y = start_row + sprite_height
        quads[tostring((i+1)*100)] = love.graphics.newQuad(
            x, y,
            sprite_width, sprite_height,
            spritesheet)
    end
    return quads
end


local function createExplosionQuads()

    local quads = {}

    -- 1
    local row = 8
    local col = 16
    local x = col * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 16
    local sprite_height = 16

    quads[1] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- 2
    local row = 8
    local col = 17
    local x = col * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 16
    local sprite_height = 16

    quads[2] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- 3
    local row = 8
    local col = 18
    local x = col * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 16
    local sprite_height = 16

    quads[3] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- 4
    local row = 8
    local col = 19
    local x = col * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 32
    local sprite_height = 32

    quads[4] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    -- 5
    local row = 8
    local col = 21
    local x = col * full_sprite_width
    local y = row * full_sprite_height
    local sprite_width = 32
    local sprite_height = 32

    quads[5] = love.graphics.newQuad(
        x, y,
        sprite_width, sprite_height,
        spritesheet)

    return quads
end

local function mergeAll(...)
    local result = {}
    local tables = {...}
    for _, t in ipairs(tables) do
        for k, v in pairs(t) do
            result[k] = v
        end
    end
    return result
end

function Assets.loadImages()

    full_sprite_width = 16
    full_sprite_height = 16

    --player_image = love.graphics.newImage("assets/player_tank.png")
    --enemy_image = love.graphics.newImage("assets/player_tank.png")
    --brick_image = love.graphics.newImage("assets/brick.png")
    --steel_image = love.graphics.newImage("assets/steel.png")
    --grass_image = love.graphics.newImage("assets/grass.png")
    --water_image = love.graphics.newImage("assets/water.png")
    bullet_image = love.graphics.newImage("assets/bullet.png")
    --base_image = love.graphics.newImage("assets/smm.jpg")
    --base_lose_image = love.graphics.newImage("assets/smm_lose.png")
    title_image = love.graphics.newImage("assets/Battle-city.png")
    arrow_image = love.graphics.newImage("assets/arrow.png")

    --spritesheet = love.graphics.newImage("assets/spritesheet.png")
    local imageData = love.image.newImageData("assets/spritesheet.png")

    -- change black to transparent
    Assets.removeBlackPixels(imageData)
    spritesheet = love.graphics.newImage(imageData)

    --bullet_quad = createBulletQuad()
    star_quads = createStarQuads()
    player_quads = createPlayerQuads()
    enemy_quads = createEnemyQuads()
    pickup_quads = createPickupQuads()
    shield_quads = createShieldQuads()
    base_quads = createBaseQuads()
    brick_quads = createBrickQuads()
    steel_quads = createSteelQuads()
    watergrassice_quads = createWaterGrassIceQuads()
    ui_quads = createUIQuads()
    explosion_quads = createExplosionQuads()
    player2_quads = create2ndPlayerQuads()

    -- combine map object quads
    map_objects_quads = mergeAll(brick_quads, steel_quads, watergrassice_quads)

end

return Assets
