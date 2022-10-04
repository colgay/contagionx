#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <xs>

public plugin_init()
{
	register_clcmd("npc", "npc");
	register_clcmd("set_seq", "set_seq");
	register_clcmd("set_angle", "set_angle");
	register_think("npc_onna","npc_think");

	RegisterHam(Ham_TraceAttack, "info_target", "OnTraceAttack");
}

new cache_bloodspray, cache_blood;

public plugin_precache()
{
	cache_bloodspray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	cache_blood = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");
	precache_model("models/npc/Alien.mdl")
}

public set_seq(id)
{
	new npc_ent = find_ent_by_class(-1, "npc_onna");
	if (!pev_valid(npc_ent))	
		return PLUGIN_HANDLED;

	new arg[4];
	read_argv(1, arg, charsmax(arg));

	entity_set_float(npc_ent,EV_FL_animtime,get_gametime())
	entity_set_float(npc_ent,EV_FL_framerate,0.0)
	entity_set_int(npc_ent, EV_INT_sequence, str_to_num(arg));
	return PLUGIN_HANDLED;
}

public set_angle(id)
{
	new npc_ent = find_ent_by_class(-1, "npc_onna");
	if (!pev_valid(npc_ent))	
		return PLUGIN_HANDLED;

	new Float:pos[3], Float:npc_pos[3], Float:vec[3];
	entity_get_vector(id, EV_VEC_origin, pos);
	entity_get_vector(npc_ent, EV_VEC_origin, npc_pos);
	xs_vec_sub(pos, npc_pos, vec)
	xs_vec_normalize(vec, vec);
	vector_to_angle(vec, vec);
	vec[0] = 0.0;

	entity_set_vector(npc_ent, EV_VEC_angles, vec);

	return PLUGIN_HANDLED;
}

public npc(id)
{
	new Float:origin[3]
	entity_get_vector(id,EV_VEC_origin,origin)

	new ent = create_entity("info_target")

	entity_set_origin(ent,origin);
	origin[2] += 200.0
	entity_set_origin(id,origin)

	entity_set_float(ent,EV_FL_takedamage,DAMAGE_AIM)
	entity_set_float(ent,EV_FL_health,99999.0)

	entity_set_string(ent,EV_SZ_classname,"npc_onna");
	entity_set_model(ent,"models/npc/Alien.mdl");
	entity_set_int(ent,EV_INT_solid, SOLID_SLIDEBOX)
/*
	entity_set_byte(ent,EV_BYTE_controller1,125);
	entity_set_byte(ent,EV_BYTE_controller2,125);
	entity_set_byte(ent,EV_BYTE_controller3,125);
	entity_set_byte(ent,EV_BYTE_controller4,125);
*/
	new Float:mins[3] = {-64.0, -64.0, -36.0}
	new Float:maxs[3] = {64.0, 64.0, 164.0}
	entity_set_size(ent,mins,maxs)
	
	entity_set_float(ent,EV_FL_animtime,get_gametime())
	entity_set_float(ent,EV_FL_framerate,0.0)
	entity_set_int(ent,EV_INT_sequence,0);
	entity_set_int(ent, EV_INT_gamestate, 1);

	entity_set_vector(ent, EV_VEC_angles, Float:{0.0, 0.0, 0.0});

	entity_set_float(ent,EV_FL_nextthink,halflife_time() + 0.1)

	drop_to_floor(ent)
	console_print(id, "ent id = %d", ent);
	return 1;
}

public npc_think(ent)
{
	// Put your think stuff here.
	new Float:frame = entity_get_float(ent, EV_FL_frame);
	frame += 0.1;
	if (frame > 255)
		frame = 0.0;

	entity_set_float(ent, EV_FL_frame, frame);
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.01)
}

public OnTraceAttack(victim, attacker, Float:damage, Float:dir[3], ptr, damageType)
{
	if (!is_user_alive(attacker))
		return;
	
	new Float:end[3];
	get_tr2(ptr, TR_vecEndPos, end);
	create_blood(end);
}

stock create_blood(Float:end[3], num = 10)
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BLOODSPRITE);
    write_coord(floatround(end[0]));
    write_coord(floatround(end[1]));
    write_coord(floatround(end[2]));
    write_short(cache_bloodspray);
    write_short(cache_blood);
    write_byte(247);
    write_byte(num);
    message_end();
}