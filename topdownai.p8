pico-8 cartridge // http://www.pico-8.com
version 1
__lua__

-- top down enemy ai
-- by prof.patonildo

--[[
license notice!
this game is released under
cc by-nc-sa 4.0
--]]

-- documentation on tab 4!


function _init()
   
    --[[
    debug variable, 
    table of objects to be drawn,
    table of floating text messages
    --]]
    debug,drawlist,floats=nil,{},{}
   
    -- define custom color palette
    custompalette()
   
    -- ** player **
    p={
        -- x and y position
        x=64,y=64,
        -- direction x and direction y
        dx=0,dy=0,
        --[[
        previous direction
        0==left; 1==right;
        2==up; 3==down
        --]]
        pd=3,
        -- speed
        spd=0.75,
        -- x and y size of the sprite
        sx=1,sy=1,
        -- collision box
        box={
            --[[
            #1 -> top left corner
            #2 -> bottom right corner
            --]]
            {0,2},{7,8},{7,2},{0,8}
        },
        -- current animation frame
        curframe=1,
        -- current atnimation number
        curani=1,
        -- animation/frame timer
        anit=0,
        -- list of animations
        anims={
            -- {{sprite,flipx,flipy},...,timer}
            -- standing
            {{7,true},{8,true},16}, -- left
            {{7},{8},16}, -- right
            {{4},{5},16}, -- up
            {{1},{2},16}, -- down
            -- moving
            {{9,true},{8,true},8}, -- left
            {{9},{8},8}, -- right
            {{6},{5},{6,true},{5},8}, -- up 
            {{3},{2},{3,true},{2},8}, -- down
        },
    }

    -- ** enemies **
    enemies={}
    for i=1,5 do
        local e={
            -- solid atribute. if true, the player can't walk through enemies
            solid=true,
            -- active flag. if true, this means this enemy should be actively seeking the player
            active=false,
            -- collision with other enemies flag. if false, other enemies will ignore collisions with this enemy
            collides=true,
            -- target on sight flag. if true, this means this enemy has a clear sight to the player
            tgtonsight=false,
            -- turn timer, used to count when to change direction
            turntimer=0,
            -- seek timer. counts up until a predetermined value. if it hits that value, deactivate (stop seeking player)
            seektimer=0,
            -- wait timer, used to make the enemy wait some frames under certain conditions
            waittimer=0,
            x=1,y=i*8,
            -- previous x and y position, used to clear colision errors in certain conditions
            px=1,py=i*8,
            -- target x and target y position
            tx=1,ty=i*8,
            dx=0,dy=0,pd=3,
            spd=0.5,
            sx=1,sy=1,
            box={
                {0,2},{7,8},{7,2},{0,8}
            },
            curframe=1,curani=1,anit=0,
            anims={
            -- standing
            {{70,true},{71,true},16}, -- left
            {{70},{71},16}, -- right
            {{67},{68},16}, -- up
            {{64},{65},16}, -- down
            -- moving
            {{72,true},{71,true},{72,true},{71,true},8}, -- left
            {{72},{71},{72},{71},8}, -- right
            {{69},{68},{69,true},{68},8}, -- up 
            {{66},{65},{66,true},{65},8}, -- down
            },
            -- list of sensors used to track player
            sensors={}
        }
        add(enemies,e)
    end

end

function _update60()
   
    -- ** player ** 
    player_update()
   
    -- ** enemies **
    enemies_update()
   
    -- ** y sorting **
    -- empty list of objects to draw
    drawlist={}
    -- collect objects to sort
    local sortlist={}
    add(sortlist,p)
    for i in all(enemies) do
        add(sortlist,i)
    end
    -- sort objects, line by line
    local y=0
    while y<127 do
        for i in all(sortlist) do
            if i.y<=y then
                -- add to draw list, delete from sorting list
                add(drawlist,i)
                del(sortlist,i)
            end
        end
        -- proceed to next line
        y+=1
    end
   
end

