pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- Hauptmenue

menu_options = {"start", "exit"}
pause_menu_options = {"resume", "exit"}
difficulty_menu_options = {"hard", "medium", "easy"}
selected_option = 1
current_state = "menu"

function _init()
    current_state = "menu"
    selected_option = 1
end

function _update()
    if current_state == "menu" then
        handle_menu_input(menu_options)
    elseif current_state == "difficulty_menu" then
        handle_menu_input(difficulty_menu_options)
    elseif current_state == "pause_menu" then
        handle_menu_input(pause_menu_options)
    elseif current_state == "game" then
        handle_game_input()
    elseif current_state == "exit" then
        -- Kein Input im Exit-Screen
    end
end    

function _draw()
    cls()
    if current_state == "menu" then
        draw_menu()
    elseif current_state == "difficulty_menu" then
        draw_difficulty_menu()
    elseif current_state == "pause_menu" then
        draw_pause_menu()
    elseif current_state == "game" then
        draw_game()
    elseif current_state == "exit" then
        draw_exit_screen()
    end
end

function handle_menu_input(menu_type)
    if btnp(2) then -- up
        selected_option -= 1
        if selected_option < 1 then
            selected_option = #menu_type
        end
    elseif btnp(3) then -- down
        selected_option += 1
        if selected_option > #menu_type then
            selected_option = 1
        end
    elseif btnp(5) then -- enter
        if current_state == "menu" then
            if selected_option == 1 then
                current_state = "difficulty_menu"
            elseif selected_option == 2 then
                current_state = "exit"
            end
        elseif current_state == "difficulty_menu" then
            if selected_option == 1 then
                difficulty_state = "hard"
                current_state = "game"
            elseif selected_option == 2 then
                difficulty_state = "medium"
                current_state = "game"
            elseif selected_option == 3 then
                difficulty_state = "easy"
                current_state = "game"
            end
        elseif current_state == "pause_menu" then
            if selected_option == 1 then
                current_state = "game"
            elseif selected_option == 2 then
                current_state = "exit"
            end
        end
    end
end

function menu_loop(menu_type)
    for i, option in ipairs(menu_type) do
        if i == selected_option then
            print("-> " .. option, 60, 60 + i * 10, 7)
        else
            print("   " .. option, 60, 60 + i * 10, 7)
        end
    end
end

function draw_menu()
    print("Hauptmenue", 60, 40, 7)
    menu_loop(menu_options)
end

function draw_difficulty_menu()
    print("Schwierigkeitsgrad", 60, 40, 7)
    menu_loop(difficulty_menu_options)
end

function draw_pause_menu()
    print("Pause", 60, 40, 7)
    menu_loop(pause_menu_options)
end

function draw_exit_screen()
    print("Auf Wiedersehen!", 60, 60, 7)
end


-- Game-Code
sprites = {}
spawn_timer = 0
spawn_interval = 2
sprite_falling_speed = 1

function draw_game()
    cls(12)
    for sprite in all(sprites) do
        spr(sprite.sprite_id, sprite.x, sprite.y)
    end
end

function handle_game_input()
    if btnp(5) then
        current_state = "pause_menu"
    end
    if difficulty_state == "hard" then
        spawn_frames = 8
    elseif difficulty_state == "medium" then
        spawn_frames = 16
    elseif difficulty_state == "easy" then
        spawn_frames = 24
    end
    spawn_timer += 1/spawn_frames
    if spawn_timer >= spawn_interval then
        spawn_sprite()
        spawn_timer = 0
    end

    update_sprite()
end

function spawn_sprite()
    local sprite_id = flr(rnd(4)) -- IDs 0 bis 3
    local x = 64 -- feste X-Position
    local y = -8 -- Start れもber dem Bildschirm
    add(sprites, {sprite_id = sprite_id, x = x, y = y})
end

function update_sprite()
    for i = #sprites, 1, -1 do
        local sprite = sprites[i]
        sprite.y += sprite_falling_speed -- Sprite nach unten bewegen
        if sprite.y > 128 then
            del(sprites, sprite) -- Sprite entfernen, wenn es den unteren Rand erreicht
        end
    end
end


__gfx__
00066000000060000006600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000066000066660000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000066600666666006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000666666666666666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666660006600066666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666660000066600006600006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666600000066000006600000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000060000006600000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
