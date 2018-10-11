
minetest.register_on_joinplayer(function(player)
	if not( player:get_attribute("sculptool") ) then
		player:set_attribute( "sculptool", minetest.serialize({}) )
	end
end)

minetest.register_on_newplayer(function(player)
	player:set_attribute( "sculptool", minetest.serialize({}) )
end)




local sculpt_list_moreblocks_knows = {}
local boucle = 0


minetest.register_globalstep(function(dtime)
	

	
	if  boucle <= 2 then

		for name, namecut in pairs(circular_saw.known_nodes) do
		
			if not(sculpt_list_moreblocks_knows[name])then
				if minetest.registered_nodes[name] then
					local def_groups = stairsplus.copytable(minetest.registered_nodes[name].groups)
					
					def_groups.cuttable = 1
					
					minetest.override_item(name, {
						node_cut_by_moreblocks = {namecut[1], namecut[2]},
						groups = def_groups,
					})
					
					
					
					
					
					local node_origin = name
					
					local micro_node_origin = namecut[1] ..":micro_".. namecut[2]			
					local sculpt = minetest.registered_items[node_origin].groups.sculpt
					if sculpt == 2 then
						node_origin = minetest.registered_nodes[node_origin].node_origin_deco
						micro_node_origin = circular_saw.known_nodes[node_origin]
						micro_node_origin = micro_node_origin[1] ..":micro_".. micro_node_origin[2]
					end
					
					--[[
					minetest.register_craft({
						output = node_origin,
						type = "shapeless",
						recipe = { micro_node_origin, micro_node_origin, micro_node_origin,
								micro_node_origin,	micro_node_origin,	micro_node_origin,
								micro_node_origin,micro_node_origin},
					})
					--]]
					
					for i,alternate in pairs(circular_saw.names) do
						
						local nodename = namecut[1] .. ":" .. alternate[1] .."_".. namecut[2] .. alternate[2]
						local def_cost = circular_saw.cost_in_microblocks[i]
						local def_groups = stairsplus.copytable(minetest.registered_nodes[name].groups)
						
						def_groups.cut = 1
						
						
						if def_cost == 8 then
							def_drop = node_origin
						else
							def_drop = micro_node_origin .." ".. def_cost
							micro = true
						end

						minetest.override_item(nodename, {
							drop = def_drop,
							node_origin = name,
							moreblocks_cost = def_cost,
							on_place = minetest.rotate_node,
							after_place_node = 
								function(pos, placer, itemstack, pointed_thing)
									local player_tool = minetest.deserialize(placer:get_attribute("sculptool"))
									local nodename = placer:get_wielded_item():get_name()
									local node_origin = nodename
									local count_in_hand = placer:get_wielded_item():get_count()
									local count_in_inv = placer:get_inventory():contains_item("main", node_origin .. " 3" )
									
									if not(player_tool[node_origin]) or count_in_hand > 1 or count_in_inv then
										return
									end
									
									local cost = 0
									local def_drop = minetest.registered_nodes[node_origin].drop
									
									local group = minetest.registered_nodes[node_origin].groups.cut
									if group then
										cost = minetest.registered_nodes[node_origin].moreblocks_cost
										def_drop = minetest.registered_nodes[node_origin].drop
										node_origin = minetest.registered_nodes[node_origin].node_origin
									end

									group = minetest.registered_items[node_origin].groups.sculpt
									
									if group == 2 then
										node_origin = minetest.registered_nodes[node_origin].node_origin_deco
									end
																		
									local micro_node_origin = nil
									local micro_node_exception = true
									group = minetest.registered_nodes[node_origin].groups.cuttable
									
									if group then
										micro_node_origin = minetest.registered_nodes[node_origin].node_cut_by_moreblocks
										micro_node_origin = micro_node_origin[1] ..":micro_".. micro_node_origin[2]
										if micro_node_origin .. " 1" == def_drop then
											micro_node_exception = placer:get_inventory():contains_item("main", micro_node_origin .. " 2" )
										end
									end
									
									local inv_drop = placer:get_inventory():contains_item("main", def_drop)
									local inv_node = placer:get_inventory():contains_item("main", node_origin)

									if inv_node or (inv_drop and micro_node_exception) then
										if inv_drop and micro_node_exception then
											placer:get_inventory():remove_item("main", def_drop)
										elseif inv_node then
											minetest.chat_send_all("node")
											placer:get_inventory():remove_item("main", node_origin)
											if micro_node_origin .. " 1" == def_drop then
												itemstack:add_item("main", micro_node_origin .." 6")
											else
												placer:get_inventory():add_item("main", micro_node_origin .." ".. 8 - cost)
											end
										end
										
										if micro_node_origin .. " 1" == def_drop then
											micro_node_exception = placer:get_inventory():contains_item("main", micro_node_origin .. " 2" )
										end
										inv_drop = placer:get_inventory():contains_item("main", def_drop)
										inv_node = placer:get_inventory():contains_item("main", node_origin)
										if not(inv_node) and (not(inv_drop) or not(micro_node_exception))  then
											itemstack:replace("sculptool:tool")
											player_tool[nodename] = nil
											placer:set_attribute("sculptool", minetest.serialize(player_tool))
											return itemstack	
										end
										if micro_node_origin .. " 1" == def_drop then
											return itemstack
										end
										return true
									else
										minetest.remove_node(pos)
										itemstack:replace("sculptool:tool")
										player_tool[nodename] = nil
										placer:set_attribute("sculptool", minetest.serialize(player_tool))
										return itemstack
									end
								
								end
							,
						})
					end
				end
				sculpt_list_moreblocks_knows[name] = true
			else 
				boucle = boucle+1
				
			end
		end
	end
	
end)	

