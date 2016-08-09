--Hotline Generator

--[[
Notes on functionality: 
all rooms are placed on coords that are multiples of 3, this makes the smallest rooms still reasonable
and allows enemies to placed on coords which are 1 more than a multiple of 3, meaning all enemies will never be placed on walls.
Doors are placed in a similar manner, horizontal doors are placed on multiple of 3s ys and 1 more than a multiple of 3 x, meaning they are never too close to a vertical wall
vertical doors have similar placeent technique

floors, walls and enemies have coords simplified for most of the program. only in the functions that actually place them are the coords multiplied by 32 to put them in the same scale as the size of the walls and collision boxes

the building is alwasy from (0,0) to (30,18)
that is in the games coords from (0,0) to (960,576).
x32 as mentioned above

the format of the level files are explained in a different file

a basic rundown of how levels are made:
the building is made as a 30x18 room.
it is then filled with rooms of various sizes, without overlap.
1-2 Doors are placed on each room. 
an algorithm is run to make sure all rooms are reachable, and doors are added if not. 
2 enemies are placed near the center of each room of random type
then a random number of enemies are scattered around the building.

]]








--The function that builds the level
function generator()
    -- corners are kept track of with q, e, z, and c representing the different corners. 
    done = {}
    --[[
    they represent them like this:
    q e
    
    z c
    that is, q is the top left, e is top right, z bottom left, c bottom right
    ]]

    --this keeps track of if the corners have had rooms placed on them yet.
    done.q = false
    done.e = false
    done.z = false
    done.c = false

    --place the rooms, with a 50% chance to try to place a corner room and a 50% chance to place a float room, that is one that does not touch the edges of the building
    while rooms>0 do
        if r() > 0.5 then
            corner()
        else
            float()
        end
    end
    
    --place all the enemies
    while mafia > 0 do
        mafia = mafia - 1
        --random coords that will not interset with walls
        x,y = math.floor(r(0,9))*3+1,math.floor(r(0,5))*3+1

        --make sure you do not place an enemy on one that is there already
        while not canPlaceMafia(x,y) do
            x,y = math.floor(r(0,9))*3+1,math.floor(r(0,5))*3+1
        end

        --place a random enemy at x,y
        placeEnemy(x,y,addMeleeRandomEnemy,addMeleePatrolEnemy,addGunRandomEnemy,addGunPatrolEnemy,3,4,2,5)
    end

    --placing rooms adds entries to boxLocations
    --we use these to place doors on rooms
    for i = 1, #boxLocations do
        makeDoorInBox(boxLocations[i][1],boxLocations[i][2],boxLocations[i][3],boxLocations[i][4], boxLocations[i][5])
    end

    --place the building as one huge room around the others and then place a door by the botton left by the car
    box(0,0,30,18)
    removeWallsAt(1,18,'H')
    doorFunctions['addHDoor'](1,18)
    
    --this makes sure all rooms are reachable
    while not checkFlood() do
        fixFlood()
    end

    --the level is done
end

--tests to see if an enemy has been placed on (x,y) before
function canPlaceMafia(x,y)
    for i=1,#mafiaCords do
        if x == mafiaCords[i][1] and y == mafiaCords[i][2] then
            return false
        end
    end
    return true
end

