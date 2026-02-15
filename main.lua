-- Global_Variables_Like_So
-- local_variables_like_so
-- CONSTANTS_LIKE_SO

function love.load()
    -- Virtual resolution
    VIRTUAL_WIDTH = 375
    VIRTUAL_HEIGHT = 667

    -- Get actual screen size
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()

    -- Calculate how much to scale by
    Scale_X = window_width / VIRTUAL_WIDTH
    Scale_Y = window_height / VIRTUAL_HEIGHT
    Scale = math.min(Scale_X, Scale_Y)

    -- Calculate black bars offset
    Offset_X = (window_width - (VIRTUAL_WIDTH * Scale)) / 2
    Offset_Y = (window_height - (VIRTUAL_HEIGHT * Scale)) / 2

    -- Cards
    Cards = {}
    Card_Width = 90
    Card_Height = 140

    -- Padding around entire app
    Screen_X_Padding = 30
    Screen_Y_Padding = 40

    -- Top info area
    Info_Height = 150
    Info_Area_Padding = 20

    -- Card area
    Card_Area_Padding = 20
    Card_Area_Height = VIRTUAL_HEIGHT - Info_Height - (2 * Card_Area_Padding) - (2 * Screen_Y_Padding)
    Card_Area_Width = VIRTUAL_WIDTH - (2 * (Screen_X_Padding + Card_Area_Padding))

    -- Card stack positioning
    Card_Stack_Left_TL = {
        x = Screen_X_Padding + Card_Area_Padding,
        y = Screen_Y_Padding + Info_Height + Card_Area_Padding
    }
    Card_Stack_Right_TL = {
        x = Card_Stack_Left_TL.x + Card_Area_Width - Card_Width,
        y = Screen_Y_Padding + Info_Height + Card_Area_Padding
    }

    Num_Cards_In_Stack = 7
    Card_Stack_Left_BL = {
        x = Card_Stack_Left_TL.x,
        y = Card_Stack_Left_TL.y + Card_Area_Height
    }
    Card_Stack_Right_BL = {
        x = Card_Stack_Right_TL.x,
        y = Card_Stack_Right_TL.y + Card_Area_Height
    }

    -- Load buttons
    Buttons = {
        left_stack = {
            x = Card_Stack_Left_TL.x,
            y = Card_Stack_Left_TL.y,
            width = Card_Width,
            height = Card_Area_Height
        },
        right_stack = {
            x = Card_Stack_Right_TL.x,
            y = Card_Stack_Right_TL.y,
            width = Card_Width,
            height = Card_Area_Height
        }
    }

    -- Hands
    Left_Hand = {}
    Right_Hand = {}
end

function love.update(dt)
end

local function draw_layout_guides()
    love.graphics.setColor(1, 0, 0, 0.5)

    -- Draw boundary all around
    love.graphics.rectangle("line",
                            Screen_X_Padding,
                            Screen_Y_Padding,
                            VIRTUAL_WIDTH - (2 * Screen_X_Padding),
                            VIRTUAL_HEIGHT - (2 * Screen_Y_Padding)
    )

    -- Draw top info area
    love.graphics.rectangle("line",
                            Screen_X_Padding,
                            Screen_Y_Padding,
                            VIRTUAL_WIDTH - (2 * Screen_X_Padding),
                            Info_Height
    )

    -- Draw top info box
    love.graphics.rectangle("line",
                            Screen_X_Padding + Info_Area_Padding,
                            Screen_Y_Padding + Info_Area_Padding,
                            VIRTUAL_WIDTH - (2 * (Screen_X_Padding + Info_Area_Padding)),
                            Info_Height - (2 * Info_Area_Padding)
    )

    -- Draw card box
    love.graphics.rectangle("line",
                            Screen_X_Padding + Card_Area_Padding,
                            Screen_Y_Padding + Info_Height + Card_Area_Padding,
                            Card_Area_Width,
                            Card_Area_Height
    )

    -- Draw card levels
    for i = 1, Num_Cards_In_Stack do
        local hue = i / Num_Cards_In_Stack  -- 0 to 1
        love.graphics.setColor(
            0.5 + 0.5 * math.sin(hue * math.pi * 2),
            0.5 + 0.5 * math.sin((hue + 0.33) * math.pi * 2),
            0.5 + 0.5 * math.sin((hue + 0.67) * math.pi * 2)
        )

        local y_left = Card_Stack_Left_BL.y - Card_Height - ((i - 1) * ((Card_Area_Height - Card_Height) / (Num_Cards_In_Stack - 1)))
        love.graphics.rectangle("fill",
                                Card_Stack_Left_TL.x,
                                y_left,
                                Card_Width,
                                Card_Height
        )

        local y_right = Card_Stack_Right_BL.y - Card_Height - ((i - 1) * ((Card_Area_Height - Card_Height) / (Num_Cards_In_Stack - 1)))
        love.graphics.rectangle("fill",
                                Card_Stack_Right_TL.x,
                                y_right,
                                Card_Width,
                                Card_Height
        )
    end
end

function love.draw()
    -- Apply scaling transformation
    love.graphics.push()
    love.graphics.translate(Offset_X, Offset_Y)   -- move origin point
    love.graphics.scale(Scale, Scale)

    -- Draw at VIRTUAL coordinates (375x667)
    love.graphics.clear(0.1, 0.2, 0.3)          -- fill screen with color
    love.graphics.setColor(1, 1, 1)

    -- Draw cards
    love.graphics.setColor(1, 1, 1)
    for i, card in ipairs(Cards) do
        love.graphics.rectangle("fill", card.x, card.y, Card_Width, Card_Height)
    end

    -- Stop scaling
    love.graphics.pop()

    -- Draw zones on screen
    draw_layout_guides()
end

function love.touchpressed(id, x, y)
    -- Convert to virtual coordinates
    local virtual_x = (x - Offset_X) / Scale
    local virtual_y = (y - Offset_Y) / Scale

    -- -- Add new card at touch position
    -- local newCard = {
    --     x = virtual_x - Card_Width / 2,
    --     y = virtual_y - Card_Height / 2
    -- }

    -- table.insert(Cards, newCard)

    local function is_point_in_rect(point_x, point_y, rect)
        return point_x >= rect.x and point_x <= rect.x + rect.width and
               point_y >= rect.y and point_y <= rect.y + rect.height
    end

    if is_point_in_rect(virtual_x, virtual_y, Buttons.left_stack) then
        print("Left draw pile clicked")
    elseif is_point_in_rect(virtual_x, virtual_y, Buttons.right_stack) then
        print("Right draw pile clicked")
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        love.touchpressed("id", x, y)
    end
end