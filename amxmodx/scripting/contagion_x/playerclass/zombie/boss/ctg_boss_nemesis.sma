#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <xs>
#include <ctg_util>

enum
{
	NEMESIS_TYPE_1,
	NEMESIS_TYPE_2,
};

new const SPR_TRAIL[] = "sprites/laserbeam.spr";
new const SPR_FIREBALL2[] = "sprites/eexplo.spr";
new const SPR_FIREBALL3[] = "sprites/fexplo.spr";
new const SPR_SMOKE[] = "sprites/steam1.spr";

new const SOUND_ROCKETFIRE[] = "weapons/rocketfire1.wav";
new const SOUND_ROCKETFLY[] = "weapons/rocket1.wav";
new const SOUND_EXPLODE[] = "weapons/c4_explode1.wav";

new const MODEL_ROCKET[] = "models/rpgrocket.mdl";

new CNemesis;
new CNemesisType[2];

new bool:g_IsRocketReloaded[MAX_PLAYERS + 1];
new Float:g_LastRocketFire[MAX_PLAYERS + 1] = {-999999.0, ...};

new Float:CvarSlashAttackRate, Float:CvarRpgReloadTime;

new Float:CvarRocketRadius, Float:CvarRocketMinDamage, Float:CvarRocketMaxDamage, Float:CvarRocketForce, 
	Float:CvarRocketMinForce, Float:CvarRocketForceZ, Float:CvarRocketForceMinZ;

new CvarRocketSpeed[2], Float:CvarMaxFollowDegree;

new g_SprTrail, g_SprFireball2, g_SprFireball3, g_SprSmoke;
new g_MdlGibs;

public plugin_precache()
{
	new CBoss = ctg_Boss();

	CNemesis = ctg_CreatePlayerClass(CBoss, "Nemesis", "nemesis", "");
	{
		CNemesisType[NEMESIS_TYPE_1] = ctg_CreatePlayerClass(CNemesis, "Nemesis Type-1", "nemesis1", "", Team_Zombie);
		CNemesisType[NEMESIS_TYPE_2] = ctg_CreatePlayerClass(CNemesis, "Nemesis Type-2", "nemesis2", "", Team_Zombie);
	}

	precache_sound(SOUND_ROCKETFIRE);
	precache_sound(SOUND_ROCKETFLY);
	precache_sound(SOUND_EXPLODE);
	precache_model(MODEL_ROCKET);

	g_SprTrail = precache_model(SPR_TRAIL);
	g_SprFireball2 = precache_model(SPR_FIREBALL2);
	g_SprFireball3 = precache_model(SPR_FIREBALL3);
	g_SprSmoke = precache_model(SPR_SMOKE);

	g_MdlGibs = precache_model("models/concretegibs.mdl");
}

public plugin_init()
{
	register_plugin("[CTG] Boss: Nemesis", CTG_VERSION, "colg");

	register_forward(FM_PlayerPreThink, "OnPlayerPreThink");
	register_forward(FM_CmdStart, "OnCmdStart");

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "OnKnifePrimaryAttack_P", 1, true);

	register_touch("rpgrocket", "*", "OnRocketTouch");
	register_think("rpgrocket", "OnRocketThink");

	ctg_CreatePlayerClassCvars(CNemesisType[NEMESIS_TYPE_1], "nemesis1", 2000, 0.95, 1.05, 0.4);
	ctg_CreatePlayerClassCvars(CNemesisType[NEMESIS_TYPE_2], "nemesis2", 2000, 0.7, 1.15, 0.55);

	new pcvar = create_cvar("ctg_nemesis1_slash_attack_rate", "0.5");
	bind_pcvar_float(pcvar, CvarSlashAttackRate);

	pcvar = create_cvar("ctg_nemesis_rpg_reload_time", "25.0");
	bind_pcvar_float(pcvar, CvarRpgReloadTime);

	pcvar = create_cvar("ctg_nemesis_rocket_min_damage", "25.0");
	bind_pcvar_float(pcvar, CvarRocketMinDamage);

	pcvar = create_cvar("ctg_nemesis_rocket_max_damage", "150.0");
	bind_pcvar_float(pcvar, CvarRocketMaxDamage);

	pcvar = create_cvar("ctg_nemesis_rocket_radius", "250.0");
	bind_pcvar_float(pcvar, CvarRocketRadius);

	pcvar = create_cvar("ctg_nemesis_rocket_force", "400.0");
	bind_pcvar_float(pcvar, CvarRocketForce);

	pcvar = create_cvar("ctg_nemesis_rocket_min_force", "100.0");
	bind_pcvar_float(pcvar, CvarRocketMinForce);

	pcvar = create_cvar("ctg_nemesis_rocket_force_z", "150.0");
	bind_pcvar_float(pcvar, CvarRocketForceZ);

	pcvar = create_cvar("ctg_nemesis_rocket_force_min_z", "50.0");
	bind_pcvar_float(pcvar, CvarRocketForceMinZ);

	pcvar = create_cvar("ctg_nemesis_rocket_speed1", "1250");
	bind_pcvar_num(pcvar, CvarRocketSpeed[0]);

	pcvar = create_cvar("ctg_nemesis_rocket_speed2", "750");
	bind_pcvar_num(pcvar, CvarRocketSpeed[1]);

	pcvar = create_cvar("ctg_nemesis_rocket_max_follow_degree", "10");
	bind_pcvar_float(pcvar, CvarMaxFollowDegree);
}

