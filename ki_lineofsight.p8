pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

player = {
    x = 64, 
    y = 64, 
    sprite = 1,
    speed = 1}

enemy = {
    x = 32,
    y = 32,
    state = "neutral",
    angle = 0,
    sprite = 2,
    speed = 0.5}

game_over = false
game_over_timer = 0

function _draw()
    cls(11)
    spr(player.sprite, player.x, player.y)
    spr(enemy.sprite, enemy.x, enemy.y)
    
    if not game_over then
        print("timer: " .. time(), 2, 2, 1)
        game_over_timer = time()
    else
        print("game over!", 32, 60, 1)
        print("timer: " .. game_over_timer, 2, 2, 1)
    end
end



function _init()

end

function _update60() 
    if not game_over then
        if btn(0) then player.x = player.x - player.speed end
        if btn(1) then player.x = player.x + player.speed end
        if btn(2) then player.y = player.y - player.speed end
        if btn(3) then player.y = player.y + player.speed end

        if (enemy.state == "neutral") then
            local sight_length = 50
            local angle_rad = enemy.angle / 57.2958
            local sx = enemy.x + 4
            local sy = enemy.y + 4
            local ex = sx + cos(angle_rad) * sight_length
            local ey = sy + sin(angle_rad) * sight_length
            color(8)
            line(sx, sy, ex, ey)
            enemy.x = enemy.x + (rnd(3) - 1) * enemy.speed
            enemy.y = enemy.y + (rnd(3) - 1) * enemy.speed
            enemy.angle = (enemy.angle + 2) % 360
            if check_sight() then
                enemy.state = "chasing"
                enemy.sprite = 3
            end
        else
            _enemy_follow_player()
        end

        if (player.x < 0) then
            player.x = (player.x + 127) % 128
            enemy.state = "neutral"
            enemy.sprite = 2
        end
        if (player.x > 127) then
            player.x = player.x % 128
            enemy.state = "neutral"
            enemy.sprite = 2
        end
        if (player.y < 0) then
            player.y = (player.y + 127) % 128
            enemy.state = "neutral"
            enemy.sprite = 2
        end
        if (player.y > 127) then
            player.y = player.y % 128
            enemy.state = "neutral"
            enemy.sprite = 2
        end
    end

    if _enemy_collision(player.x, enemy.x, player.y, enemy.y) then
        game_over = true
    end
end

function _enemy_collision(x1, x2, y1, y2)
    return abs(x1 - x2) < 8 and abs(y1 - y2) < 8
end

function _obstacle_collision(x1, x2, y1, y2)
    return abs(x1 - x2) < 8 and abs(y1 - y2) < 8
end

function _enemy_follow_player()
    local dx = player.x - enemy.x
    local dy = player.y - enemy.y
    local dist = sqrt(dx^2 + dy^2)
    enemy.x = enemy.x + (dx / dist) * enemy.speed * 1.5
    enemy.y = enemy.y + (dy / dist) * enemy.speed * 1.5
end

function check_sight()
    -- Berechne den Endpunkt der Sichtlinie
    local sight_length = 50
    local angle_rad = enemy.angle / 57.2958
    local sx = enemy.x + 4
    local sy = enemy.y + 4
    local ex = sx + cos(angle_rad) * sight_length
    local ey = sy + sin(angle_rad) * sight_length

    -- Prれもfe auf Schnittpunkt mit dem Spieler
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

__gfx__
00000000aaaaaaaa9999999988888888000000550000000000050000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9999999908888880000000550000000000055000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9999999980888808000000550000000000005000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9999999986088068000000550000000055005000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9999999988888888000000550000000000555555000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9999999988888888000000550000000000005000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9999999988666688555555550000000000005000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaa9999999986888868555555550000000000005000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