function sculptool_add(node, list)

	--Ecrire les node deco dans le node de base group sculpt = 1
	minetest.registered_nodes[node].groups.sculpt = 1
	
	minetest.override_item(node, {
		sculptool = list,
	})

	--Reecrire les node deco groups sculpt = 2

	for _, nodelist in ipairs(list) do 
		minetest.registered_nodes[nodelist].groups.sculpt = 2
		
		
		minetest.override_item(nodelist, {
			drop = node,
			node_origin_deco = node,
			after_place_node = 
				function(pos, placer, itemstack, pointed_thing)
					local node = placer:get_wielded_item():get_name()
					local player_tool = minetest.deserialize(placer:get_attribute("sculptool"))
					local count_in_hand = placer:get_wielded_item():get_count()
					if not(player_tool[node]) or count_in_hand > 1 then
							return
					end
					
					
					local node_origin = minetest.registered_nodes[node].node_origin_deco
				
					if not(placer:get_inventory():contains_item("main", node_origin)) then
						minetest.remove_node(pos)
						itemstack:replace("sculptool:tool")
						return itemstack
					end 
					placer:get_inventory():remove_item("main", node_origin)
					if placer:get_inventory():contains_item("main", node_origin) then
						return true
					else
						itemstack:replace("sculptool:tool")
						return itemstack
					end
				end
			,
		})
	end


end

local function sculpt_formspec_cut(scale, pos, node, player )
	
	local mod, name = node:match("(.*):(.*)")
	local sculpt = minetest.registered_items[node].groups.sculpt
	
	if mod == "default" then mod = "moreblocks" end
	
	local head = ""

	if sculpt == 2 then
		head = "item_image_button["..7 * scale / 2 - scale / 2 ..",0;" .. scale .. "," .. scale.. ";".. 
		node..
		";sculptool,".. node ..",c0,"..pos.x..","..pos.z..","..pos.y..",".. player:get_player_name() ..",;]"
	end
	
	local moreblock = {
		[1] = {":micro_",""},
		[2] = {":panel_",""},
		[3] = {":slab_",""},
		[4] = {":stair_",""},
		[5] = {":slope_","_cut"},
		[6] = {":slope_","_outer"},
		[7] = {":slab_","_three_sides_u"},
		}

	local formspec = 
		"size[".. 7 * scale ..",".. 1.25 * scale + scale .."]".. head 

	for index,alternate  in pairs(moreblock) do
		formspec = 
			formspec .."item_image_button[".. (index - 1) * scale ..",".. 1.25 * scale ..";".. scale ..",".. scale ..";"..
			mod.. alternate[1] .. name .. alternate[2] ..
			";sculptool,".. mod.. alternate[1] .. name ..",c".. index ..",".. pos.x ..",".. pos.z ..",".. pos.y ..",".. player:get_player_name() ..",;]"
	end
	
	return formspec
	
