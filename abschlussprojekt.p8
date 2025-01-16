pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

------------------------------------------
--               Menues                 --
------------------------------------------
menu_options = {"start", "exit"}
pause_menu_options = {"resume", "exit"}
difficulty_menu_options = {"hard", "medium", "easy"}
selected_option = 1
current_state = "menu"

function _init()
    current_state = "menu"
    selected_option = 1
    if current_state == "game" then
        create_cheerleader_frames()
    end
end

function _update()
    if current_state == "menu" then
        handle_menu_input(menu_options)
    elseif current_state == "difficulty_menu" then
        handle_menu_input(difficulty_menu_options)
    elseif current_state == "pause_menu" then
        handle_menu_input(pause_menu_options)
    elseif current_state == "game" then
        update_game()
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


------------------------------------------
--                Spiel                 --
------------------------------------------
sprites = {}
spawn_timer = 0
spawn_interval = 2
sprite_falling_speed = 1
correct_count = 0
arrows_spawned = 0

hit_zone_y = 100
hit_zone_tolerance = 8
well_done_threshold = 2

feedback_msg = ""

cheer_anim_counter = 0
cheer_anim_frames = 4

function draw_game()
    cls()
    line(0, hit_zone_y + 4, 128, hit_zone_y + 4, 7)

    for sprite in all(sprites) do
        spr(sprite.sprite_id, sprite.x, sprite.y)
    end

    spr(cheer_anim_frames)
    show_score()
    show_feedback()
end

function update_game()

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
    check_input()
    update_cheerleader_animation()
end

function spawn_sprite()
    local sprite_id = flr(rnd(4)) -- IDs 0 bis 3
    local x = 64 -- feste X-Position
    local y = -8 -- Start れもber dem Bildschirm
    add(sprites, {sprite_id = sprite_id, x = x, y = y})
    arrows_spawned += 1
end

function update_sprite()
    for i = #sprites, 1, -1 do
        local sprite = sprites[i]
        sprite.y += sprite_falling_speed -- Sprite nach unten bewegen
        if sprite.y > 128 then
            feedback_msg = "you suck"
            del(sprites, sprite) -- Sprite entfernen, wenn es den unteren Rand erreicht
        end
    end
end

function check_input()
    for i = #sprites, 1, -1 do
        local sprite = sprites[i]

        -- in der trefferzone?
        if abs(sprite.y - hit_zone_y) < hit_zone_tolerance then
            if sprite.sprite_id == 2 and btnp(2) then
                hit_feedback(sprite)
            elseif sprite.sprite_id == 1 and btnp(1) then
                hit_feedback(sprite)
            elseif sprite.sprite_id == 0 and btnp(3) then
                hit_feedback(sprite)
            elseif sprite.sprite_id == 3 and btnp(0) then
                hit_feedback(sprite)
            end
        end
    end
end

function hit_feedback(sprite)
    sfx(0)
    correct_count += 1
    local dist = abs(sprite.y - hit_zone_y)
    if dist < well_done_threshold then
        feedback_msg = "well done!"
    else
        feedback_msg = "good"
    end
    del(sprites, sprite)
end

function update_cheerleader_animation()
    cheer_anim_counter += 1
    -- z.b. schaltet alle 15 updates um
    if (cheer_anim_counter % 30) < 15 then
        cheer_anim_frame = 4
    else
        cheer_anim_frame = 5
    end
end

function create_cheerleader_frames()
    -- wir definieren 2x (8x8)-sprites (id=4, id=5)
    -- die bilder entstehen per sset() befehl im tilesheet
    -- idee: sprite 4 = arme unten, sprite 5 = arme oben
    -- "b" = blond (farbe 10)
    -- "r" = rotes outfit (farbe 8 oder 9)
    -- "s" = haut (farbe 7 oder 14)
    -- "." = schwarz (farbe 0)
    local cheer1 = {
        "..bb....",
        "..bb....",
        "..rb....",
        "...r....",
        "...ss...",
        "...ss...",
        "....s...",
        "....s...",
    }
    local cheer2 = {
        "..bb..bb",
        "..bb..bb",
        "..rb..rb",
        "...r..r.",
        "...sssss",
        "....sss.",
        ".....ss.",
        ".....s..",
    }

    -- farb-zuordnung
    local cmap = {
        b=10,  -- gelb
        r=8,   -- rot
        s=7,   -- haut (weiれか)
        ["."]=0
    }

    -- sprite #4: x=32..39, y=0..7
    draw_sprite_in_sheet(cheer1, 32, 0, cmap)
    -- sprite #5: x=40..47, y=0..7
    draw_sprite_in_sheet(cheer2, 40, 0, cmap)
end

function draw_sprite_in_sheet(lines, sx, sy, colormap)
    for row=0,7 do
        local line = lines[row+1]
        for col=0,7 do
            local ch = sub(line, col+1, col+1)
            local c = colormap[ch] or 0
            sset(sx+col, sy+row, c)
        end
    end
end

function show_score()
    -- x=correct_count (grれもn=11)
    -- / (blau=12)
    -- y=arrows_spawned (weiれか=7)

    local s_x = tostr(correct_count)
    local s_slash = "/"
    local s_y = tostr(arrows_spawned)

    color(11) -- grれもn
    print(s_x, 0, 0)
    local w_x = #s_x * 4

    color(12) -- blau
    print(s_slash, w_x, 0)
    local w_slash = #s_slash * 4

    color(7)  -- weiれか
    print(s_y, w_x + w_slash, 0)
end

function show_feedback()
    -- text oben rechts in regenbogenfarben
    if feedback_msg == "" then
        return
    end

    local msg = feedback_msg
    local text_width = #msg * 4
    local x = 128 - text_width - 2
    local y = 0
    rainbow_print(msg, x, y)
end

-- druckt text buchstabenweise in wechselnden farben
function rainbow_print(txt, x, y)
    local cols = {8,9,10,11,12,13,14}
    local ncols = #cols
    for i=1,#txt do
        color(cols[(i-1)%ncols+1])
        print(sub(txt,i,i), x + (i-1)*4, y)
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
