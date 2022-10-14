
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

new g_SprTrail;
new const g_SoundSpitHit[][] = {"bullchicken/bc_spithit1.wav", "bullchicken/bc_spithit2.wav"};

public plugin_precache()
{
	g_SprTrail = precache_model("sprites/laserbeam.spr");
	precache_model("sprites/ef_angrapoison.spr");

	precache_sound("bullchicken/bc_acid1.wav");

	for (new i = 0; i < sizeof g_SoundSpitHit; i++)
		precache_sound(g_SoundSpitHit[i]);
}

public plugin_init()
{
	register_plugin("Poison Smoke", "0.1", "Holla");

	register_think("poison", "PoisonThink");
	register_touch("poison", "*", "PoisonTouch");

	register_clcmd("psmoke", "CmdSmoke");
	register_clcmd("pangle", "CmdAngle");
	register_clcmd("plight", "CmdLight");
}

public CmdAngle(id)
{
	new Float:angle[3];
	new ent = -1;
	while ((ent = find_ent_by_class(ent, "env_sprite")))
	{
		entity_get_vector(ent, EV_VEC_angles, angle);
		angle[2] += 45.0;
		entity_set_vector(ent, EV_VEC_angles, angle);
	}
}

public CmdSmoke(id)
{
	new Float:origin[3];
	ExecuteHam(Ham_EyePosition, id, origin);

	new ent = create_entity("info_target");

	entity_set_origin(ent, origin);
	entity_set_model(ent, "sprites/ef_angrapoison.spr");
	entity_set_size(ent, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0});
	entity_set_string(ent, EV_SZ_classname, "poison");
	entity_set_float(ent, EV_FL_scale, 0.1);
	entity_set_int(ent, EV_INT_iuser1, random_num(0, 1));
	set_ent_rendering(ent, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255);
	entity_set_edict(ent, EV_ENT_owner, id);
	//DispatchSpawn(ent);

	entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS);

	new Float:velocity[3];
	velocity_by_aim(id, 1500, velocity);

	velocity[0] += random_float(-50.0, 50.0);
	velocity[1] += random_float(-50.0, 50.0);
	velocity[2] += random_float(-50.0, 50.0);

	entity_set_vector(ent, EV_VEC_velocity, velocity);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id
	write_short(ent) // entity
	write_short(g_SprTrail) // sprite
	write_byte(10) // life
	write_byte(5) // width
	write_byte(0) // r
	write_byte(255) // g
	write_byte(0) // b
	write_byte(200) // brightness
	message_end()

	emit_sound(ent, CHAN_WEAPON, g_SoundSpitHit[random(sizeof g_SoundSpitHit)], VOL_NORM, ATTN_NORM, 0, random_num(90, 110));

	entity_set_float(ent, EV_FL_nextthink, get_gametime());

	return PLUGIN_HANDLED;
}

public CmdLight(id)
{
	new arg[32];
	read_argv(1, arg, charsmax(arg));

	set_lights(arg);
}

public PoisonThink(ent)
{
	if (!is_valid_ent(ent))
		return;

	if (entity_get_float(ent, EV_FL_renderamt) <= 0.0)
	{
		client_print(0, print_chat, "remove");
		remove_entity(ent);
		return;
	}

	new Float:currtime = get_gametime();

	new Float:angle[3];
	entity_get_vector(ent, EV_VEC_angles, angle);
	if (entity_get_int(ent, EV_INT_iuser1))
		angle[2] += 1.0;
	else
		angle[2] -= 1.0;
	
	entity_set_vector(ent, EV_VEC_angles, angle);

	new Float:frame = entity_get_float(ent, EV_FL_frame);
	entity_set_float(ent, EV_FL_frame, frame >= 21.0 ? 0.0 : frame + 1);

	if (entity_get_int(ent, EV_INT_movetype) == MOVETYPE_NONE)
	{
		new Float:scale = entity_get_float(ent, EV_FL_scale) + 0.05;
		entity_set_float(ent, EV_FL_scale, scale > 1.0 ? 1.0 : scale);

		new Float:touchtime = entity_get_float(ent, EV_FL_fuser1);
		if (currtime >= touchtime + 1.0)
		{
			new Float:starttime = touchtime + 1.0;
			entity_set_float(ent, EV_FL_renderamt, floatmax((1.0 - (currtime - starttime) / 1.0) * 255.0, 0.0));
		}
	}

	entity_set_float(ent, EV_FL_nextthink, currtime + 0.05);
}

public PoisonTouch(ent, toucher)
{
	client_print(0, print_chat, "touch");

	if (entity_get_int(ent, EV_INT_movetype) != MOVETYPE_NONE)
	{
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
		entity_set_int(ent, EV_INT_solid, SOLID_NOT);
		entity_set_float(ent, EV_FL_fuser1, get_gametime());

		emit_sound(ent, CHAN_VOICE, "bullchicken/bc_acid1.wav", VOL_NORM, ATTN_NORM, 0, random_num(90, 110));
		emit_sound(ent, CHAN_WEAPON, g_SoundSpitHit[random(sizeof g_SoundSpitHit)], VOL_NORM, ATTN_NORM, 0, random_num(90, 110));

		new Float:origin[3], Float:end[3];
		entity_get_vector(ent, EV_VEC_origin, origin);
		entity_get_vector(ent, EV_VEC_velocity, end);
		xs_vec_normalize(end, end);
		xs_vec_mul_scalar(end, 128.0, end);
		xs_vec_add(origin, end, end);
		engfunc(EngFunc_TraceLine, origin, end, IGNORE_MONSTERS, ent, 0);
		get_tr2(0, TR_vecEndPos, end);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_WORLDDECAL);
		engfunc(EngFunc_WriteCoord, end[0]);
		engfunc(EngFunc_WriteCoord, end[1]);
		engfunc(EngFunc_WriteCoord, end[2]);
		write_byte(random_num(7, 8));
		message_end();
	}
}