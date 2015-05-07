local SIZE = 1

local ws_lists = {}
local function get_ws_list(a,x)
        ws_lists[a] = ws_lists[a] or {}
        local v = ws_lists[a][x]
        if v then
                return v
        end
        v = {}
        for x=x,x+79 do
                local n = x/(20*SIZE)
                local y = 0
                for k=1,5*SIZE do
                        y = y + 13*SIZE*(math.sin(math.pi * k^a * n)/(math.pi * k^a))
                end
                v[x] = y
        end
        ws_lists[a][x] = v
        return v
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

	local heightx = get_ws_list(3, minp.x)
	local heightz = get_ws_list(5, minp.z)

	for x=minp.x,maxp.x do
		local land_base = heightx[x]
		-- local land_base = 10*math.abs(n + math.sin(n) + math.sin(n + math.sin(n)))
		for z=minp.z,maxp.z do
			local land_base = land_base + heightz[z] + 0.5
			land_base = land_base + SIZE*10*math.sin(((x/(SIZE*10))^2 + (z/(SIZE*10))^2)^(1/2))
			land_base = math_floor(land_base)
			for y=minp.y,maxp.y do
				local p_pos = area:index(x, y, z)
				if y < land_base-1 then
					data[p_pos] = c_stone
				elseif y == math.floor(land_base) then
					if y > 9*SIZE then
						data[p_pos] = c_snow
					elseif y > 0 then
						data[p_pos] = c_dirt_with_grass
					else
						data[p_pos] = c_sand
					end
				elseif y == math.floor(land_base) - 1 then
					if y > 9*SIZE then
						data[p_pos] = c_ice
					elseif y > 0 then
						data[p_pos] = c_dirt
					else
						data[p_pos] = c_sandstone
					end
				elseif y < -3 then
					data[p_pos] = c_water
				end
			end
		end
	end

	vm:set_data(data)
	vm:calc_lighting()
	vm:update_liquids()
	vm:write_to_map()

	local geninfo = string.format("[mg] done after: %.2fs", os.clock() - t1)
	print(geninfo)
	minetest.chat_send_all(geninfo)
end)