end
--[[
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	--circular_saw.known_nodes["age_old:stone_aged_pillar"] = {"age_old", "stone_aged_pillar"}
	circular_saw.names
	
	minetest.chat_send_all("test ".. minetest.serialize(minetest.registered_items[newnode]))
	minetest.chat_send_all("test ".. minetest.serialize(itemstack:get_name()))
	if minetest.registered_nodes[newnode] then
		if (minetest.registered_nodes[newnode].groups["sculpt"] == 2 or 
			minetest.registered_nodes[newnode].groups["cut"] ) or
			circular_saw.known_nodes[newnode]
		then
			
			placer:get_inventory():remove_item("main", node)
			if placer:get_inventory():contains_item("main", node) then
				return true
			else
				itemstack:replace("sculptool:tool")
				return itemstack
			end
		end
	end
	--
end)


minetest.register_on_dignode(function(pos, oldnode, digger)

	if (minetest.registered_nodes[oldnode].groups["sculpt"] == 2 or 
		minetest.registered_nodes[oldnode].groups["cut"] )
	then
		return nil
	end

end)
--]]

minetest.register_on_punchnode(function(pos, node, player, pointed_thing)
		
		local nodehand = player:get_wielded_item():get_name()
		local player_tool = minetest.deserialize(player:get_attribute("sculptool"))
		
		
		if minetest.registered_nodes[nodehand] then
			if (minetest.registered_nodes[nodehand].groups["sculpt"] == 2 or 
				minetest.registered_nodes[nodehand].groups["cut"] ) and
				player:get_player_control().sneak and
				player_tool[nodehand]
			then
				player:set_wielded_item("sculptool:tool")
				player_tool[nodehand] = nil
				player:set_attribute("sculptool",minetest.serialize(player_tool))
			end
		end
end)

