pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

------------------------------------------
--               Menues                 --
------------------------------------------

-------------------------
--      Variablen      --
-------------------------

-- Hauptmenue-Optionen
menu_options = {"start", "exit"}

-- Pausemenue-Optionen
pause_menu_options = {"resume", "main menu", "exit"}

-- Schwierigkeitsgrad-Optionen
difficulty_menu_options = {"hard", "medium", "easy", "back"}

-- Spiel-Timer
timer = 0

-- Initialisierung des Spiels
function _init()
    current_state = "menu"                              -- Starte im Hauptmenue
    selected_option = 1                                 -- Starte mit erster Option ausgewaehlt
end

-- Haupt-Loop
-- Hier wird je nach aktuellem Zustand des Spiels die entsprechende Funktion aufgerufen
function _update()
    if current_state == "menu" then
        handle_menu_input(menu_options)                 -- Input im Hauptmenue
    elseif current_state == "difficulty_menu" then
        handle_menu_input(difficulty_menu_options)      -- Input im Schwierigkeitsgradmenue
    elseif current_state == "pause_menu" then       
        handle_menu_input(pause_menu_options)           -- Input im Pausemenue
    elseif current_state == "game" then
        update_game()                                   -- Update des Spiels
    elseif current_state == "exit" then
        -- Kein Input im Exit-Screen
    end
end    

-- Zeichnen der Menues und des Spiels
-- Checkt den aktuellen Status und ruft entsprechende Zeichenfunktion auf
function _draw()
    cls()                                               -- Bildschirm loeschen
    if current_state == "menu" then         
        draw_menu()                                     -- Hauptmenue zeichnen, falls Status "menu"
    elseif current_state == "difficulty_menu" then
        draw_difficulty_menu()                          -- Schwierigkeitsgradmenue zeichnen, falls Status "difficulty_menu"
    elseif current_state == "pause_menu" then
        draw_pause_menu()                               -- Pausemenue zeichnen, falls Status "pause_menu"
    elseif current_state == "game" then
        draw_game()                                     -- Spiel zeichnen, falls Status "game"
    elseif current_state == "exit" then
        draw_exit_screen()                              -- Exit-Screen zeichnen, falls Status "exit"
    end
end


function handle_menu_input(menu_type)
    if btnp(2) then                                     -- up
        selected_option = (selected_option - 2) % #menu_type + 1
    elseif btnp(3) then                                 -- down
        selected_option = selected_option % #menu_type + 1
    elseif btnp(5) then                                 -- enter
        if current_state == "menu" then
            if selected_option == 1 then
                current_state = "difficulty_menu"
            elseif selected_option == 2 then
                current_state = "exit"
            end
        elseif current_state == "difficulty_menu" then
            if selected_option <= 3 then
                difficulty_state = menu_type[selected_option]
                current_state = "game"
            elseif selected_option == 4 then
                current_state = "menu"
                selected_option = 1
            end
        elseif current_state == "pause_menu" then
            if selected_option == 1 then
                current_state = "game"
            elseif selected_option == 2 then
                current_state = "menu"
                reset_game()
            elseif selected_option == 3 then
                current_state = "exit"
            end
        end
    end
end

-- Funktion für Menue-Loop
-- Gibt die Menue-Optionen des uebergebenen Menue-Typs aus und markiert die ausgewaehlte Option
function menu_loop(menu_type)
    local x = 28
    local y = 58
    local width = 64
    local height = #menu_type * 10 + 20
    rect(x, y, x + width, y + height, 7)                -- Zeichne Rechteck um die Menue-Optionen
    for i, option in ipairs(menu_type) do               -- Schleife ueber alle Menue-Optionen
        if i == selected_option then
            print("-> " .. option, 30, 60 + i * 10, 7)  -- Wenn Option ausgewaehlt, dann mit Pfeil ausgeben
        else
            print("   " .. option, 30, 60 + i * 10, 7)  -- Ansonsten nur Option ausgeben
        end
    end
end

-- Zeichnet Hauptmenue
function draw_menu()
    print("main menu", 30, 40, 7)
    menu_loop(menu_options)                             -- Hauptmenue-Loop
end

-- Zeichnet Schwierigkeitsgradmenue
function draw_difficulty_menu()
    print("difficulty menu", 30, 40, 7)
    menu_loop(difficulty_menu_options)                  -- Schwierigkeitsgradmenue-Loop