function _draw()
   
    cls(3)
   
    -- ** map tiles **
    map()
   
    -- ** objects **   
    for i in all(drawlist) do
        anispr(i)
    end
   
    -- floating texts
    fltxt()
   
    --[
    -- ** debug **
    --[[
    -- player hitbox
    rect(p.x+p.box[1][1],p.y+p.box[1][2],p.x+p.box[2][1],p.y+p.box[2][2],7)
    -- player indicators
    for i in all(p.box) do
        pset(p.x+i[1],p.y+i[2],8)
        pset(i[1]+p.x+p.dx*p.spd,i[2]+p.y+p.dy*p.spd,11)
    end
    --]]
    for i in all(enemies) do
        --[[
        -- enemy hitbox
        rect(i.x+i.box[1][1],i.y+i.box[1][2],i.x+i.box[2][1],i.y+i.box[2][2],7)
        -- enemy indicators
        for j in all(i.box) do
            pset(i.x+j[1],i.y+j[2],8)
            pset(j[1]+i.x+i.dx*i.spd,j[2]+i.y+i.dy*i.spd,11)
        end
        --]]
        -- sensors
        for j in all(i.sensors) do
            pset(j.x,j.y,8)
        end
        -- enemy position and target position
        --[[
        pset(i.x,i.y,14)
        pset(i.tx,i.ty,12)
        --]]
    end
    -- debug variable
    --print(debug,0,0,7)
    --]]

end

-->8
-- general use


-- animate sprite
function anispr(o)
    o.anit+=1
    local ani=o.anims[o.curani]
    if o.anit==ani[#ani] then
        o.anit=0
        o.curframe+=1
        if (o.curframe>#ani-1) o.curframe=1
    end
    local frame=ani[o.curframe]
    --spr(frame[1],o.x,o.y,o.sx,o.sy,frame[2],frame[3])
    outspr(frame[1],o.x,o.y,o.sx,o.sy,frame[2],frame[3])
end

-- change animations
function anichange(o,ani)
    if (o.curani==ani) return
    o.anit,o.curframe,o.curani=0,1,ani
end

-- check map tile
function checktile(cx,cy)
    cx,cy=flr(cx/8),flr(cy/8)
    tile={mget(cx,cy),x=cx,y=cy}
    return tile
end

-- check object collision
function checkobj(o1,o2,dx,dy)
    if (not dx) dx=o1.dx
    if (not dy) dy=o1.dy
    local x1,y1,x2,y2=
        o1.x+dx*o1.spd+o1.box[1][1],
        o1.y+dy*o1.spd+o1.box[1][2],
        o1.x+dx*o1.spd+o1.box[2][1],
        o1.y+dy*o1.spd+o1.box[2][2]
    local x3,y3,x4,y4=
        o2.x+o2.box[1][1],
        o2.y+o2.box[1][2],
        o2.x+o2.box[2][1],
        o2.y+o2.box[2][2]
    if (x1>=x4) return nil
    if (x2<=x3) return nil
    if (y1>=y4) return nil
    if (y2<=y3) return nil
    return o2
end

-- manage floating text
function fltxt()
    for i in all(floats) do
        if (not i.life) i.life=30
        i.life-=1
        if (i.life<=0) del(floats,i)
        if (not i.ty) i.ty=i.y-8
        i.y+=(i.ty-i.y)/10
        i.x+=sin(i.life/10)/2
        if (not i.col) i.col=7
        --print(i.txt,i.x,i.y,i.col)
        outprint(i.txt,i.x,i.y,i.col)
    end
end

-- print outlined text
function outprint(txt,x,y,col1,col2)
    if (not col2) col2=0
    local dir={{-1,0},{-1,-1},{0,-1},{1,-1},{1,0},{1,1},{0,1},{-1,1}}
    --local dir={{-1,0},{0,-1},{1,0},{0,1}}
    for i in all(dir) do
        print(txt,x+i[1],y+i[2],col2)
    end
    print(txt,x,y,col1)
end

-- draw outlined sprites
function outspr(sp,x,y,sx,sy,flipx,flipy,col)
    if (not sx) sx=1
    if (not sy) sy=1
    if (not col) col=0
    --local dir={{-1,0},{-1,-1},{0,-1},{1,-1},{1,0},{1,1},{0,1},{-1,1}}
    local dir={{-1,0},{0,-1},{1,0},{0,1}}
    for i=0,15 do
        pal(i,0)
    end
    for i in all(dir) do
        spr(sp,x+i[1],y+i[2],sx,sy,flipx,flipy)
    end
    pal()
    custompalette()
    spr(sp,x,y,sx,sy,flipx,flipy)
end

-- check distance in 8x8 tiles
function checkdist(o1,o2,of)
    if (not of) of=0
    local x1,y1=flr((o1.x+of)/8),flr((o1.y+of)/8)
    local x2,y2=flr((o2.x+of)/8),flr((o2.y+of)/8)
    local dist=sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))
    return dist
