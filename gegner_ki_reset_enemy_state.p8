pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- Variablen fuer Game Over
-- game_over: Status, zeigt an ob das Spiel vorbei ist
local game_over = false
-- game_over_timer: Zeit, die bis zum Game Over vergangen ist
local game_over_timer = 0

-- Initialisierung, hier keine Funktionen
function _init () 
    -- Spieler, setzt sich aus x und y Koordinaten sowie Sprite und Geschwindigkeit zusammen
    player = {
        x = 96, 
        y = 96, 
        sprite = 1,
        speed = 1
    }

    -- Gegner, setzt sich aus x und y Koordinaten sowie Sprite und Geschwindigkeit zusammen
    -- Zusaetzlich hat Gegner einen Status und einen Sichtwinkel
    enemy = {
        x = 32,
        y = 32,
        state = "neutral",
        angle = 0,
        line_x = 0,
        line_y = 0,
        sprite = 2,
        speed = 1
    }
end 

-- Update Funktion, wird mit jedem Frame aufgerufen
-- _update60: Spiel laeuft mit 60 Frames pro Sekunde
-- Hier wird die Bewegung des Spielers und des Gegners sowie die Kollision und der Status des Gegners ueberprueft
function _update60 () 
    player_movement()                                                       -- Methode fuer Spielerbewegung
    map_borders_teleport()                                                  -- Alternative Methode zur Kollision mit Kartenrand, teleportiert Spieler/Gegener an auf andere Seite der Karte
    if (collision(player.x, enemy.x, player.y, enemy.y)) then               -- Methode fuer Kollision zwischen Spieler und Gegner
        game_over = true                                                    -- Spiel vorbei, falls Kollision zwischen Spieler und Gegner stattfindet
    end
    if (enemy.state == "neutral") then                                      -- Check, ob Gegner im neutralen Zustand ist
        enemy_random_movement()                                             -- Solange Gegner neutral ist, bewegt er sich zufaellig
        scan_for_player()                                                   -- Solange Gegner neutral ist, scannt er nach Spieler
    elseif (enemy.state == "chasing" and game_over == false) then           -- Check, ob Gegner im Verfolgungsmodus ist
        enemy_following_player()                                            -- Solange Gegner im Verfolgungsmodus ist, verfolgt er den Spieler
    end
end

-- Draw Funktion, wird mit jedem Frame aufgerufen
-- _draw: Zeichnet die Spielwelt und die Entities
function _draw()
    cls(7)                                                                  -- Hintergrundfarbe, 7 = weiれか            
    spr(player.sprite, player.x, player.y)                                  -- Zeichnet Spieler an Position x und y mit Sprite 1
    spr(enemy.sprite, enemy.x, enemy.y)                                     -- Zeichnet Gegner an Position x und y mit Sprite 2      
    if (enemy.state == "neutral") then                                      -- Wenn Gegner im neutralen Zustand ist
        line(enemy.x + 4, enemy.y + 4, enemy.line_x, enemy.line_y, 9)       -- Zeichnet Linie, in der nach Spieler gescannt wird, in Farbe 4 (orange)
    end

    if (not game_over) then                                                 -- Wenn Spiel nicht vorbei ist, zeige Timer        
        print("timer: " .. time(), 2, 2, 0)                                 -- Zeigt Timer in der linken oberen Ecke, wird bei jedem Frame aktualisiert, beginnt bei Spielstart
        game_over_timer = time()                                            -- Setzt Game Over Timer auf aktuelle Zeit  
    else
        print("game over after ".. game_over_timer .. " seconds", 4, 60, 0) -- Zeigt Game Over Nachricht, wenn Spiel vorbei ist
    end

end

-- Funktion fuer Spielerbewegung
-- Spieler kann sich mit ueber keyconfig festgelegten Tasten bewegen
function player_movement()
    if (not game_over) then
        if btn(0) then player.x = player.x - player.speed end               -- Bewegung nach links
        if btn(1) then player.x = player.x + player.speed end               -- Bewegung nach rechts
        if btn(2) then player.y = player.y - player.speed end               -- Bewegung nach oben
        if btn(3) then player.y = player.y + player.speed end               -- Bewegung nach unten
    end
end

-- Funktion fuer Kollision zwischen Spieler und Gegner
-- Kollision findet statt, wenn Abstand zwischen Spieler und Gegner kleiner als 8 ist
function collision (x1, x2, y1, y2)   
    return abs(x1 - x2) < 8 and abs(y1 - y2) < 8                            -- Kollision, wenn Abstand zwischen Spieler und Gegner kleiner als 8  
                                                                            -- In diesem Fall beruehren sich die Sprites, gibt true zurueck
end

