local SIZE = minetest.setting_get("generator_size")
local chunksize = minetest.setting_get("chunksize")

if not chunksize then
	chunksize = 5
end

if not SIZE then
	SIZE = 1000
end



-- Safe size (positive and absolute)
local ssize = math.ceil(math.abs(SIZE))

-- Heights
local h = {}
h.sea = -1
h.ice = ssize * (3/4)

local recursion_depth = math.ceil(math.abs(SIZE)/10)

local function do_ws_func(depth, a, x)
	local n = x/(4*SIZE)
	local y = 0
	for k=1,depth do
		y = y + SIZE*(math.sin(math.pi * k^a * n)/(math.pi * k^a))
	end
	return y
end

local ws_lists = {}
local function get_ws_list(a,x)
        ws_lists[a] = ws_lists[a] or {}
        local v = ws_lists[a][x]
        if v then
                return v
        end
        v = {}
        for x=x,x + (chunksize*16 - 1) do
		local y = do_ws_func(ssize, a, x)
                v[x] = y
        end
        ws_lists[a][x] = v
        return v
end

local function get_distance(x,z,x0,z0)
	if not (x0 or z0) then
		x0 = 0
		z0 = 0
	end
	y = (((x - x0)/(SIZE))^2 + ((z - z0)/(SIZE))^2)^(1/2)
	return y
end

local c_water = minetest.get_content_id("default:water_source")
local c_stone = minetest.get_content_id("default:stone")
local c_dirt = minetest.get_content_id("default:dirt")
local c_dirt_with_grass = minetest.get_content_id("default:dirt_with_grass")
local c_sand = minetest.get_content_id("default:sand")
local c_sandstone = minetest.get_content_id("default:sandstone")
local c_snow = minetest.get_content_id("default:snowblock")
local c_ice = minetest.get_content_id("default:ice")
local c_grass = minetest.get_content_id("default:grass_1")

minetest.register_on_generated(function(minp, maxp, seed)

	local x0,z0,x1,z1 = minp.x,minp.z,maxp.x,maxp.z	-- Assume X and Z lengths are equal

	local t1 = os.clock()
	local geninfo = "[mg] generates..."
	print(geninfo)
	minetest.chat_send_all(geninfo)

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	local heightx = get_ws_list(3, minp.x)
	local heightz = get_ws_list(5, minp.z)

	for x=minp.x,maxp.x do
		local land_base = heightx[x]
		for z=minp.z,maxp.z do
			local land_base = land_base + heightz[z]
			land_base = land_base + SIZE/3*math.sin(get_distance(x,z))
			if SIZE*math.cos(get_distance(x/SIZE,z,100,-1000)) - land_base > SIZE then
				land_base = land_base + SIZE/5*math.sin(get_distance(x,z,12*z,-51*x)/SIZE)
			end
			if math.sin(x/SIZE) + math.sin(z/SIZE) > 0 then
				land_base = land_base + (math.sin(x/SIZE) + math.sin(z/SIZE))*SIZE
			end
			land_base = math.floor(land_base)
			local beach = math.floor(SIZE/97*math.cos((x - z)*10/(SIZE))) -- Also used for ice
			for y=minp.y,maxp.y do
				local p_pos = area:index(x, y, z)
				if y < land_base - 1 then
					data[p_pos] = c_stone
				elseif y == land_base + 1 and y > beach + 1 and y < beach + h.ice and y > h.sea then
					data[p_pos] = c_grass
				elseif y == land_base then
					if y > beach + h.ice then
						data[p_pos] = c_snow
					elseif y >= beach then
						if y >= h.sea - 1 then
							data[p_pos] = c_dirt_with_grass
						else
							data[p_pos] = c_dirt
						end
					else
						data[p_pos] = c_sand
					end
				elseif y == land_base - 1 then
					if y > beach + h.ice then
						data[p_pos] = c_ice
					elseif y >= beach then
						data[p_pos] = c_dirt
					else
						data[p_pos] = c_sandstone
					end
				elseif y < h.sea then
					data[p_pos] = c_water
				end
			end
		end
	end

	vm:set_data(data)
--	vm:calc_lighting()
--	vm:update_liquids()
	vm:write_to_map()

	local geninfo = string.format("[mg] done after: %.2fs", os.clock() - t1)
	print(geninfo)
	minetest.chat_send_all(geninfo)
end)