end

-- define palette
function custompalette()
    palt(0,false)
    palt(15,true)
end
-->8
-- player logic


-- ** main player update **
function player_update()

    -- set move direction
    --[[
    this way of getting inputs
    to set directions makes sure
    to only consider 4 way 
    movement (no diagonals!) and
    to avoid inputs from overriding
    one another
    --]]
    if p.dy==0 then
        if btn(0) and btn(1) then
            p.dx=0
        elseif btn(0) then
            p.dx,p.pd=-1,0
        elseif btn(1) then
            p.dx,p.pd=1,1
        else
            p.dx=0
        end
    end
    if p.dx==0 then
        if btn(2) and btn(3) then
            p.dy=0
        elseif btn(2) then
            p.dy,p.pd=-1,2
        elseif btn(3) then
            p.dy,p.pd=1,3
        else
            p.dy=0
        end
    end
   
    -- check for tiles
    local tile=nil
    for i in all(p.box) do
        tile=checktile(i[1]+p.x+p.dx*p.spd,i[2]+p.y+p.dy*p.spd)
        -- react to items
        if (fget(tile[1],1)) mset(tile.x,tile.y,0)
        -- break if found wall
        if fget(tile[1],0) then
            break
        end
    end
   
    -- check for objects
    local object=nil
    for i in all(enemies) do
        object=checkobj(p,i)
        if object then
            break
        end
    end
   
    -- movement
    if not fget(tile[1],0) and not (object and object.solid) then
        p.x+=p.dx*p.spd
        p.y+=p.dy*p.spd
    end
    -- constrain x and y to screen
    p.x,p.y=mid(1,p.x,119),mid(1,p.y,119)
   
    -- animation
    if p.dx==0 and p.dy==0 then
        -- standing still
        if (p.pd==0) anichange(p,1) -- left
        if (p.pd==1) anichange(p,2) -- right
        if (p.pd==2) anichange(p,3) -- up
        if (p.pd==3) anichange(p,4) -- down
    else
        -- moving
        if (p.pd==0) anichange(p,5) -- left
        if (p.pd==1) anichange(p,6) -- right
        if (p.pd==2) anichange(p,7) -- up
        if (p.pd==3) anichange(p,8) -- down
    end

end
-->8
-- enemy logic


