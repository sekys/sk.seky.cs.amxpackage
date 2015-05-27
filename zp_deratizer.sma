#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <csx>
#include <xs>
#include <zombieplague>

#define PLUGIN "[ZP] Deratizer kolo"
#define VERSION "1.0"
#define AUTHOR "Seky"

#define BODOV	10

new wpn_ft, sprite_fire, sprite_burn, sprite_xplo
new g_item_name[] = "Flamethrower"
new g_restarted, g_damage, g_xplode_dmg,
	g_damage_dis, g_splash_dis, g_ammo_packs_after_kill, g_frags_after_kill
new bool:g_hasFlamethrower[33], g_FireFlamethrower[33]
new g_msgDeathMsg, g_msgScoreInfo, bool:kolo

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_cvar("zp_extra_flamethrower", VERSION,FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)
	
	g_damage = register_cvar("zp_ft_damage", "50")
	g_xplode_dmg = register_cvar("zp_ft_xplode_dmg", "100")
	g_damage_dis = register_cvar("zp_ft_damage_dis", "120")
	g_splash_dis = register_cvar("zp_ft_splash_dis", "75")
	g_ammo_packs_after_kill = register_cvar("zp_ft_ammo_after_kill", "1")
	g_frags_after_kill = register_cvar("zp_ft_frags_after_kill", "1")
			
	register_event("DeathMsg", "Event_DeathMsg", "a")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_event("TextMsg", "Event_WeaponDrop", "be", "2=#Weapon_Cannot_Be_Dropped")
	
	//register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink")
	//register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	//register_forward( FM_PlayerPreThink, "fm_player_prethink" )
	
	register_think("flamethrower", "think_Flamethrower")
	g_msgDeathMsg 	= get_user_msgid("DeathMsg");
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	wpn_ft = custom_weapon_add("weapon_flamethrower", 0, "flamethrower")
}

