-- Global_Variables_Like_So
-- local_variables_like_so
-- CONSTANTS_LIKE_SO

local function init_deck()
    -- Clear out deck if needed
    for k, v in pairs(Deck) do Deck[k] = nil end

    -- Add value cards to deck
    for card_value = 1, Num_Cards_In_Stack do
        for i = 1, card_value do
            table.insert(Deck, {
                value = card_value,
            })
        end
    end

    -- Add other cards to deck

    -- Shuffle deck
    for i = #Deck, 2, -1 do
        local j = love.math.random(1, i)
        Deck[i], Deck[j] = Deck[j], Deck[i]
    end
end


function love.load()
    love.math.setRandomSeed(love.timer.getTime() * 1000)

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

    Num_Cards_In_Stack = 5
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
        },
    }

    -- Score
    Score = 0

    -- Hands
    Left_Hand = {}
    Right_Hand = {}

    -- Deck
    Deck = {}
    init_deck()

    -- Duplicate management
    -- Length of these is either 0 or 2, 0 == no duplicate, 2 == duplicate
    Left_Hand_Duplicate_Indices = {}
    Right_Hand_Duplicate_Indices = {}

    -- Detect swipes
    Active_Touches = {}
    Swipe_Threshold = 50
    Swipe_Time_Limit = 0.5
    Hold_Duration = 0.5
    Tap_Max_Distance = 10
    Tap_Max_Duration = 0.3
end

function love.update(dt)
    -- Check for hold
    for id, touch in pairs(Active_Touches) do
        if not touch.hold_triggered then
            local hold_time = love.timer.getTime() - touch.start_time
            if hold_time >= Hold_Duration then
                print("Hold detected at " .. touch.start_x .. ", " .. touch.start_y)
                touch.hold_triggered = true
            end
        end
    end
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

    -- Draw left hand
    for i, card in ipairs(Left_Hand) do
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
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(card.value .. " * " .. i, Card_Stack_Left_BL.x + Card_Width / 3, y_left + Card_Height - 20)
    end

    -- Draw right hand
    for i, card in ipairs(Right_Hand) do
        local hue = i / Num_Cards_In_Stack  -- 0 to 1
        love.graphics.setColor(
            0.5 + 0.5 * math.sin(hue * math.pi * 2),
            0.5 + 0.5 * math.sin((hue + 0.33) * math.pi * 2),
            0.5 + 0.5 * math.sin((hue + 0.67) * math.pi * 2)
        )
        local y_left = Card_Stack_Right_BL.y - Card_Height - ((i - 1) * ((Card_Area_Height - Card_Height) / (Num_Cards_In_Stack - 1)))
        love.graphics.rectangle("fill",
                                Card_Stack_Right_TL.x,
                                y_left,
                                Card_Width,
                                Card_Height
        )
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(card.value .. " * " .. i, Card_Stack_Right_BL.x + Card_Width / 2, y_left + Card_Height - 20)
    end
end

local function draw_info_boxes()
    love.graphics.push()

    -- Draw points box
    local left_box_TL = {
        x = Screen_X_Padding + Info_Area_Padding,
        y = Screen_Y_Padding + Info_Area_Padding
    }
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill",
                            Screen_X_Padding + Info_Area_Padding,
                            Screen_Y_Padding + Info_Area_Padding,
                            (VIRTUAL_WIDTH / 2) - (Screen_X_Padding + Info_Area_Padding),
                            Info_Height - (2 * Info_Area_Padding)
    )
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Points: " .. Score, left_box_TL.x + 10, left_box_TL.y + 10)

    love.graphics.pop()
end

function love.draw()
    -- Apply scaling transformation
    love.graphics.push()
    love.graphics.translate(Offset_X, Offset_Y)   -- move origin point
    love.graphics.scale(Scale, Scale)

    -- Draw at VIRTUAL coordinates (375x667)
    love.graphics.clear(0.1, 0.2, 0.3)          -- fill screen with color
    love.graphics.setColor(1, 1, 1)

    -- Stop scaling
    love.graphics.pop()

    -- Draw zones on screen
    draw_layout_guides()

    -- Draw info boxes
    draw_info_boxes()