end

-- Zeichnet Pausemenue
function draw_pause_menu()
    print("pause", 30, 40, 7)
    menu_loop(pause_menu_options)                       -- Pausemenue-Loop
end

-- Zeichnet Exit-Screen
function draw_exit_screen()
    print("see you soon!", 30, 60, 7)                
end


------------------------------------------
--                Spiel                 --
------------------------------------------

-------------------------
--      Variablen      --
-------------------------

-- Array fuer fallende Pfeil-Sprites
sprites = {}

-- Spawn-Timer fuer Pfeile
spawn_timer = 0

-- Spawn-Intervall fuer Pfeile
spawn_interval = 2

-- Geschwindigkeit, mit der Pfeile fallen
sprite_falling_speed = 1

-- Anzahl korrekt getroffener Pfeile
correct_count = 0

-- Punktestand
score = 0

-- Anzahl gespawnter Pfeile
arrows_spawned = 0

-- Variablen Hit-Zone fuer Pfeile
-- y-Koordinate der Hit-Zone
hit_zone_y = 100

-- Toleranz der Hit-Zone
hit_zone_tolerance = 8

-- Toleranz fuer "well done" Feedback
well_done_threshold = 2

-- Feedback-Nachricht
feedback_msg = ""

-- Animationszaehler fuer Cheerleader
cheer_anim_counter = 0

-------------------------
--   Draw-Funktionen   --
-------------------------

-- Funktion, die Spiel zeichnet
function draw_game()
    cls()                                               -- Bildschirm loeschen
    line(0, hit_zone_y + 4, 128, hit_zone_y + 4, 7)     -- Zeichne Hit-Zone, bestehehend aus Linie und Tolernazzone
                                                        -- Pfeile muessen in dieser Zone getroffen vom Spieler getroffen werden
    for sprite in all(sprites) do                       -- Schleife ueber alle Pfeile
        spr(sprite.sprite_id, sprite.x, sprite.y)       -- Zeichne Pfeil am oberen Bildschirm
    end

    draw_borders()                                      -- Zeichne Abgrenzungslinien
    draw_correct_hits()                                 -- Zeige korrekt getroffene Pfeile oben links
    draw_timer()                                        -- Zeichne Timer oben links
    draw_feedback()                                     -- Zeige Feedback-Nachricht oben rechts
    draw_score()                                        -- Zeige Score oben rechts unter Feedback-Nachricht
    draw_cheerleader()                                  -- Zeichne Cheerleader auf Hitzone-Linie                
end

-- Funktion, die Abgrenzungslinien zeichnet
function draw_borders()
    rect(0, 16, 127, 127, 7)                            -- Zeichne Rechteck um das Spielfeld
end

-- Funktion, die korrekten Treffer anzeigt
function draw_correct_hits()
    -- x = correct_count (gruen = 11) / (blau=12)
    -- y = arrows_spawned (weiß = 7)

    -- Score-Text
    local s_x = tostr(correct_count)                    -- Anzahl korrekt getroffener Pfeile als String
    local s_slash = "/"                                 -- Schraegstrich zwischen korrekt getroffenen Pfeilen und gespawnten Pfeilen
    local s_y = tostr(arrows_spawned)                   -- Anzahl gespawnter Pfeile als String

    color(11)
    print(s_x, 0, 0)                                    -- Zeige korrekt getroffene Pfeile in gruen
    local w_x = #s_x * 4                                -- Breite des Strings in Pixeln

    color(12)
    print(s_slash, w_x, 0)                              -- Zeige Schraegstrich in blau
    local w_slash = #s_slash * 4                        -- Breite des Schraegstrichs in Pixeln

    color(7)
    print(s_y, w_x + w_slash, 0)                        -- Zeige Anzahl gespawnter Pfeile in weiss
end

-- Funktion, die Timer anzeigt
function draw_timer()
    print("time: " ..flr(timer), 0, 8, 7)               -- Zeige Spielzeit in Sekunden oben links unter Score
end

-- Funktion, die Feedback-Nachricht anzeigt
function draw_feedback()
    local msg = feedback_msg                            -- Feedback-Nachricht
    local text_width = #msg * 4                         -- Breite der Nachricht in Pixeln
    local x = 128 - text_width - 2                      -- x-Koordinate der Nachricht
    local y = 0                                         -- y-Koordinate der Nachricht
    rainbow_print(msg, x, y)                            -- Zeige Nachricht in Regenbogenfarben rechts oben