--tries to place a corner room
function corner()
    --choose where the room will be
    --xend and yend are one set of coords, the other will be deterimined by choosing a corner of the building
    xend,yend = math.floor(math.random()*9 + 1)*3, math.floor(math.random()*5 + 1)*3
    xstart, ystart = 0,0
    direc = nil

    --pick a corner that has not been chosen before, mark is as having been chosen and set the xstart and ystart coords apropriately
    if math.random() > 0.75 and not done.q then
        xstart, ystart = 0,0
        done.q = true
        direc = 'q'
    elseif math.random() > 2/3 and not done.e then
        xstart, ystart = 30,0
        done.e = true
        direc = 'e'
    elseif math.random() > 1/2 and not done.c then
        xstart, ystart = 30,18
        done.c = true
        direc = 'c'
    elseif not done.z then 
        xstart, ystart = 0,18
        done.z = true
        direc = 'z'
    else
        --if there are no open corners, leave this function
        rooms = rooms - 1
        return 0
    end

    --makeCoordsWH takes two pairs of coords and returns 4 values, a top left x and y and a width and height
    xLeft, yTop, w,h  = makeCoordsWH(xend,yend,xstart,ystart)

    --lim makes sure you dont spend too long checking random rooms to see if they work
    lim = 0

    --DashSolids:checkCollision(xLeft,yTop,w,h) tests to see if the room intersects a previously placed room
    --(w^2 + h^2)^0.5 > 14 makes sure the room is of a reasonable size by limiting the diagonal
    --( (w^2 + h^2)^0.5 < 5 and r()<0.66 ) makes the loop try again 2/3s of time if the room is really tiny, because tiny rooms aren't very fun
    while DashSolids:checkCollision(xLeft,yTop,w,h) or (w^2 + h^2)^0.5 > 14 or ( (w^2 + h^2)^0.5 < 5 and r()<0.66 ) do
        -- if any of those conditions are met the loop repicks coords and tries again
        xend,yend = math.floor(math.random()*9 + 1)*3, math.floor(math.random()*5 + 1)*3
        xLeft, yTop, w,h  = makeCoordsWH(xend,yend,xstart,ystart)
        --if you have tried 100 times, leave so generation doesn't take forever
        lim = lim + 1
        if lim > 100 then
            rooms = rooms - 1
            return 0
        end
    end

    --This records the rooms placement in DashSolids so other rooms are checked to see if they collide with this one
    DashSolids:set(nil,xLeft, yTop, w, h)

    --place this room as walls
    box(xstart,ystart,xend,yend,direc)

    --you have placed a room, record this
    rooms = rooms - 1
end

--takes two sets of coords and returns it in the form x,y,width,height
function makeCoordsWH(x1,y1,x2,y2)
    x = math.min(x1,x2)
    y = math.min(y1,y2)
    return x, y, math.abs(x1-x2), math.abs(y1-y2)
end

--place a floating room, that is one that doesn't touch the outside walls of the building
function float( ... )
    --pick to coords for the room
    x, y = math.floor(r(1,8))*3, math.floor(r(1,4))*3
    x2, y2 = math.floor(r(x/3+1,9))*3, math.floor(r(y/3+1,5))*3

    --determine the width and height of the room
    w,h = x2-x,y2-y

    --the same loop as in corner(), makes sure the room is reasonable 
    lim = 0
    while DashSolids:checkCollision(x,y,w,h) or (w^2 + h^2)^0.5 > 14 or ( (w^2 + h^2)^0.5 < 5 and r()<0.66 )  do
        lim = lim + 1
        if lim > 100 then
            rooms = rooms - 1
            return 0
        end
        x, y, w, h = math.floor(math.random()*6 + 1)*3, math.floor(math.random()*2 + 1)*3, math.floor(math.random()*3 + 1)*3, math.floor(math.random()*3 + 1)*3
    end

    --place the room, record it in DashSolids, and decrement the number of rooms left to place
    box(x,y,x+w,y+h)
    DashSolids:set(nil,x,y,w,h)
    rooms = rooms - 1
end

