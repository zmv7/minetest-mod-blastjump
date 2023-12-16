local default_power = minetest.settings:get("blastjump.default_power") or 10

local function frnd(min, max)
	return (max-min)*math.random() + min
end

minetest.register_tool("blastjump:blaster",{
	description = "Blastjumping blaster",
	inventory_image = "blastjump_blaster.png",
	on_use = function(itemstack, user, pointed_thing)
		if not minetest.check_player_privs(user, {blastjumping=true}) then
			itemstack:take_item()
			return itemstack
		end
		local meta = itemstack:get_meta()
		local power = tonumber(meta:get("count_meta")) or default_power
		local props = user:get_properties()
		local pos = user:get_pos()
		local dir = user:get_look_dir()
		if pos and props and dir then
			pos.y = pos.y + props.eye_height
			local obj = minetest.add_entity(pos, "blastjump:blast", power)
			if obj then
				obj:set_velocity({x = dir.x * 60, y = dir.y * 60, z = dir.z * 60})
			end
			minetest.sound_play("lasergun_fire", {pos = pos, gain = 0.5})
		end
	end
})
minetest.register_entity("blastjump:blast",{
	physical = true,
	collide_with_object = false,
	visual = "sprite",
	collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
	visual_size = {x = 0.2, y = 0.2, z = 0.2},
	pointable = false,
	glow = 14,
	use_texture_alpha = true,
	textures = {"blastjump_blast.png"},
	on_activate = function(self, staticdata)
		self.power = tonumber(staticdata) or default_power
	end,
	on_step = function(self, dtime, moveresult)
		local power = self.power or default_power
		if moveresult.collides then
			local pos = self.object:get_pos()
			local objs = minetest.get_objects_inside_radius(pos, math.abs(power)/5)
			for _,obj in ipairs(objs) do
				if obj:is_player() then
					local ppos = obj:get_pos()
					local dist = vector.distance(pos,ppos)
					local dir = vector.direction(pos,ppos)
					local push = power-dist*5
					if not minetest.check_player_privs(obj, {blastjump_op=true}) then
						local hp = obj:get_hp()
						obj:set_hp(hp-push/10)
					end
					obj:add_velocity({x = dir.x * push, y = dir.y * push, z = dir.z * push})
				end
			end
			for i=1,100 do
				minetest.add_particle({
					pos = pos,
					velocity = {x = frnd(-3,3), y = frnd(-3,3), z = frnd(-3,3)},
					expirationtime = frnd(0.1, 0.3),
					collisiondetection = true,
					collision_removal = true,
					size = 0.5,
					vertical = false,
					texture = "blastjump_blast.png",
					glow = 14
				})
			end
			self.object:remove()
		end
	end,
})
minetest.register_chatcommand("blastjump-power",{
  description = "Change power of wileded blastjumping blaster",
  privs = {blastjump_op=true},
  params = "[number]",
  func = function(name, param)
	local player = minetest.get_player_by_name(name)
	if not player then
		return false, "No player"
	end
	local witem = player:get_wielded_item()
	if not witem or witem:get_name() ~= "blastjump:blaster" then
		return false, "You must hold blastjump blaster in your hand!"
	end
	local power = tonumber(param) or default_power
	if power > 255 or power < -255 then
		return false, "Out of range (-255 - 255)"
	end
	local meta = witem:get_meta()
	meta:set_int("count_meta", power)
	player:set_wielded_item(witem)
	return true, "Blastjumping blaster's power has been set to "..power
end})
minetest.register_privilege("blastjumping",{description = "Can use blastjumping blaster", give_to_singleplayer = false})
minetest.register_privilege("blastjump_op",{description = "Can change power of blastjumping blaster", give_to_singleplayer = false})
