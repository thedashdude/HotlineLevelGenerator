--[[					THIS VERSION IS FOR HOTLINEGENERATOR ONLY						]]

--Solids table has tables (Solids) with data .x .y .w .h .tags
--x and y are the position
--w and h are the height
--tags is a table of strings, which you can use to limit checkCollision
--if no tags are provided when a Solid is being set it will have the tag 'solid'

local DashSolids = {Solids={}}

--Given the x,y,width and height of a rectangle, check if it overlaps with any Solids with the specified tag
--tag defaults to 'solid' which is included in any Solid where the tags were not specified
--also returns the name of the Solid it collided with
function DashSolids:checkCollision (x,y,w,h,tag)
	x = x or 0
	y = y or 0
	w = w or 32
	h = h or 32
	tag = tag or 'all'
	for name,v in pairs(self.Solids) do
		if (x+w>v.x and x<v.x+v.w) and (y+h>v.y and y<v.y+v.h) and self:hasTag(name,tag) then
			return true, name
		end
	end
	return false, nil
end

--Clears all solids data
function DashSolids:clear()
	self.Solids = {}
end


--Used to both change and set Solids data.
--All data is changed, so be wary
--If name is nil then the Solid will be then first empty entry in the DashSolids 
function DashSolids:set(name,x,y,w,h,tags)
	name = name or (#self.Solids+1)
	x = x or 0
	y = y or 0
	w = w or 32
	h = h or 32
	tags = tags or {}
	tags.DEFAULT = 'all'
	self.Solids[name] = {}
	self.Solids[name].x = x
	self.Solids[name].y = y
	self.Solids[name].w = w
	self.Solids[name].h = h
	self.Solids[name].tags = tags
	return name
end

--Given a name and a tag to look for, this function will test if the Solid in Solids[name] 
--has a tag of the variable tag
--Requires the name of the Solid
function DashSolids:hasTag(name,tag)
	name = name or 1
	tag = tag or 'all'

	if not self.Solids[name] then return false end
	
	for k,v in pairs(self.Solids[name].tags) do 
		if v == tag then
			return true
		end
	end
	return false
end

--Draws an outline of all Solids
function DashSolids:draw()
	love.graphics.setColor(255,100,100)
	for _,v in pairs(self.Solids) do
		love.graphics.rectangle('line', v.x, v.y, v.w, v.h)
	end
end
return DashSolids