--this places a room, or box, at the specified coords. direc is only really used to tell the box if it is a corner
function box(x1,y1,x2,y2,direc)
    --take the coords and make them easier to work with finding the larger and smaller of the two values of each of x and y
    xS = math.min(x1,x2) --smaller x
    xL = math.max(x1,x2) --larger x
    yS = math.min(y1,y2) --smaller y
    yL = math.max(y1,y2) -- larger y

    --the amount of glass left to place in a sequence of glass. if it is zero, as it mostly will be, dont place glass
    glass = 0

    --the percent chance placing a single wall will begin a glass sequence. I am not a glass fan, so I have this as 1
    glassPercent = 1

    --place the walls on the horizontal y1 side
    for i = xS, xL-1 do

        --if glass is zero (or less) place walls as normal
        if glass <= 0 then
            --place the wall
            addHWall(i,y1)
            --with glassPercent chance begin a glass sequence of 2-5 glass inclusive
            if math.floor(r(1,100)) <= glassPercent then
                glass = math.floor(r(2,5))
            end
        else
            --if in a glass sequence place glass and decrease the glass left to place
            addHGlass(i,y1)
            glass = glass - 1
        end
    end
    --reset the amount of glass to zero
    glass = 0

    --all the following for loops do the same for different sides of the room
    --horizontal y2 side
    for i = xS, xL-1 do
        if glass <= 0 then
            addHWall(i,y2)
            if math.floor(r(1,100)) <= glassPercent then
                glass = math.floor(r(2,5))
            end
        else
            addHGlass(i,y2)
            glass = glass - 1
        end
    end
    glass = 0

    --vertical x1 side
    for i = yS, yL-1 do
        if glass <= 0 then
            addVWall(x1,i)
            if  math.floor(r(1,100)) <= glassPercent then
                glass = math.floor(r(2,5))
            end
        else
            addVGlass(x1,i)
            glass = glass - 1
        end
    end
    glass = 0

    --vertical x2 side
    for i = yS, yL-1 do
        if glass <= 0 then
            addVWall(x2,i)
            if math.floor(r(1,100)) <= glassPercent then
                glass = math.floor(r(2,5))
            end
        else
            addVGlass(x2,i)
            glass = glass - 1
        end
    end

    --n and n2 choose the flooring that the room will be filled with (n is the x on the sprite sheet, n2 is the y)
    n = math.floor(r(0,2))*4
    n2 = math.floor(r(0,10))

    --fill in the box with floor
    for xi = xS, xL -1 do
        for yi = yS, yL-1 do
            addFloor(xi,yi,n,n2)
        end
    end

    --mafia will be greater than 0 on all boxes/rooms but the building that surrounds them all.
    --this adds the box location to the table that the doors will be placed from for all rooms but the building, which has a special way of getting doors.
    if mafia > 0 then
        --direc makes sure corner rooms dont have doors into the outside
        boxLocations[#boxLocations+1] = {xS,yS,xL,yL,direc}
        --50% chance to have 2 doors
        if r() >0.5 then
            boxLocations[#boxLocations+1] = {xS,yS,xL,yL,direc}
        end
    end

    -- for all placed rooms but the building, place two enemies in them
    if mafia > 0 then
        --corner z is the one jacket must enter through, so if this room is tha one, enemy spawing is different
        if direc ~= 'z' then
            placeEnemy((xS+xL)/2,(yS+yL)/2,addMeleeRandomEnemy,addMeleePatrolEnemy,addGunRandomEnemy,addGunPatrolEnemy,3,4,2,5)
            placeEnemy((xS+xL)/2+1,(yS+yL)/2+1,addMeleeRandomEnemy,addMeleePatrolEnemy,addGunRandomEnemy,addGunPatrolEnemy,3,4,2,5)
        else
            -- the two enemies placed have 0% chance of being gun carrying enemies
            placeEnemy((xS+xL)/2,(yS+yL)/2,addMeleeRandomEnemy,addMeleePatrolEnemy,addGunRandomEnemy,addGunPatrolEnemy,3,4,0,0)
            placeEnemy((xS+xL)/2,(yS+yL)/2+1,addMeleeRandomEnemy,addMeleePatrolEnemy,addGunRandomEnemy,addGunPatrolEnemy,3,4,0,0)
        end
    end
end

--given a rooms coords and possibly its corner, place a door randomly on it
function makeDoorInBox(xS,yS,xL,yL,direc)--q e z c format
    -- holder values for x and y
    x,y = 0,0
    dir = ''
    directions = 'qezc'
    n = math.floor(r(1,4))
    --if specified direc stays the same, otherwise it is randomy picked from the string above, "qezc"
    direc = direc or directions:sub(n,n)

    --depending on what corner the room is in, or randomly if it isn't, determine the coords of the door
    --the door isn't placed on the buildings walls, so q cant have doors on the top or left wall, e cant have doors on the top or right wall and so on
    if direc == 'q' then
        if r() >= 0.5 then
            --dir is the orientation of the door, V is vertical and H is horizontal
            dir = 'V'
            --xL is the larger of the two xs, or the right side
            x = xL
            --one more than a multiple of 3 from yS to yL
            y = math.floor(math.floor(r(yS+1,yL-1))/3)*3+1
        else
            dir = 'H'
            y = yL
            x = math.floor(math.floor(r(xS+1,xL-1))/3)*3+1
        end
    end
    -- all the other ifs do the same thing
    if direc == 'e' then
        if r() >= 0.5 then
            dir = 'V'
            x = xS
            y = math.floor(math.floor(r(yS+1,yL-1))/3)*3+1
        else
            dir = 'H'
            y = yL
            x = math.floor(math.floor(r(xS+1,xL-1))/3)*3+1
        end
    end
    if direc == 'z' then
        if r() >= 0.5 then
            dir = 'V'
            x = xL
            y = math.floor(math.floor(r(yS+1,yL-1))/3)*3+1
        else
            dir = 'H'
            y = yS
            x = math.floor(math.floor(r(xS+1,xL-1))/3)*3+1
        end
    end
    if direc == 'c' then
        if r() >= 0.5 then
            dir = 'V'
            x = xS
            y = math.floor(math.floor(r(yS+1,yL-1))/3)*3+1
        else
            dir = 'H'
            y = yS
            x = math.floor(math.floor(r(xS+1,xL-1))/3)*3+1
        end
    end

    --removes the walls that the door will replace
    removeWallsAt(x,y,dir)

    --place the door, using dir to determine the function to be called
    doorFunctions['add'..dir..'Door'](x,y)

    --floodTable will be explained later, towards the bottom with the associated functions
    floodTable[x][y] = 0
end

--r is a function that gets a random number.
--if no parameters are passed it returns a number from [0,1)
--otherwise a number (non-integer) from [min,max+1)
--this means math.floor(r(min,max)) returns an integer from min to max inclusive
function r(min,max)
    min = min or 0
    max = max or 0
    return min+math.random()*(max+1-min)
end

--add flooring at x,y with sprite on the sprite sheet k,l
function addFloor(x,y,k,l)
    --floors sprites are 16*16, so to have this function work on the same scale as the other functions it must place four floor sprites
    k = k or 0
    l = l or 0
    l = l * 16
    k = k * 16
    tlsTable[#tlsTable+1] = "2\n" .. k .. "\n"..l.."\n" .. (x*32) .. "\n" .. (y*32) .. "\n1001\n"
    tlsTable[#tlsTable+1] = "2\n" .. k .. "\n"..l.."\n" .. (x*32+16) .. "\n" .. (y*32) .. "\n1001\n"
    tlsTable[#tlsTable+1] = "2\n" .. k .. "\n"..l.."\n" .. (x*32) .. "\n" .. (y*32+16) .. "\n1001\n"
    tlsTable[#tlsTable+1] = "2\n" .. k .. "\n"..l.."\n" .. (x*32+16) .. "\n" .. (y*32+16) .. "\n1001\n"
end

--add a horizontal wall at x,y ( this means going to right of x,y )
function addHWall(x,y)
    --remove any walls that would be there
    removeWallsAt(x,y,'H')
    wllTable[#wllTable+1] = '7' .. '\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '62\n0'.. '\n'
    floodTable[x][y] = 2
end

--add a vertical wall at x,y ( this means going down form x,y )
function addVWall(x,y)
    --remove any walls that would be there
    removeWallsAt(x,y,'V')
    wllTable[#wllTable+1] = '8' .. '\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '63\n0'.. '\n'
    floodTable[x][y] = 2
end

--add a random moving melee enemy at x,y
--has weapon 73 or 74 (club or knife)
function addMeleeRandomEnemy(x,y)
    objTable[#objTable+1] = '10\n' .. (x*32).. '\n' .. (y*32).. '\n' .. is73or74() .. '\n0\n875\n0\n'
end

--add a patroling melee enemy at x,y
--has weapon 73 or 74 (club or knife)
function addMeleePatrolEnemy(x,y)
    objTable[#objTable+1] = '10\n' .. (x*32).. '\n' .. (y*32).. '\n' .. is73or74() .. '\n0\n938\n0\n'
end

--add a patroling gun enemy at x,y
--has weapon a weapon from {70,75,68,69,1500}
function addGunPatrolEnemy(x,y)
    objTable[#objTable+1] = '10\n' .. (x*32).. '\n' .. (y*32).. '\n' .. getGun() .. '\n0\n878\n0\n'
end

--add a random moving gun enemy at x,y
--has weapon a weapon from {70,75,68,69,1500}
function addGunRandomEnemy(x,y)
    objTable[#objTable+1] = '10\n' .. (x*32).. '\n' .. (y*32).. '\n' .. getGun() .. '\n0\n876\n0\n'
end

--pick a gun for a gun enemy
function getGun( ... )
    --{70,75,68,69,1500} corespond to (M16, Silencer, Double Barrel, Shotgun, Kalashnikov)
    guns = {70,75,68,69,1500}
    return guns[math.floor(r(1,#guns))]
end

--place an enemy at x,y by calling a function a,b,c, or d with the provided ratios
function placeEnemy(x,y,a,b,c,d,aRatio,bRatio,cRatio,dRatio)
    ratioSum = aRatio+bRatio+cRatio+dRatio
    n = math.floor(r(1,ratioSum))

    --remember where you placed it so enemies dont overlap
    mafiaCords[#mafiaCords+1] = {x,y}
    if n<=aRatio then
        a(x,y)
    elseif n<=bRatio+aRatio then
        b(x,y)
    elseif n<=cRatio+bRatio+aRatio then
        c(x,y)
    else
        d(x,y)
    end
end

--Well, uh, I, uh...
--This was necessary at the time.
--Trust me
function is73or74()
    --Pick either 73 or 74
    if math.random() > 0.5 then
        return 73
    end
    return 74
end

--add horizontal glass at x,y, removing any wall that may have been there before
function addHGlass( x,y )
    removeWallsAt(x,y,'H')
    wllTable[#wllTable+1] = '683' .. '\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '1997\n0'.. '\n'
    floodTable[x][y] = 2
end

--add vertical glass at x,y, removing any wall that may have been there before
function addVGlass( x,y )
    removeWallsAt(x,y,'V')
    wllTable[#wllTable+1] = '682' .. '\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '1996\n0'.. '\n'
    floodTable[x][y] = 2
end

--[[
the flood functions and flood table are used to make sure you can reach all rooms.
any wall or glass placed marks is position on the floodTable with a 2
everything else is by default a 0

floodTable has x values from 0 to 30 and y from 0 to 18

flood table looks like 

2222222222222222222
2000000000000000002
2000000002000000002
2000000002000000002
2000000000000000002
2000000002000000002
2222222222222022222
2000000000000002002
2002002000000002002
2002022022222220002
2000000002000000002
2002000002000000002
2002222222002222002
2000000000002002002
2002000002002002002
2002222222222020002
2002000000000000002
2002000002002000002
2002000002002000002
2002000002000000002
2002000002002000002
2002222222222022222
2000002000000000002
2000002000000002002
2222022222222222002
2000000000000002002
2000000000002002002
2000000000002222002
2000000000000002002
2000000000002002002
2222222222222222220

]]

--checkFlood sets floodTable[1][1] to 1 from 0 and then sets all 0s adjacent to 1s to 1s
--and repeats this until flood table is all 1s and 2s or until it has filled all it could
--this is the titular 'flooding'
--if anything is still a 0 the building fails the checkFlood and a door must
--be placed so the unflooded rooms can be reached
function checkFlood()
    floodTable[1][1] = 1
    --flood the table
    for k = 0, 29*17 do
        for i = 1, 29 do
            for j = 1, 17 do
                flood(i,j)
            end
        end
    end

    --test to see if everything flooded
    for i = 1, 29 do
        for j = 1, 17 do
            if floodTable[i][j] == 0 then
                return false
            end
        end
    end
    return true
end

--sets floodTable[x][y] to 1 if it is next to another 1 and isn't a 2
--is used by checkFlood()
function flood(x,y)
    if floodTable[x][y] == 2 then
        return 0
    end

    if floodTable[x-1][y] == 1 or floodTable[x+1][y] == 1 or floodTable[x][y-1] == 1 or floodTable[x][y+1] == 1 then
        floodTable[x][y] = 1
    end
end

--called if the building fails checkFlood()
--goes through all cells in floodTable and calls checkTransition() on them
--by calling this until checkFlood succeeds the level is garunteed to have all rooms be reachable
function fixFlood( ... )
    for i = 1, 29 do
        for j = 1, 17 do
            if checkTransition(i,j) then
                return 0
            end
        end
    end
end

--checkTransition checks if a cell is a wall with flooded area on one side and unflooded area on the other
--if the cell is and its coords are acceptable as doors (see Notes on Functionality) it has a chance of
--placing a door at x,y 
function checkTransition(x,y)
    dir = ''
    if not (x%3 + y%3 == 1) then
        return false
    end
    if floodTable[x][y] == 2 and floodTable[x-1][y]+floodTable[x+1][y] == 1 then
        dir = 'V'
    elseif floodTable[x][y] == 2 and floodTable[x][y-1]+floodTable[x][y+1] == 1 then
        dir = 'H'
    else
        return false   
    end


    if math.floor(r(1,100)) <= 5 then
        removeWallsAt(x,y,dir)
        doorFunctions['add'..dir..'Door'](x,y)
        floodTable[x][y] = 1
        return true
    end
    return false
end

--looks through wllTable and removes any glass or walls with the specified coords and direction
--used primarily for clearing room for doors
function removeWallsAt(x,y,dir)
    dir = dir or 'H'
    i = 1
    while i <= #wllTable do
        --not really an easier way to write this if, but it is ugly, just checks for the wall or glass text corresponding to the provided direction
        if (dir == 'H' and wllTable[i] == ('7' .. '\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '62\n0'.. '\n')) or (dir == 'V' and wllTable[i] == ('8' .. '\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '63\n0'.. '\n')) or (dir == 'H' and wllTable[i] == ('683' .. '\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '1997\n0'.. '\n')) or (dir == 'V' and wllTable[i] == ('682' .. '\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '1996\n0'.. '\n')) then
            table.remove(wllTable,i)
            i= i-1
        end
        i = i + 1
    end
end




--These are functions for placing doors, placed in a table so that they can be called like this:
--doorFunctions["addVDoor"](x,y)
--which allows you to choose what function to call with string manipulation
doorFunctions = {}
function doorFunctions.addVDoor(x,y)
    obj = obj .. '25\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '91' .. '\n0\n0\n0\n'
    objTable[#objTable+1] = '25\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '91' .. '\n0\n0\n0\n'
end
function doorFunctions.addHDoor(x,y)
    obj = obj .. '26\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '92' .. '\n0\n0\n0\n'
    objTable[#objTable+1] = '26\n' .. (x*32).. '\n' .. (y*32).. '\n' .. '92' .. '\n0\n0\n0\n'
end


--Set the random seed to the time to get a unique level each time.
math.randomseed( os.time() )

--DashSolids is a file that helps detect collisions, this loads it
DashSolids = require('DashSolids')

-- the files that need to be changed are level0.wll, level0.wobj, and level0.tls

-- tables are used with each entry being a distinct object/sprite then concatenated into a string at the end of generating the level
-- this allows entries to be removed if you know the index
-- the initial text in the obj string is the car jacket comes out of

obj = [[1583
63
740
4154
0
2345
0
]]

wllTable = {}
objTable = {}
objTable[1] = obj
tlsTable = {}

--floodTable is a table used to tell if all rooms are accessable
--it starts as all 0s
floodTable = {}
for i = 0, 30 do
    floodTable[i] = {}
    for j=0,18 do
        floodTable[i][j] = 0
    end
end

--the number of rooms to try to place, an integer between 20 and 30 inclusive
rooms = math.floor(r(20,30))

--the number of enemies to place, an integer between 10 and 15 inclusive
mafia = math.floor(r(10,15))

--a list of all locations enemies have been placed, used to avoid placing enemies on top of each other
mafiaCords = {}

--a list of all places boxes (rooms) have been placed. this is used to place doors after all rooms have been placed
boxLocations = {}

--call the function that builds the level
generator()

--convert the tables to strings
wll = ""
for i=1,#wllTable do
    wll = wll..wllTable[i]
end
obj = ""
for i=1,#objTable do
    obj = obj..objTable[i]
end
tls = ""
for i=1,#tlsTable do
    tls = tls..tlsTable[i]
end

--open all the files and write the data to them. These are not the files used by HM2, but you can copy the data from the txt files to the .wll, .obj and .tls files
f = io.open('level0.wll','w')
f:write(wll)
f:close()
f = io.open('level0.obj','w')
f:write(obj)
f:close()
f = io.open('level0.tls','w')
f:write(tls)
f:close()
f = io.open('level0.play','w')
f:write('')
f:close()
