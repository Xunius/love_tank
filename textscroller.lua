-- TextScroller class for LÖVE2D

local TextScroller = {}
TextScroller.__index = TextScroller

function TextScroller.new(options)
    local self = setmetatable({}, TextScroller)

    -- Default configuration
    self.texts = options.texts or {"Welcome to the game!"}
    self.font = options.font or love.graphics.newFont(24)
    self.color = options.color or {1, 1, 1, 1} -- white
    self.speed = options.speed or 100 -- pixels per second
    self.repetitions = options.repetitions or -1 -- -1 for infinite
    self.separator = options.separator or "    •    " -- separator between texts
    self.y = options.y or 10 -- vertical position

    -- Internal state
    self.x = love.graphics.getWidth() -- start off-screen right
    self.currentRep = 0
    self.isActive = true
    self.fullText = self:buildFullText()
    self.textWidth = self.font:getWidth(self.fullText)

    return self
end

function TextScroller:buildFullText()
    if #self.texts == 0 then
        return ""
    elseif #self.texts == 1 then
        return self.texts[1]
    else
        return table.concat(self.texts, self.separator)
    end
end

function TextScroller:update(dt)
    if not self.isActive then
        return
    end

    -- Move text to the left
    self.x = self.x - self.speed * dt

    -- Check if text has completely scrolled off screen
    if self.x + self.textWidth < 0 then
        if self.repetitions > 0 then
            self.currentRep = self.currentRep + 1
            if self.currentRep >= self.repetitions then
                self.isActive = false
                return
            end
        end

        -- Reset position for next cycle
        self.x = love.graphics.getWidth()
    end
end

function TextScroller:draw()
    if not self.isActive or self.fullText == "" then
        return
    end

    -- Save current graphics state
    local oldFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    -- Set scroller properties
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.color)

    -- Draw the text
    love.graphics.print(self.fullText, self.x, self.y)

    -- Restore graphics state
    love.graphics.setFont(oldFont)
    love.graphics.setColor(r, g, b, a)
end

-- Methods to control the scroller
function TextScroller:setTexts(texts)
    self.texts = texts or {}
    self.fullText = self:buildFullText()
    self.textWidth = self.font:getWidth(self.fullText)
end

function TextScroller:addText(text)
    table.insert(self.texts, text)
    self.fullText = self:buildFullText()
    self.textWidth = self.font:getWidth(self.fullText)
end

function TextScroller:setFont(font)
    self.font = font
    self.textWidth = self.font:getWidth(self.fullText)
end

function TextScroller:setColor(r, g, b, a)
    self.color = {r, g or r, b or r, a or 1}
end

function TextScroller:setSpeed(speed)
    self.speed = speed
end

function TextScroller:setRepetitions(reps)
    self.repetitions = reps
    if reps > 0 then
        self.currentRep = 0
    end
end

function TextScroller:start()
    self.isActive = true
    self.x = love.graphics.getWidth()
    self.currentRep = 0
end

function TextScroller:stop()
    self.isActive = false
end

function TextScroller:reset()
    self.x = love.graphics.getWidth()
    self.currentRep = 0
    self.isActive = true
end

function TextScroller:isFinished()
    return not self.isActive
end

return TextScroller
