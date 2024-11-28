pico-8 cartridge // http://www.pico-8.com
version 1
__lua__

-- Spielvariablen
player = {x = 64, y = 64, sprite = 1}
enemy = {
    x = 32,
    y = 32,
    sprite = 2,
    angle = 0,
    state = "neutral",
    speed = 0.5
}
game_over = false

function _init()
    -- Initialisierungscode hier (falls erforderlich)
end

function _update()
    if not game_over then
        -- Spielerbewegung
        if btn(0) then player.x = player.x - 1 end -- Links
        if btn(1) then player.x = player.x + 1 end -- Rechts
        if btn(2) then player.y = player.y - 1 end -- Hoch
        if btn(3) then player.y = player.y + 1 end -- Runter

        -- Begrenzung des Spielers auf den Bildschirm
        player.x = mid(0, player.x, 127)
        player.y = mid(0, player.y, 127)

        -- Gegnerverhalten
        if enemy.state == "neutral" then
            -- Zufällige Bewegung
            enemy.x = enemy.x + (rnd(2) - 1) * enemy.speed
            enemy.y = enemy.y + (rnd(2) - 1) * enemy.speed

            -- Sichtfeldrotation
            enemy.angle = (enemy.angle + 2) % 360

            -- Überprüfung, ob der Spieler im Sichtfeld ist
            if check_sight() then
                enemy.state = "chasing"
                enemy.sprite = 3 -- Ändere das Sprite
            end
        elseif enemy.state == "chasing" then
            -- Verfolge den Spieler
            local dx = player.x - enemy.x
            local dy = player.y - enemy.y
            local dist = sqrt(dx^2 + dy^2)
            enemy.x = enemy.x + (dx / dist) * enemy.speed * 1.5
            enemy.y = enemy.y + (dy / dist) * enemy.speed * 1.5
        end

        -- Überprüfung auf Kollision
        if collide(player.x, player.y, enemy.x, enemy.y) then
            game_over = true
        end
    end
end

function _draw()
    cls()

    -- Zeichne Spieler
    spr(player.sprite, player.x, player.y)

    -- Zeichne Gegner
    spr(enemy.sprite, enemy.x, enemy.y)

    -- Zeichne Sichtfeld, wenn Gegner neutral ist
    if enemy.state == "neutral" then
        local sight_length = 50
        local angle_rad = enemy.angle / 57.2958 -- Umrechnung in Radiant
        local sx = enemy.x + 4 -- Mittelpunkt des Sprites anpassen
        local sy = enemy.y + 4
        local ex = sx + cos(angle_rad) * sight_length
        local ey = sy + sin(angle_rad) * sight_length
        color(8) -- Rote Linie
        line(sx, sy, ex, ey)
    end

    -- Spielstatus anzeigen
    if game_over then
        print("Game Over", 50, 60, 7)
    end
end

function check_sight()
    -- Berechne den Endpunkt der Sichtlinie
    local sight_length = 50
    local angle_rad = enemy.angle / 57.2958
    local sx = enemy.x + 4
    local sy = enemy.y + 4
    local ex = sx + cos(angle_rad) * sight_length
    local ey = sy + sin(angle_rad) * sight_length

    -- Prüfe auf Schnittpunkt mit dem Spieler
    return line_intersect(sx, sy, ex, ey, player.x, player.y, player.x + 8, player.y + 8)
end

function line_intersect(x1,y1,x2,y2,x3,y3,x4,y4)
    -- Algorithmus zur Liniensegment-Schnittpunktsberechnung
    local den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
    if den == 0 then return false end
    local t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / den
    local u = -((x1 - x2) * (y1 - x3) - (y1 - y2) * (x1 - x3)) / den
    return t >= 0 and t <= 1 and u >= 0 and u <= 1
end

function collide(x1, y1, x2, y2)
    -- Einfache Kollisionsüberprüfung
    return abs(x1 - x2) < 8 and abs(y1 - y2) < 8
end
