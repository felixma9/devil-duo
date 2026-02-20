-- Global_Variables_Like_So
-- local_variables_like_so
-- CONSTANTS_LIKE_SO

local function init_deck()
    -- Clear out deck if needed
    for k, v in pairs(Deck) do Deck[k] = nil end

    -- Add value cards to deck
    for card_value = 1, NUM_CARDS_IN_STACK do
        for i = 1, card_value do
            table.insert(Deck, {
                value = card_value,
            })
        end
    end

    -- Add other cards to deck
    table.insert(Deck, { value = 0 })
    -- Some cards have special values, these will be special cards
    table.insert(Deck, { value = -1 })

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
    CARD_WIDTH = 90
    CARD_HEIGHT = 140

    -- Padding around entire app
    SCREEN_X_PADDING = 30
    SCREEN_Y_PADDING = 40

    -- Top info area
    INFO_HEIGHT = 150
    INFO_AREA_PADDING = 20

    -- Card area
    CARD_AREA_PADDING = 20
    Card_Area_Height = VIRTUAL_HEIGHT - INFO_HEIGHT - (2 * CARD_AREA_PADDING) - (2 * SCREEN_Y_PADDING)
    Card_Area_Width = VIRTUAL_WIDTH - (2 * (SCREEN_X_PADDING + CARD_AREA_PADDING))

    -- Card stack positioning
    Card_Stack_Left_TL = {
        x = SCREEN_X_PADDING + CARD_AREA_PADDING,
        y = SCREEN_Y_PADDING + INFO_HEIGHT + CARD_AREA_PADDING
    }
    Card_Stack_Right_TL = {
        x = Card_Stack_Left_TL.x + Card_Area_Width - CARD_WIDTH,
        y = SCREEN_Y_PADDING + INFO_HEIGHT + CARD_AREA_PADDING
    }

    NUM_CARDS_IN_STACK = 5
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
            width = CARD_WIDTH,
            height = Card_Area_Height
        },
        right_stack = {
            x = Card_Stack_Right_TL.x,
            y = Card_Stack_Right_TL.y,
            width = CARD_WIDTH,
            height = Card_Area_Height
        },
    }

    -- Score
    Score = 0

    -- Hands
    NUM_HANDS_SUBMITTABLE = 3
    Hands_Submitted = 0
    Left_Hand = {}
    Right_Hand = {}

    -- Deck
    Deck = {}
    init_deck()

    -- Bonus management
    -- When a bonus card (+2, +4) is drawn, place that bonus in the correct index (1 to NUM_CARDS_IN_STACK)
    Left_Hand_Bonus_Indices = {}
    Right_Hand_Bonus_Indices = {}

    for i = 1, NUM_CARDS_IN_STACK do
        Left_Hand_Bonus_Indices[i] = 0
        Right_Hand_Bonus_Indices[i] = 0
    end

    -- { card_value, bonus_value }
    Bonus_Card_Values = {
        [-1] = 2,
        [-2] = 4,
    }

    -- Duplicate management
    -- Length of these is either 0 or 2, 0 == no duplicate, 2 == duplicate
    Left_Hand_Duplicate_Indices = {}
    Right_Hand_Duplicate_Indices = {}

    -- Detect swipes
    Active_Touches = {}
    SWIPE_THRESHOLD = 50
    SWIPE_TIME_LIMIT = 0.5
    HOLD_DURATION = 0.5
    TAP_MAX_DISTANCE = 10
    TAP_MAX_DURATION = 0.3
end

function love.update(dt)
    -- Check for hold
    for id, touch in pairs(Active_Touches) do
        if not touch.hold_triggered then
            local hold_time = love.timer.getTime() - touch.start_time
            if hold_time >= HOLD_DURATION then
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
                            SCREEN_X_PADDING,
                            SCREEN_Y_PADDING,
                            VIRTUAL_WIDTH - (2 * SCREEN_X_PADDING),
                            VIRTUAL_HEIGHT - (2 * SCREEN_Y_PADDING)
    )

    -- Draw top info area
    love.graphics.rectangle("line",
                            SCREEN_X_PADDING,
                            SCREEN_Y_PADDING,
                            VIRTUAL_WIDTH - (2 * SCREEN_X_PADDING),
                            INFO_HEIGHT
    )

    -- Draw top info box
    love.graphics.rectangle("line",
                            SCREEN_X_PADDING + INFO_AREA_PADDING,
                            SCREEN_Y_PADDING + INFO_AREA_PADDING,
                            VIRTUAL_WIDTH - (2 * (SCREEN_X_PADDING + INFO_AREA_PADDING)),
                            INFO_HEIGHT - (2 * INFO_AREA_PADDING)
    )

    -- Draw card box
    love.graphics.rectangle("line",
                            SCREEN_X_PADDING + CARD_AREA_PADDING,
                            SCREEN_Y_PADDING + INFO_HEIGHT + CARD_AREA_PADDING,
                            Card_Area_Width,
                            Card_Area_Height
    )

    -- Draw left hand
    for i, card in ipairs(Left_Hand) do
        local hue = i / NUM_CARDS_IN_STACK  -- 0 to 1
        love.graphics.setColor(
            0.5 + 0.5 * math.sin(hue * math.pi * 2),
            0.5 + 0.5 * math.sin((hue + 0.33) * math.pi * 2),
            0.5 + 0.5 * math.sin((hue + 0.67) * math.pi * 2)
        )
        local y_left = Card_Stack_Left_BL.y - CARD_HEIGHT - ((i - 1) * ((Card_Area_Height - CARD_HEIGHT) / (NUM_CARDS_IN_STACK - 1)))
        love.graphics.rectangle("fill",
                                Card_Stack_Left_TL.x,
                                y_left,
                                CARD_WIDTH,
                                CARD_HEIGHT
        )
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(card.value .. " * " .. i, Card_Stack_Left_BL.x + CARD_WIDTH / 3, y_left + CARD_HEIGHT - 20)
        
        if Left_Hand_Bonus_Indices[i] > 0 then
            love.graphics.setColor(1, 0, 0)
            love.graphics.print("+" .. Left_Hand_Bonus_Indices[i], Card_Stack_Left_BL.x + CARD_WIDTH / 3, y_left + 10)
        end
    end

    -- Draw right hand
    for i, card in ipairs(Right_Hand) do
        local hue = i / NUM_CARDS_IN_STACK  -- 0 to 1
        love.graphics.setColor(
            0.5 + 0.5 * math.sin(hue * math.pi * 2),
            0.5 + 0.5 * math.sin((hue + 0.33) * math.pi * 2),
            0.5 + 0.5 * math.sin((hue + 0.67) * math.pi * 2)
        )
        local y_left = Card_Stack_Right_BL.y - CARD_HEIGHT - ((i - 1) * ((Card_Area_Height - CARD_HEIGHT) / (NUM_CARDS_IN_STACK - 1)))
        love.graphics.rectangle("fill",
                                Card_Stack_Right_TL.x,
                                y_left,
                                CARD_WIDTH,
                                CARD_HEIGHT
        )
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(card.value .. " * " .. i, Card_Stack_Right_BL.x + CARD_WIDTH / 2, y_left + CARD_HEIGHT - 20)

        if Right_Hand_Bonus_Indices[i] > 0 then
            love.graphics.setColor(1, 0, 0)
            love.graphics.print("+" .. Right_Hand_Bonus_Indices[i], Card_Stack_Right_BL.x + CARD_WIDTH / 2, y_left + 10)
        end
    end
