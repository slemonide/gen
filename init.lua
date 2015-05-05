-- fairly imperfect code
 
local c_air = minetest.get_content_id("air")
local c_water = minetest.get_content_id("default:water_source")
local c_stone = minetest.get_content_id("default:stone")
local c_dirt = minetest.get_content_id("default:dirt")
local c_dirt_with_grass = minetest.get_content_id("default:dirt_with_grass")
 
minetest.register_on_generated(function(minp, maxp, seed) 
 
	local x0,z0,x1,z1 = minp.x,minp.z,maxp.x,maxp.z	-- Assume X and Z lengths are equal
 
	t1 = os.clock()
	local geninfo = "[mg] generates..."
	print(geninfo)
	minetest.chat_send_all(geninfo)

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
 
	for x=minp.x,maxp.x do
		local n = x/4000
		local a = 2
                local land_base = 0
		for k=1,50 do
			land_base = land_base + 300*(math.sin(math.pi * k^a * n)/(math.pi * k^a))
		end
                -- local land_base = 10*math.abs(n + math.sin(n) + math.sin(n + math.sin(n)))
		for z=minp.z,maxp.z do
			for y=minp.y,maxp.y do
				local p_pos = area:index(x, y, z)
				if y == math.floor(land_base) then
					data[p_pos] = c_dirt_with_grass
				elseif y == math.floor(land_base) - 1 then
                                        data[p_pos] = c_dirt
				elseif y < land_base then
					data[p_pos] = c_stone
                                elseif y < 30 then
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
