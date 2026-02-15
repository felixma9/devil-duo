function love.conf(t)
    -- Window settings
    t.window.width = 375
    t.window.height = 667
    t.window.title = "Devil's Hands"
    t.window.resizable = false
    t.window.highdpi = true

    -- Disable unnecessary modules
    t.modules.joystick = false
    t.modules.physics = false
end