-- ** main enemy ai update **
function enemies_update()
   
    -- loop through all enemies
    for i in all(enemies) do
       
        -- reset target status
        i.tgtonsight=false
       
        -- ** sensors logic    **   
        --[[
        for performance reasons, don't
        spawn more than 8 sensors per
        enemy.
        --]]
        if #i.sensors<=8 then
            -- spawn sensor
            local sensor={
                -- sensor position
                x=i.x+4,y=i.y+4,
                -- sensor age (sensors get deleted after a certain age)
                age=0,
                -- sensor collision box
                box={{-2,-2},{2,-2},{2,2},{-2,2}}
            }
            -- calculate angle to player
            sensor.ang=atan2((p.y+4+4*p.dy)-sensor.y,(p.x+4+4*p.dx)-sensor.x)
            -- limit sensor angle (simulate limited fov)
            --[[
            the condition checkdist(i,p,4)>1
            means that the sensor will not be
            removed if the player is 1 tile (8x8 pixels)
            close to this enemy. this is to simulate
            the enemy hearing the player getting
            close to it from behind. if you want the
            player to be able to surprise enemies from
            behind, remove this condition.
            --]]
            if not i.active and checkdist(i,p,4)>1 then
                if i.pd==0 then
                    -- sensors at obtuse angles will get removed quicker
                    if (sensor.ang>0.5 and sensor.ang<1)    sensor.age=28
                    -- if angle exceeds the intended fov, delete the sensor
                    if (sensor.ang>0.55 and sensor.ang<0.95)    sensor=nil
                elseif i.pd==1 then
                    if (sensor.ang>0 and sensor.ang<0.5)    sensor.age=28
                    if (sensor.ang>0.05 and sensor.ang<0.45)    sensor=nil
                elseif i.pd==2 then
                    if (sensor.ang>0.75 or sensor.ang<0.25)    sensor.age=28
                    if (sensor.ang>0.8 or sensor.ang<0.2)    sensor=nil
                elseif i.pd==3 then
                    if (sensor.ang>0.25 and sensor.ang<0.75)    sensor.age=28
                    if (sensor.ang>0.3 and sensor.ang<0.7)    sensor=nil               
                end
            end
            -- if the sensor didn't get deleted, add it to the list for processing
            if (sensor)    add(i.sensors,sensor)
        end
        -- loop through all sensors
        for j in all(i.sensors) do
            -- ** update sensors **
            -- move towards target
            j.x+=sin(j.ang)*4
            j.y+=cos(j.ang)*4
            -- increase age
            j.age+=1
            if j.age>1 then -- sensors must exist for at least 1 frame before the game even considers destroying them
                -- delete old sensors
                if j.age>32 then -- 32 is the max life of the sensor. you can increase or reduce this number
                 del(i.sensors,j)
             end
             -- check for walls
             for k in all(j.box) do
                 -- walls are marked with flag 0
                 if fget(checktile(j.x+k[1],j.y+k[2])[1],0) then
                     del(i.sensors,j)
                    end
                end
            end           
            -- check for player
            -- if the sensor is at least 6 pixels close to the player, a collision with the player occurs
            if abs(j.x-(p.x+4))<=6 and abs(j.y-(p.y+4))<=6 then
                del(i.sensors,j)
                -- prepare the enemy for action!
                if not i.active then
                 local floatlife=30
                 add(floats,{txt="!",x=i.x+3,y=i.y,life=floatlife})
                    i.waittimer,i.turntimer=floatlife,0
                end
                i.tx,i.ty,i.active,i.seektimer,i.tgtonsight=p.x+4*p.dx,p.y+4*p.dy,true,0,true
            end
        end
       
        -- ** behavior logic **
        -- count wait timer
        i.waittimer-=1
        i.waittimer=max(i.waittimer,0)
        -- time to act!
        if i.waittimer<=0 then
            -- count turn timer
            i.turntimer-=1
            i.turntimer=max(0,i.turntimer)
            -- prepare local vars
            local spd,tile,object=1,nil
           
            -- ** actively seeking **
            if i.active then
                -- deactivate if target reached
                if not i.tgtonsight and abs(i.tx-i.x)<=4 and abs(i.ty-i.y)<=4 then
                 i.active,i.turntimer,i.seektimer=false,0,0
                    local floatlife=60
                    add(floats,{txt="?",x=i.x+3,y=i.y,life=floatlife})
                    i.waittimer=floatlife
                    break
                end
                -- deactivate if active time exceeds limit
                i.seektimer+=1
                if i.seektimer>200 then
                 i.active,i.seektimer,i.turntimer,i.dx,i.dy=false,0,0,0,0
                    local floatlife=60
                    add(floats,{txt="?",x=i.x+3,y=i.y,life=floatlife})
                    i.waittimer=floatlife
                    break
                end
                -- ** set move direction **
                -- calculate target position
                local tx,ty=i.tx-i.x,i.ty-i.y
                -- turntimer is used to make enemy move in a stair step manner when needed
                if i.turntimer<=0 then
                    i.turntimer,i.collides=rnd(30)+10,true -- whenever turntimer reaches 0, the collision with other enemies is reactivated
                 if abs(ty)>abs(tx) then
                     i.dx,i.dy=0,sgn(ty)
                 else
                     i.dx,i.dy=sgn(tx),0
                 end
                end
                -- check for objects
                object=echeckobj(i)
                if object then
                    if object[1]==p then
                        -- collided the player, stop moving
                        i.dx,i.dy=0,0
                    else
                        if object[1] then
                            if object[2]=="horizontal" then
                                -- horizontal collision with other enemy, move vertically
                                i.dx,i.dy=0,sgn(ty)
                            elseif object[2]=="vertical" then
                                -- vertical collision with other enemy, move horizontally
                                i.dx,i.dy=sgn(tx),0
                            end
                        end
                    end
                end
                -- check for tiles
                tile=echecktile(i)
                -- if there is a tile, the tile isn't number 0(empty/none) and the tile flag is 0(walls are flag 0)
                if tile and tile[1]!=0 and fget(tile[1],0) then
                    if tile[4]=="horizontal" then
                        -- horizontal collision with wall, move vertically
                        i.dx,i.dy=0,sgn(ty)
                    elseif tile[4]=="vertical" then
                        -- vertical collision with wall, move horizontally
                        i.dx,i.dy=sgn(tx),0
                    end
                end
                -- check for other enemies again, to avoid getting stuck
                object=echeckobj(i,true,true)
                if object then
                    -- this avoids the object from getting stuck inside other enemies, by disabling its collision with other enemies
                    i.dx,i.dy,i.x,i.y,i.turntimer,i.collides=0,0,i.px,i.py,rnd(30)+10,false
                end
           
            -- ** inactive, roaming **
            else
                -- set speed modifier
                -- (move slower when roaming)
                spd=0.25
                -- set move direction
                if i.turntimer<=0 or (i.dx==0 and i.dy==0) or (i.dx!=0 and (i.x<=1 or i.x>=119)) or (i.dy!=0 and (i.y<=1 or i.y>=119)) then
                    -- set a random direction when turntimer reaches 0 or when stopped by a collision or by the screen edges
                    local setdir=rnd({{-1,0},{1,0},{0,-1},{0,1}})
                    i.dx,i.dy,i.turntimer=setdir[1],setdir[2],rnd(300)+300
                end
                -- check for objects
                object=echeckobj(i)
                if object then
                    -- stopping the enemy will trigger it to change direction
                    i.dx,i.dy=0,0
                end
                -- check for tiles
                tile=echecktile(i)
                if tile and tile[1]!=0 and fget(tile[1],0) then
                    -- stopping the enemy will trigger it to change direction
                    i.dx,i.dy=0,0
                end
            end
           
            -- ** regular operations **
            -- these get executed regardless of whether the enemy is active or not, since they are more general behavior
            -- update previous position
            if (not object)    i.px,i.py=i.x,i.y
            -- constrain x and y to screen
            i.x,i.y=mid(1,i.x,119),mid(1,i.y,119)
            -- move
            if tile and not fget(tile[1],0) then
                i.x+=i.dx*i.spd*spd
                i.y+=i.dy*i.spd*spd
            end       
        end
   
        -- set pd for animation
        --[[
        the (i.x==i.px and i.y==i.py)
        condition is important. if it
        is true, that means the enemy is
        stuck. checking for that avoids
        the animation from flipping
        crazily when the enemy gets stuck
        --]]
        if not (i.x==i.px and i.y==i.py) then
            if i.dy==0 then
                if i.dx<0 then
                    i.pd=0 -- left direction
                elseif i.dx>0 then
                    i.pd=1 -- right direction
                end
            end
            if i.dx==0 then
                if i.dy<0 then
                    i.pd=2 -- up direction
                elseif i.dy>0 then
                    i.pd=3 -- down direction
                end
            end
        end
       
        -- animation
        if i.waittimer>0 or (i.dx==0 and i.dy==0) or (i.x==i.px and i.y==i.py) then
            -- standing still
            if (i.pd==0) anichange(i,1) -- left
            if (i.pd==1) anichange(i,2) -- right
            if (i.pd==2) anichange(i,3) -- up
            if (i.pd==3) anichange(i,4) -- down
        else
            -- moving
            -- change animations
            if (i.pd==0) anichange(i,5) -- left
            if (i.pd==1) anichange(i,6) -- right
            if (i.pd==2) anichange(i,7) -- up
            if (i.pd==3) anichange(i,8) -- down
            -- change animation speed
            if i.active then
                i.anims[i.curani][#i.anims[i.curani]]=8
            else
                i.anims[i.curani][#i.anims[i.curani]]=16
                if (i.curframe==#i.anims[i.curani]-1)    i.waittimer=40
            end
        end
   
    end
end


-- ** helper functions **

-- enemy ai checking objects
function echeckobj(i,ignoreplayer,ignoredir)
   
    -- player
    local object=checkobj(i,p)
    if object==p then
        if (not ignoreplayer)    return {p}
   
    else
        -- other enemies
        for j in all(enemies) do
            if j!=i and j.collides then
               
                if ignoredir then
                    -- check current position
                    object=checkobj(i,j,0,0)
                    if object then
                        return {object}
                    end
               
                else
                    -- check horizontal direction
                    object=checkobj(i,j,i.dx,0)
                    if object then
                        return {object,"horizontal"}
                    end
                    -- check vertical direction
                    object=checkobj(i,j,0,i.dy)
                    if object then
                        return {object,"vertical"}
                    end
                end
           
            end
        end
    end
end

-- enemy ai checking tiles
function echecktile(i)
    local tile=nil
    for j in all(i.box) do
       
        -- check horizontal direction
        tile=checktile(j[1]+i.x+i.dx*i.spd,j[2]+i.y)
        if tile[1]!=0 and fget(tile[1],0) then
            tile[4]="horizontal"
            return tile
        end
       
        -- check vertical direction
        tile=checktile(j[1]+i.x,j[2]+i.y+i.dy*i.spd)
        if tile[1]!=0 and fget(tile[1],0) then
            tile[4]="vertical"
            return tile
        end
    end
   
    return tile

end
-->8
-- documentation

--[[

this is an example of how to
do enemies that somewhat follow
and try to seek the player.

it works like this:
    - each enemy shoots sensors
    towards the player
   
    - if a sensor hits a wall, it
    gets deleted
   
    - if a sensor exceeds a set
    ammount of time, it gets deleted
   
    - if a sensor hits the player,
    a position gets marked as a 
    target for the enemy that emmited
    that sensor
   
    - enemies will move to their
    target positions
   
    - enemies will roam randomly
    when the player hasn't been
    detected
   
    - enemies have a fov: sensors
    are emitted only if they are
    inside the range of this fov.
   
    - if the player gets too close
    to enemies, they will detect
    the player, regardless of their
    fov.
   
    - if the enemy can't find the
    player, it will get deactivated
    after a set ammount of frames
    or after it reaches its target
    position.

this example also features:
    - a bunch of helper functions
    - animation system
    - y sorting system
    - outlined sprites
    - outlined text printing
    - floating text messages system

if this was helpful or interesting
for you, please give my itch.io page
a visit https://profpatonildo.itch.io/
or consider buying me a coffee 
https://ko-fi.com/profpatonildo70266

--]]