end

function draw_score()
    local score_text = "score: " .. score               -- Punktestand als String
    local text_width = #score_text * 4                  -- Breite des Strings in Pixeln
    local x = 128 - text_width - 2                      -- x-Koordinate des Punktestands
    local y = 8                                         -- y-Koordinate des Punktestands, unter Feedback-Nachricht
    print(score_text, x, y, 7)                          -- Zeige Punktestand rechts oben unter Feedback-Nachricht
end

-- Funktion, die Cheerleader zeichnet
-- "Animiert" eine Bewegung der Cheerleader durch Sprite-Wechsel alle 30 Frames
function draw_cheerleader()
    if cheer_anim_counter % 30 < 15 then                -- Falls Animationszaehler kleiner als 15, zeichne Cheerleader-Sprite 1
        spr(4, 1, 96)                                   -- Cheerleader linke Seite
        spr(4, 118, 96)                                 -- Cheerleader rechte Seite
    else                                                -- Ansonsten zeichne Cheerleader-Sprite 2
        spr(5, 1, 96)                                   -- Cheerleader linke Seite
        spr(5, 118, 96)                                 -- Cheerleader rechte Seite
    end
end

-------------------------
--  Update-Funktionen  --
-------------------------

-- Funktion, die Spiel-Logik aktualisiert
function update_game()

    if btnp(5) then
        current_state = "pause_menu"                    -- Pausemenue aufrufen, falls Enter gedrueckt
        selected_option = 1
    end
    if difficulty_state == "hard" then
        spawn_frames = 8                                -- Schwierigkeitsgrad "hard", spawnt neuen Pfeil alle 8 Frames
    elseif difficulty_state == "medium" then
        spawn_frames = 16                               -- Schwierigkeitsgrad "medium", spawnt neuen Pfeil alle 16 Frames
    elseif difficulty_state == "easy" then
        spawn_frames = 24                               -- Schwierigkeitsgrad "easy", spawnt neuen Pfeil alle 24 Frames
    end

    spawn_timer += 1/spawn_frames                       -- Erhoehe Spawn-Timer
    if spawn_timer >= spawn_interval then               -- Check, ob neuer Pfeil gespawnt werden soll
        spawn_sprite()
        spawn_timer = 0                                 -- Reset Spawn-Timer                     
    end

    update_sprite()                                     -- Update Pfeile
    update_timer()                                      -- Update Spiel-Timer
    update_cheerleader()                                -- Update Cheerleader
    check_input()                                       -- Check Input des Spielers
end

-- Funktion, die Pfeile aktualisiert
function update_sprite()
    for i = #sprites, 1, -1 do                          -- Schleife ueber alle gespawnten Pfeile
        local sprite = sprites[i]                       -- Aktueller Pfeil
        sprite.y += sprite_falling_speed                -- Pfeil nach unten bewegen
        if sprite.y > 128 then                          -- Check, ob Pfeil unteren Bildschirmrand erreicht
            feedback_msg = "missed!"                    -- Wenn ja, schlechte Feedback-Nachricht und Pfeil aus Array entfernen
            del(sprites, sprite)
        end
    end
end

-- Funktion, die Spielzeit aktualisiert
function update_timer()
    timer += 1/30                                       -- Erhoehe Timer um 1/30 Sekunde, also alle 30 Frames um 1
end

-- Funktion, die Cheerleader aktualisiert
function update_cheerleader()
    cheer_anim_counter += 1                             -- Erhoehe Animationszaehler
end

-------------------------
-- Sonstige Funktionen --
-------------------------

-- Funktion, die Pfeile spawnt
function spawn_sprite()
    local sprite_id = flr(rnd(4))                       -- IDs 0 bis 3, zufaelliger Pfeil
    local x;                                            -- x-Koordinate des Pfeils, abhaengig von ID
    if sprite_id == 0 then                              
        x = 30                                          -- x-Koordinate fuer Pfeil-ID 0, Pfeil nach unten
    elseif sprite_id == 1 then
        x = 52                                          -- x-Koordinate fuer Pfeil-ID 1, Pfeil nach rechts
    elseif sprite_id == 2 then
        x = 76                                          -- x-Koordinate fuer Pfeil-ID 2, Pfeil nach oben
    elseif sprite_id == 3 then
        x = 98                                          -- x-Koordinate fuer Pfeil-ID 3, Pfeil nach links
    end
    local y = 16                                        -- Start an oberer Abgrenzungslinie
    add(sprites, {sprite_id = sprite_id, x = x, y = y}) -- Hinzufuegen des neuen Pfeils zum Array
    arrows_spawned += 1                                 -- Erhoehe Anzahl gespawnter Pfeile