public OnPlayerPreThink(id)
{
	if (!is_user_alive(id))
		return;
	
	if (ctg_GetPlayerClassId(id) == CNemesisType[NEMESIS_TYPE_1])
	{
		if (!g_IsRocketReloaded[id])
		{
			if (get_gametime() >= g_LastRocketFire[id] + CvarRpgReloadTime)
			{
				set_dhudmessage(255, 0, 0, -1.0, 0.3, 0, 0.0, 3.0, 1.0, 1.0);
				show_dhudmessage(0, "Nemesis' RPG reloaded!");
				g_IsRocketReloaded[id] = true;
			}
		}
	}
}

public OnCmdStart(id, uc)
{
	if (!is_user_alive(id))
		return;
	
	if (ctg_GetPlayerClassId(id) == CNemesisType[NEMESIS_TYPE_1])
	{
		if (g_IsRocketReloaded[id])
		{
			new button = get_uc(uc, UC_Buttons);
			if ((button & IN_USE) && (~entity_get_int(id, EV_INT_oldbuttons) & IN_USE))
			{
				RocketLaunch(id, 0);
			}
			else if ((button & IN_RELOAD) && (~entity_get_int(id, EV_INT_oldbuttons) & IN_RELOAD))
			{
				RocketLaunch(id, 1);
			}
		}
	}
}

public OnKnifePrimaryAttack_P(ent)
{
	if (!is_valid_ent(ent))
		return;
	
	new id = get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");

	if (is_user_alive(id) && ctg_GetPlayerClassId(id) == CNemesisType[NEMESIS_TYPE_1])
	{
		set_ent_data_float(ent, "CBasePlayerWeapon", "m_flNextPrimaryAttack", CvarSlashAttackRate);
		set_ent_data_float(ent, "CBasePlayerWeapon", "m_flNextSecondaryAttack", CvarSlashAttackRate);
		set_ent_data_float(ent, "CBasePlayerWeapon", "m_flTimeWeaponIdle", CvarSlashAttackRate);
	}
}