-- Funktion, mit der der Gegner den Spieler verfolgt
-- Wird genutzt, wenn Gegner in Modus "chasing" ist
function enemy_following_player () 
    local dx = player.x - enemy.x                                           -- Differenz zwischen Spieler und Gegner in x-Richtung          
    local dy = player.y - enemy.y                                           -- Differenz zwischen Spieler und Gegner in y-Richtung 
    local dist = sqrt(dx^2 + dy^2)                                          -- Distanz zwischen Spieler und Gegner, berechnet mit Pythagoras
    enemy.x = enemy.x + (dx / dist) * enemy.speed                           -- Gegner bewegt sich in x-Richtung auf Spieler zu
    enemy.y = enemy.y + (dy / dist) * enemy.speed                           -- Gegner bewegt sich in y-Richtung auf Spieler zu
end

-- Funktion fuer zufaellige Bewegung des Gegners
-- Wird genutzt, wenn Gegner im Modus "neutral" ist
function enemy_random_movement()
    local rnd_dir = rnd(1)                                                  -- Zufaellige Richtung, in die sich der Gegner bewegt
    local enemy_dir_x = 0                                                   -- Richtung des Gegners in x-Richtung
    local enemy_dir_y = 0                                                   -- Richtung des Gegners in y-Richtung
    if (rnd_dir > 0.5) then                                                 -- Wenn zufaellige Richtung grれへれかer als 0.5 ist
        enemy_dir_x = rnd({-1, 1})                                          -- Zufaellige Richtung in x-Richtung (-1 oder 1)
    else
        enemy_dir_y = rnd({-1, 1})                                          -- Zufaellige Richtung in y-Richtung (-1 oder 1)
    end
    enemy.x = enemy.x + enemy_dir_x * enemy.speed                           -- Bewegung des Gegners in x-Richtung
    enemy.y = enemy.y + enemy_dir_y * enemy.speed                           -- Bewegung des Gegners in y-Richtung
end

-- Funktion zum Scannen nach Spieler
-- Wird genutzt, wenn Gegner im Modus "neutral" ist
-- Scannt in einer Linie nach Spieler
function scan_for_player()
    local line_length = 40                                                  -- Laenge der Linie, in der nach Spieler gescannt wird in Pixel         
    enemy.line_x = mid(0, enemy.x + cos(enemy.angle) * line_length, 127)    -- x-Koordinate der Linie, in der nach Spieler gescannt wird
    enemy.line_y = mid(0, enemy.y + sin(enemy.angle) * line_length, 127)    -- y-Koordinate der Linie, in der nach Spieler gescannt wird

    enemy.angle = enemy.angle + 0.01                                        -- Winkel, in dem gescannt wird, wird bei jedem Frame aktualisiert        

    for i = 0, line_length do                                               -- Schleife, die die Linie in der nach Spieler gescannt wird, durchlaeuft
        local check_x = mid(0, enemy.x + cos(enemy.angle) * i, 127)         -- x-Koordinate, die gescannt wird
        local check_y = mid(0, enemy.y + sin(enemy.angle) * i, 127)         -- y-Koordinate, die gescannt wird
        if collision(check_x, player.x, check_y, player.y) then             -- Wenn Kollision zwischen gescannter Koordinate und Spieler stattfindet
            enemy.state = "chasing"                                         -- Setze Gegner in Verfolgungsmodus                         
            enemy.sprite = 3                                                -- Aendere Sprite des Gegners  
            break                                                           -- Beende Schleife
        end
    end
end

-- Funktionen fuer Kollision mit Kartenrand
-- Gegner und Spieler werden bei Überschreiten des Randes an andere Seite der Karte "teleportiert"
-- Beis Spielerteleportation setzt dies den Status des Gegners wieder auf neutral
function map_borders_teleport()
    if (player.x < 0) then
        player.x = 120
        enemy.state = "neutral" 
        enemy.sprite = 2
    end
    if (player.x > 120) then
        player.x = 0
        enemy.state = "neutral"
        enemy.sprite = 2
    end
    if (player.y < 0) then
        player.y = 120
        enemy.state = "neutral"
        enemy.sprite = 2
    end
    if (player.y > 120) then
        player.y = 0
        enemy.state = "neutral"
        enemy.sprite = 2
    end

    if (enemy.x < 0) then enemy.x = 120 end
    if (enemy.x > 120) then enemy.x = 0 end
    if (enemy.y < 0) then enemy.y = 120 end
    if (enemy.y > 120) then enemy.y = 0 end
end

__gfx__
0000000000aaaa000009900000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa00999999008888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aa5aa5aa9999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9979979988788788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaa55aaa9999999988877888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa09977779988788788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa009999999988888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