end

local function clear(hand)
    for k, v in pairs(hand) do hand[k] = nil end
end

local function draw_to_hand(hand, duplicate_indices)
    if #duplicate_indices > 0 then
        print("Hand has duplicate! Cards at indices " .. duplicate_indices[1] .. " and " .. duplicate_indices[2] .. " are duplicates. Clearing hand.")
        clear(hand)
        clear(duplicate_indices)
        return
    end

    if #hand < Num_Cards_In_Stack then
        -- Draw top card
        local top_card = table.remove(Deck)
        if top_card then
            table.insert(hand, top_card)
        end

        -- Check for duplicates
        for i = 1, #hand - 1 do
            if hand[i].value == hand[#hand].value then
                duplicate_indices[1] = i
                duplicate_indices[2] = #hand
                break
            end
        end
    else
        print("Hand is full!")
        clear(hand)
    end
end

local function submit_hand(hand)
    if #hand == 0 then
        print("Hand is empty, cannot submit!")
        return
    end

    local hand_score = 0
    for i, card in ipairs(hand) do
        hand_score = hand_score + (card.value * i)
    end

    Score = Score + hand_score
    print("Submitted hand for " .. hand_score .. " points! Total score: " .. Score)
    clear(hand)
end

function love.touchpressed(id, x, y)
    -- Ignore if already tracking this touch
    if Active_Touches[id] then return end

    -- Convert to virtual coordinates
    local virtual_x = (x - Offset_X) / Scale
    local virtual_y = (y - Offset_Y) / Scale

    -- Store touch
    Active_Touches[id] = {
        start_x = virtual_x,
        start_y = virtual_y,
        start_time = love.timer.getTime(),
        hold_triggered = false
    }
    print("Stored touch at " .. virtual_x .. ", " .. virtual_y)
end

function love.touchreleased(id, x, y)
    local touch = Active_Touches[id]
    if not touch then return end

    -- Remove tap so we don't trigger false positive hold
    Active_Touches[id] = nil

    local virtual_x = (x - Offset_X) / Scale
    local virtual_y = (y - Offset_Y) / Scale

    local dx = virtual_x - touch.start_x
    local dy = virtual_y - touch.start_y
    local duration = love.timer.getTime() - touch.start_time
    local distance = math.sqrt(dx * dx + dy * dy)

    local function is_point_in_rect(point_x, point_y, rect)
        return point_x >= rect.x and point_x <= rect.x + rect.width and
               point_y >= rect.y and point_y <= rect.y + rect.height
    end

    -- If hold triggered, don't process tap or swipe
    if touch.hold_triggered then
        Active_Touches[id] = nil
        return
    end

    -- Check for swipe up
    if distance > Swipe_Threshold and dy < -Swipe_Threshold and duration < Swipe_Time_Limit then
        if is_point_in_rect(touch.start_x, touch.start_y, Buttons.left_stack) then
            print("Swipe up on left stack")
            submit_hand(Left_Hand)
        elseif is_point_in_rect(touch.start_x, touch.start_y, Buttons.right_stack) then
            print("Swipe up on right stack")
            submit_hand(Right_Hand)
        end
        
    -- Check for tap
    elseif distance < Tap_Max_Distance and duration < Tap_Max_Duration then
        if is_point_in_rect(virtual_x, virtual_y, Buttons.left_stack) then
            print("Left draw pile tapped")
            draw_to_hand(Left_Hand, Left_Hand_Duplicate_Indices)
        elseif is_point_in_rect(virtual_x, virtual_y, Buttons.right_stack) then
            print("Right draw pile tapped")
            draw_to_hand(Right_Hand, Right_Hand_Duplicate_Indices)
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        love.touchpressed("mouse", x, y)
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        love.touchreleased("mouse", x, y)
    end
end