public plugin_precache()
{
	precache_sound("flamethrower.wav")
	precache_sound("items/ammopickup2.wav")
	
	sprite_xplo = precache_model("sprites/zerogxplode.spr")
	sprite_fire = precache_model("sprites/explode1.spr")
	sprite_burn = precache_model("sprites/xfire.spr")
	
	precache_model("models/v_knife.mdl")
	precache_model("models/p_knife.mdl")
	precache_model("models/w_flamethrower.mdl")
	precache_model("models/v_flamethrower.mdl")
	precache_model("models/p_flamethrower.mdl")
}
public zp_round_started(gamemode, id) 
{	
	if(gamemode == MODE_DERATIZER){ 
		kolo = true
		nastav_zbran(id)
		client_print(id, print_chat, "[G/L ZP] Musis najst zombikov a vyhladit ich !")
	}
}
public zp_round_ended(winteam)
{
	if(kolo)
	{
		kolo = false
		if(winteam != WIN_HUMANS)
		{
			new Players[32], iNum = 0, id
			get_players(Players, iNum)
			for(new i = 0; i < iNum; i++) 
			{
				id = Players[i]
				if(zp_get_user_zombie(id))
				{
					zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + BODOV)
					client_print(id, print_chat, "[G/L ZP] Deratizer to tu nevycistil, ziskavas %d bodov !", BODOV)
					if(is_user_alive(id))
					{
						zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + BODOV)
						client_print(id, print_chat, "[G/L ZP] Za to ze si prezil ziskavas dalsich %d bodov !", BODOV)
					}
				}
			}
				
		} else {
			client_print(0, print_chat, "[G/L ZP] Zombikom sa nepodarilo skryt, nic neziskavaju.")	
		}		
	}	
}
stock nastav_zbran(id)
{		
	g_hasFlamethrower[id] = true		
	//client_print(0, print_chat, "zbran ma") // log
	set_flamethrower_model(id)
	client_cmd(id, "spk items/ammopickup2")
}
public Event_NewRound() 
{
	new Players[32], iNum = 0
	get_players(Players, iNum)
	for(new i = 0; i < iNum; i++) 
	{
		g_hasFlamethrower[Players[i]] = false
	}
}
public Event_WeaponDrop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	if(g_hasFlamethrower[id])
	{
		nastav_zbran(id)
	}
	return PLUGIN_HANDLED
}
public Event_DeathMsg() 
{ 
	new id = read_data(2)
	g_hasFlamethrower[id] = false
/*	client_cmd(id, "-duck");
	client_cmd(id, "say ");*/
	return PLUGIN_CONTINUE
}
public client_disconnect(id)
{
	g_hasFlamethrower[id] = false	
}	
public Event_CurWeapon(id)
{
	if(!is_user_alive(id) || !g_hasFlamethrower[id]) 
		return PLUGIN_CONTINUE
	
	//client_print(0, print_chat, "zbran") // log
	set_flamethrower_model(id)
	entity_set_int(id, EV_INT_weaponanim, 9)

	return PLUGIN_CONTINUE
}/*
public fw_UpdateClientData_Post(id, sendweapons, cd_handle) 
{
	if(!g_hasFlamethrower[id])
		return FMRES_IGNORED
		
	set_cd(cd_handle, CD_ID, 0)
	return FMRES_HANDLED
}
public fw_CmdStart(id, uc_handle, seed) 
{
	if(!g_hasFlamethrower[id])
		return FMRES_IGNORED
	
	new buttons = get_uc(uc_handle, UC_Buttons)
	if(buttons & IN_ATTACK)
	{
		g_FireFlamethrower[id] = 1
	
		buttons &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, buttons)
	} else 
		g_FireFlamethrower[id] = 0

}*/
public fw_PlayerPostThink(id)
{
	if(!g_hasFlamethrower[id])
		return FMRES_IGNORED	
	if(!is_user_connected(id) || !is_user_alive(id))
		return FMRES_IGNORED		
	if(entity_get_int(id, EV_INT_waterlevel) > 1)
		return FMRES_IGNORED
			
	//client_print(0, print_chat, "pre") // log
	//if(g_FireFlamethrower[id])
	if((pev(id, pev_button ) & IN_ATTACK) )
	{		
			new Float:fOrigin[3], Float:fVelocity[3]
			entity_get_vector(id,EV_VEC_origin, fOrigin)
			VelocityByAim(id, 35, fVelocity)
		
			new Float:fTemp[3], iFireOrigin[3]
			xs_vec_add(fOrigin, fVelocity, fTemp)
			FVecIVec(fTemp, iFireOrigin)
			
			new Float:fFireVelocity[3], iFireVelocity[3]
			VelocityByAim(id, get_pcvar_num(g_damage_dis), fFireVelocity)
			FVecIVec(fFireVelocity, iFireVelocity)
			
			create_flames_n_sounds(id, iFireOrigin, iFireVelocity)
			//client_print(0, print_chat, "striela") // log			
			direct_damage(id, 0)
			indirect_damage(id, 0)
			custom_weapon_shot(wpn_ft, id)

	}
	return PLUGIN_CONTINUE
}
public think_Flamethrower(ent)
{
	if(is_valid_ent(ent) && entity_get_float(ent, EV_FL_health) < 950.0) 
	{
		new Float:fOrigin[3], iOrigin[3]
		entity_get_vector(ent, EV_VEC_origin, fOrigin)
		FVecIVec(fOrigin, iOrigin)
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(99)
		write_short(ent)
		message_end()
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(3)
		write_coord(iOrigin[0])
		write_coord(iOrigin[1])
		write_coord(iOrigin[2])
		write_short(sprite_xplo)
		write_byte(50)
		write_byte(15)
		write_byte(0)
		message_end()
		//client_print(0, print_chat, "dmg") // log
		RadiusDamage(fOrigin, get_pcvar_num(g_xplode_dmg), entity_get_int(ent, EV_INT_iuser4))
		remove_entity(ent)
	}
	if(is_valid_ent(ent)) entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.01)
}
public create_flames_n_sounds(id, origin[3], velocity[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(120)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(velocity[0])
	write_coord(velocity[1])
	write_coord(velocity[2] + 5)
	write_short(sprite_fire)
	write_byte(1)
	write_byte(10)
	write_byte(1)
	write_byte(5)
	message_end()
	
	emit_sound(id, CHAN_WEAPON, "flamethrower.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
public direct_damage(id, doDamage)
{
	new ent, body
	get_user_aiming(id, ent, body, get_pcvar_num(g_damage_dis) + 500)
	
	if(ent > 0 && is_user_alive(ent))
	{
		damage_user(id, ent, get_pcvar_num(g_damage))
		custom_weapon_dmg(wpn_ft, id, ent, get_pcvar_num(g_damage))
	}
}

public indirect_damage(id, doDamage)
{
	new Players[32], iNum
	get_players(Players, iNum, "a")
	for(new i = 0; i < iNum; ++i) if(id != Players[i])
	{
		new target = Players[i]
	
		new Float:fOrigin[3], Float:fOrigin2[3]
		entity_get_vector(id,EV_VEC_origin, fOrigin)
		entity_get_vector(target, EV_VEC_origin, fOrigin2)
			
		new temp[3], Float:fAim[3]
		get_user_origin(id, temp, 3)
		IVecFVec(temp, fAim)
		
		new Float:fDistance = get_pcvar_num(g_damage_dis) + 500.0
		if(get_distance_f(fOrigin, fOrigin2) > fDistance)
			continue 
		
		new iDistance = get_distance_to_line(fOrigin, fOrigin2, fAim)
		if(iDistance > get_pcvar_num(g_splash_dis) || iDistance < 0 || !fm_is_ent_visible(id, target))
			continue 
			
		damage_user(id, target, get_pcvar_num(g_damage))
		custom_weapon_dmg(wpn_ft, id, target, get_pcvar_num(g_damage))
	}
}
public set_flamethrower_model(id)
{
	entity_set_string(id, EV_SZ_viewmodel, "models/v_flamethrower.mdl")
	entity_set_string(id, EV_SZ_weaponmodel, "models/p_flamethrower.mdl")
}
stock damage_user(id, victim, damage)
{
	new iHealth = get_user_health(victim)
	if(iHealth > damage) 
	{
		//fakedamage(victim, "weapon_flamethrower", float(damage), DMG_BURN)
		fm_set_user_health(victim, iHealth - damage)
	}
	else
	{
		set_msg_block(g_msgDeathMsg, BLOCK_ONCE)
		fm_set_user_health(victim, 0)
		make_deathmsg(id, victim, 0, "flamethrower")

		new iOrigin[3]
		get_user_origin(victim, iOrigin, 0)
		
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(17)
		write_coord(iOrigin[0])
		write_coord(iOrigin[1])
		write_coord(iOrigin[2] + 10)
		write_short(sprite_burn)
		write_byte(30)
		write_byte(40)
		message_end()
			
		fm_set_user_frags(id, get_user_frags(id) + get_pcvar_num(g_frags_after_kill))
		zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + get_pcvar_num(g_ammo_packs_after_kill))
	
		message_begin(MSG_ALL, g_msgScoreInfo) 
		write_byte(id) 
		write_short(get_user_frags(id)) 
		write_short(get_user_deaths(id)) 
		write_short(0) 
		write_short(get_user_team(id)) 
		message_end()
	}
}
stock fm_set_user_health(index, health)
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);
	return 1;
}
stock get_distance_to_line(Float:pos_start[3], Float:pos_end[3], Float:pos_object[3])  
{  
	new Float:vec_start_end[3], Float:vec_start_object[3], Float:vec_end_object[3], Float:vec_end_start[3]
	xs_vec_sub(pos_end, pos_start, vec_start_end) 		// vector from start to end 
	xs_vec_sub(pos_object, pos_start, vec_start_object) 	// vector from end to object 
	xs_vec_sub(pos_start, pos_end, vec_end_start) 		// vector from end to start 
	xs_vec_sub(pos_end, pos_object, vec_end_object) 		// vector object to end 
	
	new Float:len_start_object = getVecLen(vec_start_object) 
	new Float:angle_start = floatacos(xs_vec_dot(vec_start_end, vec_start_object) / (getVecLen(vec_start_end) * len_start_object), degrees)  
	new Float:angle_end = floatacos(xs_vec_dot(vec_end_start, vec_end_object) / (getVecLen(vec_end_start) * getVecLen(vec_end_object)), degrees)  

	if(angle_start <= 90.0 && angle_end <= 90.0) 
		return floatround(len_start_object * floatsin(angle_start, degrees)) 
	return -1  
}
stock Float:getVecLen(Float:Vec[3])
{ 
	new Float:VecNull[3] = {0.0, 0.0, 0.0}
	new Float:len = get_distance_f(Vec, VecNull)
	return len
}
stock bool:fm_is_ent_visible(index, entity) 
{
	new Float:origin[3], Float:view_ofs[3], Float:eyespos[3]
	pev(index, pev_origin, origin)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(origin, view_ofs, eyespos)

	new Float:entpos[3]
	pev(entity, pev_origin, entpos)
	engfunc(EngFunc_TraceLine, eyespos, entpos, 0, index)

	switch(pev(entity, pev_solid)) 
	{
		case SOLID_BBOX..SOLID_BSP: return global_get(glb_trace_ent) == entity
	}
	
	new Float:fraction
	global_get(glb_trace_fraction, fraction)
	if(fraction == 1.0)
		return true
		
	return false
}
stock fm_set_user_frags(index, frags) 
{
	set_pev(index, pev_frags, float(frags))

	return 1
}