public OnRocketThink(rocket)
{
	if (!is_valid_ent(rocket))
		return;
	
	new mode = entity_get_int(rocket, EV_INT_iuser1);

	if (~entity_get_int(rocket, EV_INT_effects) & EF_LIGHT)
	{
		// Make trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(rocket); // entity
		write_short(g_SprTrail); // sprite
		write_byte(10); // life
		write_byte(5); // width
		write_byte(100); // r
		write_byte(100); // g
		write_byte(100); // b
		write_byte(200); // brightness
		message_end();

		entity_set_int(rocket, EV_INT_effects, entity_get_int(rocket, EV_INT_effects) | EF_LIGHT);

		new Float:origin[3], Float:vec[3], Float:end[3];
		entity_get_vector(rocket, EV_VEC_origin, origin);
		entity_get_vector(rocket, EV_VEC_velocity, vec);

		new Float:speed = xs_vec_len(vec);
		xs_vec_normalize(vec, vec);
		xs_vec_mul_scalar(vec, speed * 0.25, end);
		xs_vec_add(origin, end, end);

		engfunc(EngFunc_TraceLine, origin, end, DONT_IGNORE_MONSTERS, rocket, 0);

		xs_vec_mul_scalar(vec, float(CvarRocketSpeed[mode]), vec);
		entity_set_vector(rocket, EV_VEC_velocity, vec);
		
		new Float:f;
		get_tr2(0, TR_flFraction, f);

		if (f == 1.0) // prevent sound loop
			emit_sound(rocket, CHAN_VOICE, SOUND_ROCKETFLY, 1.0, 0.5, 0, 100);

		entity_set_float(rocket, EV_FL_nextthink, get_gametime() + 0.1);
	}
	else
	{
		if (get_gametime() >= entity_get_float(rocket, EV_FL_fuser1) + 10.0)
		{
			OnRocketTouch(rocket, 0);
			return;
		}

		if (mode == 1)
		{
			new owner = entity_get_edict2(rocket, EV_ENT_owner);
			if (owner != -1)
			{
				// rocket follows player aim (crazy maths calculations)
				new Float:startpos[3];
				entity_get_vector(rocket, EV_VEC_origin, startpos);

				new Float:vec[3], Float:endpos[3];
				ExecuteHam(Ham_EyePosition, owner, endpos);
				entity_get_vector(owner, EV_VEC_v_angle, vec);
				angle_vector(vec, ANGLEVECTOR_FORWARD, vec);
				xs_vec_mul_scalar(vec, 4096.0, vec);
				xs_vec_add(endpos, vec, endpos);

				engfunc(EngFunc_TraceLine, startpos, endpos, DONT_IGNORE_MONSTERS, rocket, 0);
				get_tr2(0, TR_vecEndPos, endpos);

				new Float:old_vel[3];
				new Float:a[3], Float:b[3], Float:g[3];
				entity_get_vector(rocket, EV_VEC_velocity, old_vel);
				xs_vec_normalize(old_vel, a);

				xs_vec_sub(endpos, startpos, b);
				xs_vec_normalize(b, b);

				new Float:c[3], Float:f[3];
				xs_vec_cross(a, b, c);
				xs_vec_normalize(c, c);
				xs_vec_cross(c, a, f);
				
				new Float:theta = floatmin(xs_acos(xs_vec_dot(a, b) / (xs_vec_len(a) * xs_vec_len(b)), radian) * (180.0 / M_PI), CvarMaxFollowDegree);
				g[0] = xs_cos(theta, degrees) * a[0] + xs_sin(theta, degrees) * f[0];
				g[1] = xs_cos(theta, degrees) * a[1] + xs_sin(theta, degrees) * f[1];
				g[2] = xs_cos(theta, degrees) * a[2] + xs_sin(theta, degrees) * f[2];

				new Float:angle[3];
				vector_to_angle(g, angle);
				entity_set_vector(rocket, EV_VEC_angles, angle);

				new Float:vel[3];
				xs_vec_mul_scalar(g, float(CvarRocketSpeed[mode]), vel);

				if (xs_vec_len(vel) < 10.0)
					vel = old_vel;

				entity_set_vector(rocket, EV_VEC_velocity, vel);
			}
		}
		entity_set_float(rocket, EV_FL_nextthink, get_gametime() + 0.1);
	}
}

public OnRocketTouch(rocket, toucher)
{
	if (!is_valid_ent(rocket))
		return;
	
	CreateExplosionEffect(rocket);

	new attacker = entity_get_edict2(rocket, EV_ENT_owner);

	new Float:origin[3];
	entity_get_vector(rocket, EV_VEC_origin, origin);

	new ent = FM_NULLENT;
	new Float:vec[3], Float:vel[3];
	new Float:radius, Float:ratio, Float:damage, Float:z;
	new damagebits;

	while ((ent = find_ent_in_sphere(ent, origin, CvarRocketRadius)) != 0)
	{
		if (!is_valid_ent(ent))
			continue;
		
		if (!is_user_alive(ent) || ctg_IsZombie(ent))
			continue;
		
		if (entity_get_float(ent, EV_FL_takedamage) == DAMAGE_NO)
			continue;

		radius = entity_range(rocket, ent);
		ratio  = (1.0 - radius / CvarRocketRadius);
		damage = floatmax(ratio * CvarRocketMaxDamage, CvarRocketMinDamage);
		damagebits = DMG_GRENADE;

		if (ent == toucher)
			damage = CvarRocketMaxDamage;
		
		if (ratio >= 0.75)
			damagebits |= DMG_ALWAYSGIB;

		ExecuteHamB(Ham_TakeDamage, ent, rocket, attacker, damage, damagebits);

		if (is_user_alive(ent))
		{
			entity_get_vector(ent, EV_VEC_velocity, vel);
			entity_get_vector(ent, EV_VEC_origin, vec);

			xs_vec_sub(vec, origin, vec);
			xs_vec_normalize(vec, vec);
			xs_vec_mul_scalar(vec, floatmax(CvarRocketForce * ratio, CvarRocketMinForce), vec);

			z = floatmax(CvarRocketForceZ * ratio, CvarRocketForceMinZ);

			if (vec[2] < z)
				vec[2] = z;

			xs_vec_add(vel, vec, vel);

			entity_set_vector(ent, EV_VEC_velocity, vel);
		}
	}

	if (entity_get_int(rocket, EV_INT_effects) & EF_LIGHT)
		emit_sound(rocket, CHAN_VOICE, SOUND_ROCKETFLY, 0.0, 0.0, SND_STOP, 100);

	remove_entity(rocket);
}

