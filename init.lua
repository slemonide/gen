local SIZE = minetest.setting_get("generator_size")
local chunksize = minetest.setting_get("chunksize")

if not chunksize then
	chunksize = 5
end

if not SIZE then
	SIZE = -300
end

-- Safe size (positive and absolute)
local ssize = math.ceil(math.abs(SIZE))

-- Heights
local h = {}
h.sea = 0
h.ice = ssize * (3/4)

--local recursion_depth = math.ceil(math.abs(SIZE)/10)

local function do_ws_func(depth, a, x)
	local n = x
	local y = 0
	for k=1,depth do
		y = y + (math.sin(math.pi * k^a * n)/(math.pi * k^a))
	end
	return y
end

local ws_lists = {}
local function get_ws_list(a, x, m)
        ws_lists[a] = ws_lists[a] or {}
        local v = ws_lists[a][x]
        if v then
                return v
        end
        v = {}
        for x=x,x + (chunksize*16 - 1) do
		local y = do_ws_func(ssize, a, x / m)
                v[x] = y
        end
        ws_lists[a][x] = v
        return v
end

local function get_distance(x,z)
	y = (x^2 + z^2)^(1/2)
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

minetest.register_on_generated(function(minp, maxp, seed)

	local x0,z0,x1,z1 = minp.x,minp.z,maxp.x,maxp.z	-- Assume X and Z lengths are equal

	local t1 = os.clock()
	local geninfo = "[mg] generates..."
	print(geninfo)
	minetest.chat_send_all(geninfo)

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	local heightx = get_ws_list(3, minp.x, SIZE)
	local heightz = get_ws_list(5, minp.z, SIZE)

	local cave1x = get_ws_list(2, minp.x, SIZE * 20)
	local cave1y = get_ws_list(5, minp.y, SIZE * 20)
	local cave1z = get_ws_list(4, minp.z, SIZE * 20)

	local cave2x = get_ws_list(6, minp.x, SIZE * 20)
	local cave2y = get_ws_list(3, minp.y, SIZE * 20)
	local cave2z = get_ws_list(2.5, minp.z, SIZE * 20)

	for x=minp.x,maxp.x do
		local cave1 = cave1x[x]
		local cave2 = cave2x[x]
		local land_base = heightx[x]
		for z=minp.z,maxp.z do
			local cave1 = cave1+cave1z[z]
			local cave2 = cave2+cave2z[z]
			local cave1 = SIZE/5 * cave1
			local cave2 = SIZE/6 * cave2
			local land_base = land_base + heightz[z]
			land_base = land_base + 1/3*math.sin(get_distance(x/SIZE,z/SIZE))
			if SIZE*math.cos(get_distance(x/SIZE,z)) - land_base > SIZE then
				land_base = land_base + 1/5*math.sin(get_distance(x/SIZE,z/SIZE))
			end
			land_base = SIZE*land_base
			land_base = math.floor(land_base)
			local beach = math.floor(SIZE/97*math.cos((x - z)*10/(SIZE))) -- Also used for ice
			local lower_ground, cave_in_ended
			for y=maxp.y,minp.y,-1 do
				local p_pos = area:index(x, y, z)
				if y < h.sea
				and y > land_base then
					data[p_pos] = c_water
				else
					local cave1 = cave1+cave1y[y]
					local cave2 = cave2+cave2y[y]
					cave1 = cave1%2-1
					cave2 = cave2%2-1
					cave = (cave1 < 0.5 and cave1 > -0.5) and (cave2 < 0.5 and cave2 > -0.5)
					if not cave then
						if y < land_base - 1 then
							data[p_pos] = c_stone
						elseif y == land_base then
							if y > beach + h.ice then
								data[p_pos] = c_snow
							elseif y >= beach + h.sea then
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
							elseif y >= beach + h.sea then
								data[p_pos] = c_dirt
							else
								data[p_pos] = c_sandstone
							end
						end
						if lower_ground then
							cave_in_ended = true
						end
					elseif y == land_base then
						lower_ground = land_base
					elseif lower_ground
					and not cave_in_ended then
						lower_ground = lower_ground-1
					end
				end
			end
			if lower_ground
			and lower_ground ~= minp.y then
				-- a cave appeared on land_base
				local y = lower_ground
				local p_pos = area:index(x, y, z)
				-- a copy of above where the cave wasnt on land_base
				if y > beach + h.ice then
					data[p_pos] = c_snow
				elseif y >= beach + h.sea then
					if y >= h.sea - 1 then
						data[p_pos] = c_dirt_with_grass
					else
						data[p_pos] = c_dirt
					end
				else
					data[p_pos] = c_sand
				end
			end
		end
	end

	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:update_liquids()
	vm:write_to_map()

	local geninfo = string.format("[mg] done after: %.2fs", os.clock() - t1)
	print(geninfo)
	minetest.chat_send_all(geninfo)
end)