end

local function draw_info_boxes()
    love.graphics.push()

    -- Draw points box
    local left_box_TL = {
        x = SCREEN_X_PADDING + INFO_AREA_PADDING,
        y = SCREEN_Y_PADDING + INFO_AREA_PADDING
    }
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill",
                            SCREEN_X_PADDING + INFO_AREA_PADDING,
                            SCREEN_Y_PADDING + INFO_AREA_PADDING,
                            (VIRTUAL_WIDTH / 2) - (SCREEN_X_PADDING + INFO_AREA_PADDING),
                            INFO_HEIGHT - (2 * INFO_AREA_PADDING)
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

local function handle_bonus_card(hand, card)
    print("Applying "..Bonus_Card_Values[card.value].." bonus to next card!")
    if hand == Left_Hand then
        Left_Hand_Bonus_Indices[#hand + 1] = Bonus_Card_Values[card.value]
    else
        Right_Hand_Bonus_Indices[#hand + 1] = Bonus_Card_Values[card.value]
    end
end

local function draw_to_hand(hand, duplicate_indices)
    if #duplicate_indices > 0 then
        print("Hand has duplicate! Cards at indices " .. duplicate_indices[1] .. " and " .. duplicate_indices[2] .. " are duplicates. Clearing hand.")
        clear(hand)
        clear(duplicate_indices)
        return
    end

    if #hand < NUM_CARDS_IN_STACK then
        -- Draw top card
        local top_card = table.remove(Deck)

        if not top_card then
            print("Deck is empty, cannot draw!")
            return
        end
        
        -- Handle bonus card
        if top_card.value < 0 then
            print("Drew bonus card!")
            handle_bonus_card(hand, top_card)
            return
        end
        
        table.insert(hand, top_card)

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
    if Hands_Submitted >= NUM_HANDS_SUBMITTABLE then
        print("Already submitted " .. NUM_HANDS_SUBMITTABLE .. " hands, cannot submit more!")
        return
    end

    if #hand == 0 then
        print("Hand is empty, cannot submit!")
        return
    end

    if #Left_Hand_Duplicate_Indices > 0 then
        print("Left hand has duplicates! Clearing hand.")
        clear(hand)
        clear(Left_Hand_Duplicate_Indices)
        return
    elseif #Right_Hand_Duplicate_Indices > 0 then
        print("Right hand has duplicates! Clearing hand.")
        clear(hand)
        clear(Right_Hand_Duplicate_Indices)
        return
    end

    -- Calculate score, update globals
    local hand_score = 0
    for i, card in ipairs(hand) do
        local bonus = 0

        if hand == Left_Hand and Left_Hand_Bonus_Indices[i] then
            bonus = Left_Hand_Bonus_Indices[i]
        elseif hand == Right_Hand and Right_Hand_Bonus_Indices[i] then
            bonus = Right_Hand_Bonus_Indices[i]
        end

        if bonus > 0 then
            print("Applying bonus of +" .. bonus .. " to card with value " .. card.value)
        end

        hand_score = hand_score + ((card.value + bonus) * i)
        bonus = 0
    end

    Score = Score + hand_score
    print("Submitted hand for " .. hand_score .. " points! Total score: " .. Score)
    clear(hand)

    Hands_Submitted = Hands_Submitted + 1
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
    if distance > SWIPE_THRESHOLD and dy < -SWIPE_THRESHOLD and duration < SWIPE_TIME_LIMIT then
        if is_point_in_rect(touch.start_x, touch.start_y, Buttons.left_stack) then
            print("Swipe up on left stack")
            submit_hand(Left_Hand)
        elseif is_point_in_rect(touch.start_x, touch.start_y, Buttons.right_stack) then
            print("Swipe up on right stack")
            submit_hand(Right_Hand)
        end
        
    -- Check for tap
    elseif distance < TAP_MAX_DISTANCE and duration < TAP_MAX_DURATION then
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