minetest.register_tool("sculptool:tool", {
	description = "Sculptool modify texture",
	inventory_image = "sculptool.png",
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
		
		if minetest.is_protected(pos, user:get_player_name()) then
			minetest.record_protection_violation(pos, user:get_player_name())
			return
		end
		
		local pos = pointed_thing.under
		local nodename = minetest.get_node(pos).name 
		
		if not(minetest.registered_nodes[nodename]) then
			return
		end
		
		if not ( minetest.registered_nodes[nodename].groups.sculpt == 2 or
			minetest.registered_nodes[nodename].groups.cut )
		then
			return
		end

		local nodebase = nodename
		local def_drop = minetest.registered_items[nodebase].drop
		
		if minetest.registered_items[nodebase].groups.cut then
			 nodebase = minetest.registered_items[nodebase].node_origin
			 def_drop = minetest.registered_items[nodename].drop
		end 
 
		if minetest.registered_items[nodebase].groups.sculpt == 2 then
			nodebase = minetest.registered_items[nodebase].node_origin_deco	
		end
			
		local player_tool = minetest.deserialize(user:get_attribute("sculptool"))
		
		minetest.chat_send_all(minetest.serialize(nodebase))
		minetest.chat_send_all(minetest.serialize(def_drop))
		
		
		if	(user:get_inventory():contains_item("main", nodebase) or
			user:get_inventory():contains_item("main", def_drop)) and
			player_tool[nodename] == nil
		then
			itemstack:replace(nodename)
			player_tool[nodename] = true
			user:set_attribute("sculptool", minetest.serialize(player_tool))			
			return itemstack

		end
		
	end,
	
	on_place = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
		
		local pos = pointed_thing.under
		local nodename = minetest.get_node(pos).name
		
		if not(minetest.registered_nodes[nodename]) then
			return
		end
		if minetest.is_protected(pos, user:get_player_name()) then
			minetest.record_protection_violation(pos, user:get_player_name())
			return
		end

		local nodef = minetest.registered_items[nodename]
		local scale = 1.5
			
		if nodef.groups.sculpt == 1 then
			local listnode = nodef.sculptool
			local window = math.ceil(math.sqrt(table.getn(listnode)+math.sqrt(table.getn(listnode))))  
			local maxx = scale * window
			local maxy = scale * window 
			local x = 0
			local y = 0
			local formspec =""
			
			for _, node in ipairs(listnode) do 
				
				
				if minetest.registered_nodes[node].groups["cuttable"] then 
					if x == maxx then
						x = 0
						y = y + scale
					end
					formspec = 
						formspec
						.."item_image_button[".. 0 + x ..",".. 0 + y.."; "
						..scale ..","..scale..";"
						..node..";sculptool,".. node ..",1,"..pos.x..","..pos.z..","..pos.y..",".. user:get_player_name() ..",;]"
					x = x + scale
				end
			end

			y = y + scale
			
			formspec = formspec..
			"item_image_button[".. maxx / 2 - scale / 2 ..",".. 0 + y..";"
			..scale ..","..scale..";"
			.. nodename..";sculptool,".. nodename ..",1,"..pos.x..","..pos.z..","..pos.y..",".. user:get_player_name() ..",;]"
			
			for _, node in ipairs(listnode) do 
				if not(minetest.registered_nodes[node].groups["cuttable"]) then 
					if x == maxx then
						x = 0
						y = y + scale
					end
					formspec = 
						formspec..
						"item_image_button[".. 0 + x ..",".. 0 + y.."; "
						..scale ..","..scale..";"
						.. node..";sculptool,".. node ..",1,"..pos.x..","..pos.z..","..pos.y..",".. user:get_player_name() ..",;]"
					x = x + scale
				end
			end
			
			y = y + scale
			
			formspec = "size["..maxx..","..y..";]".. formspec

			
			
			
			
			
			
			
			minetest.show_formspec(user:get_player_name(), "sculpt:choice", formspec)
		elseif nodef.groups.cuttable then
			
			local formspec = sculpt_formspec_cut(scale, pos, nodename, user)

			minetest.show_formspec(user:get_player_name(), "sculpt:cut", formspec)
		end
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local fields_string = minetest.serialize(fields)
		if not(string.find(fields_string, "sculptool,")) then
			return
		end

	local _, node, level, posx, posz, posy, player,_ = fields_string:match("(.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*)")
	local pos = {x=posx,z=posz,y=posy}
	local scale = 1.5
	local player = minetest.get_player_by_name(player)
	local mod, name = node:match("(.*):(.*)")
	local sculpt = minetest.registered_items[node].groups.sculpt
	local cut = minetest.registered_items[node].groups.cuttable
	
	--if mod == "default" then mod = "moreblocks" end
	
	if cut then
		local formspec = sculpt_formspec_cut(scale, pos, node, player )

		minetest.show_formspec(player:get_player_name(), "sculpt:cut", formspec)
	end

	
	if ( not(cut) and level == "1" ) or (sculpt == 2 and level == "c0" ) or level == "f" then
		minetest.close_formspec(player:get_player_name(), formname)

		local nodebase = node
		local def_drop = minetest.registered_nodes[node].drop
		
		
		if minetest.registered_items[nodebase].groups.cut then
			 nodebase = minetest.registered_items[nodebase].node_origin
		end 
 
		if minetest.registered_items[nodebase].groups.sculpt == 2 then
			nodebase = minetest.registered_items[nodebase].node_origin_deco
		end

		local player_tool = minetest.deserialize(player:get_attribute("sculptool"))
		
		minetest.swap_node(pos,{name = node})
		if minetest.registered_items[node].groups.cut and
			minetest.registered_items[nodebase].groups.cuttable
		then
			local cost = minetest.registered_nodes[node].moreblocks_cost
			local micro_node_origin = minetest.registered_nodes[nodebase].node_cut_by_moreblocks
			player:get_inventory():add_item("main", micro_node_origin[1] ..":micro_".. micro_node_origin[2] .." ".. 8 - cost)
		end
		
		
		if  player:get_inventory():contains_item("main", nodebase) or 
			player:get_inventory():contains_item("main",def_drop) and
			player_tool[node] == nil
		then
			player:set_wielded_item(node)
			player_tool[node] = true
			player:set_attribute("sculptool", minetest.serialize(player_tool))
		end
		
	end
	
	if string.find( level, "c") and 
		not( level == "c0" ) 
	then
		local moreblockname = {}
		local window = {}
		
		if level == "c1" or
			level == "c2" or
			level == "c3" 
		then
			
			window= {3,3}
	
			moreblockname = {
				["_1"] = {0,0},
				["_2"] = {1,0},
				[""] = {1,1},
				["_14"] = {1,2},
				["_15"] = {2,2},
			}
			
			if level == "c3" then
				moreblockname["_three_quarter"] = {0,2}
				moreblockname["_quarter"] =  {2,0}
			else
				moreblockname["_12"] = {0,2}
				moreblockname["_4"] = {2,0}
			end
		
		elseif level == "c4" then
			
			window= {4,3}
		
			moreblockname = {
				["_inner"] = {0,0},
				["_outer"] = {1,0},
				["_half"] = {3,0},
				[""] = {1.5,1},
				["_alt_1"] = {0,2},
				["_alt_2"] = {1,2},
				["_alt_4"] = {2,2},
				["_alt"] = {3,2},
			}
			
		elseif level == "c5" then
			window= {3,4}
		
			moreblockname = {
				["_half_raised"] = {0,0},
				[""] = {1,0},
				["_half"] = {2,0},
				["_inner_cut_half_raised"] = {0,1},
				["_inner_cut"] = {1,1},
				["_inner_cut_half"] = {2,1},
				["_outer_cut_half_raised"] = {0,2},
				["_outer_cut"] = {1,2},
				["_outer_cut_half"] = {2,2},
				["_cut"] = {1,3},
			}
			
		elseif level == "c6" then
			window= {3,2}
		
			moreblockname = {
				["_outer_half_raised"] = {0,0},
				["_outer"] = {1,0},
				["_outer_half"] = {2,0},
				["_inner_half_raised"] = {0,1},
				["_inner"] = {1,1},
				["_inner_half"] = {2,1},
			}
		
			
		elseif level == "c7" then
		
			local mod,name, _ = node:match("(.*)_(.*)_(.*)")
			
			window= {3,1}
		
			moreblockname = {
				["_three_sides_u"] = {0,0},
				["_three_sides"] = {1,0},
				["_two_sides"] = {2,0},
			}
			
				
		end
		local formspec = 
			"size[".. window[1] * scale ..",".. window[2] * scale .."]"
		
		for alternate,formspecpos  in pairs(moreblockname) do
			formspec = 
				formspec .."item_image_button[".. formspecpos[1] * scale ..",".. formspecpos[2] * scale ..";".. scale ..",".. scale ..";"..
				node .. alternate ..	
				";sculptool,".. node .. alternate ..",f,".. pos.x ..",".. pos.z ..",".. pos.y ..",".. player:get_player_name() ..",;]"
		end
		
		minetest.show_formspec(player:get_player_name(), "sculpt:ccut", formspec)
	end

end)

minetest.register_craft({
	output = "sculptool:tool",
	recipe = {
		{"group:stick"},
		{"default:diamond"},
		{"default:diamond"}
	}
})

mod_add ={
	"age_old",
	"default",
	"moreblocks",
}


local modpath = minetest.get_modpath("sculptool")

for _, name in ipairs(mod_add) do
	if minetest.get_modpath(name) then
		dofile(modpath .. "/sculpt_".. name ..".lua")
	end
end