end

-- Funktion, die Input des Spielers im Spiel ueberprueft
function check_input()
    for i = #sprites, 1, -1 do                          -- Schleife ueber alle gespawnten Pfeile
        local sprite = sprites[i]                       -- Aktueller Pfeil             

        -- Check, ob Pfeil in Hit-Zone ist und Spieler die richtige Taste gedrueckt hat
        if abs(sprite.y - hit_zone_y) < hit_zone_tolerance then
            if sprite.sprite_id == 2 and btnp(2) then
                hit_feedback(sprite)                    -- Falls ja, Aufruf der Hit-Feedback-Funktion
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

-- Funktion, die Feedback gibt, wenn Pfeil getroffen wurde
function hit_feedback(sprite)
    sfx(0)                                              -- Soundeffekt abspielen
    correct_count += 1                                  -- Erhoehe Anzahl korrekt getroffener Pfeile
    local dist = abs(sprite.y - hit_zone_y)             -- Distanz des Pfeils zur Hit-Zone ermitteln
    if dist < well_done_threshold then                  -- Check, ob Distanz kleiner als Toleranz fuer "well done" Feedback
        feedback_msg = "well done!"                     -- Falls ja, "well done" Feedback   
        score += 200                                    -- Erhoehe Punktestand um 200   
    else
        feedback_msg = "good"                           -- Ansonsten "good" Feedback
        score += 100                                    -- Erhoehe Punktestand um 100
    end
    del(sprites, sprite)                                -- Pfeil aus Array entfernen
end

-- Funktion, die Text in Regenbogenfarben ausgibt
function rainbow_print(txt, x, y)
    local cols = {8,9,10,11,12,13,14}                   -- Verfuegbare Farben
    local ncols = #cols                                 -- Anzahl verfuegbarer Farben
    for i=1,#txt do                                     -- Schleife ueber alle Zeichen des Textes
        color(cols[(i-1)%ncols+1])                      -- Setze Farbe auf i-tes Element der Farbenliste
        print(sub(txt,i,i), x + (i-1)*4, y)             -- Zeichne i-tes Zeichen des Textes
    end
end

-- Funktion, die Spiel zuruecksetzt
-- Wird aufgerufen, wenn Spieler aus dem Pausemenue ins Hauptmenue wechselt
function reset_game()
    timer = 0                                           -- Setze Timer zurueck
    correct_count = 0                                   -- Setze Anzahl korrekt getroffener Pfeile zurueck
    arrows_spawned = 0                                  -- Setze Anzahl gespawnter Pfeile zurueck
    feedback_msg = ""                                   -- Setze Feedback-Nachricht zurueck
    cheer_anim_counter = 0                              -- Setze Animationszaehler fuer Cheerleader zurueck
    sprites = {}                                        -- Loescht alle Pfeile aus dem Array
    score = 0                                           -- Setze Punktestand zurueck
end

------------------------------------------
--           Sprites / Sounds           --
------------------------------------------

__gfx__
000660000000600000066000000600000aa0000000aa00aa00000000000000000000000000000000000000000000000000000000000000000000000000000000
000660000000660000666600006600000aa0000000aa00aa00000000000000000000000000000000000000000000000000000000000000000000000000000000
0006600000006660066666600666000008a00000008a008a00000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000666666666666666666666666008000000002002000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666660006600066666666007700000007777700000000000000000000000000000000000000000000000000000000000000000000000000000000
06666660000066600006600006660000007700000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666600000066000006600000660000000700000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000060000006600000060000000700000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000613032c050290502c0502a0502d050270502a050260502a0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000012050000000000000000000000000024050000000000000000000000000000000250502505000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00108000000000000000000000000000000000230500000000000000001e0500000000000000001b0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011101010000000000298502e850288502d850278502b850258502985000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000002bf5027f502af5027f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
06 3f050304
00 01024344