public client_disconnected(id)
{
	g_IsRocketReloaded[id] = false;
	g_LastRocketFire[id] = -999999.0;
}

RocketLaunch(id, mode)
{
	new ent = create_entity("info_target");

	emit_sound(id, CHAN_WEAPON, SOUND_ROCKETFIRE, 1.0, ATTN_NORM, 0, PITCH_NORM);

	entity_set_model(ent, MODEL_ROCKET);
	entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});

	entity_set_string(ent, EV_SZ_classname, "rpgrocket");
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_edict(ent, EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX);

	new Float:vector[3], Float:vector2[3];
	entity_get_vector(id, EV_VEC_origin, vector);
	entity_get_vector(id, EV_VEC_view_ofs, vector2);
	xs_vec_add(vector, vector2, vector);
	
	entity_set_origin(ent, vector);

	entity_get_vector(id, EV_VEC_v_angle, vector);
	entity_set_vector(ent, EV_VEC_angles, vector);

	velocity_by_aim(id, floatround(CvarRocketSpeed[mode] * 0.6), vector);
	entity_set_vector(ent, EV_VEC_velocity, vector);

	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.3);
	entity_set_float(ent, EV_FL_fuser1, get_gametime());
	entity_set_int(ent, EV_INT_iuser1, mode);

	g_IsRocketReloaded[id] = false;
	g_LastRocketFire[id] = get_gametime();
}


stock CreateExplosionEffect(rocket)
{
	new Float:origin[3];
	entity_get_vector(rocket, EV_VEC_origin, origin);

	emit_sound(rocket, CHAN_WEAPON, SOUND_EXPLODE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
	write_byte(TE_EXPLOSION);	// This makes a dynamic light and the explosion sprites/sound
	write_coord_f(origin[0]);		// Send to PAS because of the sound
	write_coord_f(origin[1]);
	write_coord_f(origin[2] + 20.0);
	write_short(g_SprFireball3);
	write_byte(25);			// scale * 10
	write_byte(30);		// framerate
	write_byte(TE_EXPLFLAG_NONE);	// flags
	message_end();

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
	write_byte(TE_EXPLOSION);	// This makes a dynamic light and the explosion sprites/sound
	write_coord_f(origin[0] + random_float(-64.0, 64.0));	// Send to PAS because of the sound
	write_coord_f(origin[1] + random_float(-64.0, 64.0));
	write_coord_f(origin[2] + random_float(30.0, 35.0));
	write_short(g_SprFireball2);
	write_byte(30);			// scale * 10
	write_byte(30);		// framerate
	write_byte(TE_EXPLFLAG_NOSOUND);	// flags
	message_end();

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
	write_byte(TE_BREAKMODEL)
	write_coord_f(origin[0]); // position
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_coord(8); // size
	write_coord(8);
	write_coord(8);
	write_coord(random_num(-100, 100)); // velocity
	write_coord(random_num(-100, 100));
	write_coord(50);
	write_byte(25); // random velocity
	write_short(g_MdlGibs);
	write_byte(random_num(8, 12));
	write_byte(75);
	write_byte(0x08);
	message_end();

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_byte(random_num(46, 48));
	message_end();

	new Float:normal[3];
	normal = origin;
	normal[2] -= 40.0;

	engfunc(EngFunc_TraceLine, origin, normal, IGNORE_MONSTERS, rocket, 0);
	get_tr2(0, TR_vecPlaneNormal, normal);

	new num = random_num(1, 3);
	for (new i = 0; i < num; i++)
	{
		new ent = create_entity("spark_shower");
		if (!ent) continue;
		
		entity_set_origin(ent, origin);
		entity_set_vector(ent, EV_VEC_angles, normal);
		DispatchSpawn(ent);
	}

	new param[3];
	FVecIVec(origin, param);

	set_task(0.75, "ShowSmoke", 999, param, sizeof(param));
}

public ShowSmoke(param[], taskid)
{
	new origin[3];
	origin[0] = param[0];
	origin[1] = param[1];
	origin[2] = param[2] + 5;

	message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_SMOKE);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_short(g_SprSmoke);
	write_byte(35 + random_num(0, 10)); // scale * 10
	write_byte(5); // framerate
	message_end();
}