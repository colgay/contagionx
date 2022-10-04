#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <xs>
#include <ctg_core>

const EV_NADE_TYPE = EV_INT_flTimeStepSound;
const NADE_TYPE_FIRE = 2222;

new const SPR_TRAIL[] = "sprites/laserbeam.spr";
new const SPR_WAVE[] = "sprites/shockwave.spr";
new const SPR_FLAME[] = "sprites/flame.spr";
new const SPR_SMOKE[] = "sprites/steam1.spr";
new const SPR_EXPLO[] = "sprites/explode1.spr";

new const SOUND_FLAMEBURST[] = "ambience/flameburst1.wav";
new const SOUND_EXPLO[] = "debris/bustglass2.wav";
new const SOUND_BURN[] = "ambience/burning1.wav";

new Float:CvarRadius, CvarDuration, CvarMaxDuration, Float:CvarDamage, Float:CvarUpdateTime;

new g_SprTrail, g_SprWave, g_SprFlame, g_SprSmoke, g_SprExplo;

new bool:g_IsOnFire[MAX_PLAYERS + 1];
new g_BurnDuration[MAX_PLAYERS + 1];
new Float:g_BurnStartTime[MAX_PLAYERS + 1];
new Float:g_NextHurtTime[MAX_PLAYERS + 1];
new g_BurnAttacker[MAX_PLAYERS + 1];

public plugin_precache()
{
	g_SprTrail = precache_model(SPR_TRAIL);
	g_SprWave = precache_model(SPR_WAVE);
	g_SprFlame = precache_model(SPR_FLAME);
	g_SprSmoke = precache_model(SPR_SMOKE);
	g_SprExplo = precache_model(SPR_EXPLO);

	precache_sound(SOUND_FLAMEBURST);
	precache_sound(SOUND_EXPLO);
	precache_sound(SOUND_BURN);
}

public plugin_init()
{
	register_plugin("[CTG] Grenade: Fire", CTG_VERSION, "colg");

	register_forward(FM_PlayerPreThink, "OnPlayerPreThink");

	register_forward(FM_ClientDisconnect, "OnClientDisconnect");

	register_forward(FM_SetModel, "OnSetModel");
	RegisterHam(Ham_Think, "grenade", "OnThinkGrenade");

	RegisterHam(Ham_Killed, "player", "OnPlayerSpawn_P", 1, true);
	RegisterHam(Ham_Killed, "player", "OnPlayerKilled", 0, true);

	new pcvar = create_cvar("ctg_grenade_fire_radius", "240");
	bind_pcvar_float(pcvar, CvarRadius);

	pcvar = create_cvar("ctg_grenade_fire_duration", "20");
	bind_pcvar_num(pcvar, CvarDuration);

	pcvar = create_cvar("ctg_grenade_fire_max_duration", "120");
	bind_pcvar_num(pcvar, CvarMaxDuration);

	pcvar = create_cvar("ctg_grenade_fire_damage", "1.0");
	bind_pcvar_float(pcvar, CvarDamage);

	pcvar = create_cvar("ctg_grenade_fire_update_time", "0.25");
	bind_pcvar_float(pcvar, CvarUpdateTime);
}

public OnSetModel(entity, const model[])
{
	if (strlen(model) < 8)
		return;
	
	if (model[7] != 'w' || model[8] != '_')
		return;
	
	// Grenade not yet thrown
	if (entity_get_float(entity, EV_FL_dmgtime) == 0.0)
		return;
	
	if (ctg_IsZombie(entity_get_edict(entity, EV_ENT_owner)))
		return;
	
	// HE Grenade
	if (model[9] == 'h' && model[10] == 'e')
	{
		// Give it a glow
		set_ent_rendering(entity, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 16);
		
		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW); // TE id
		write_short(entity); // entity
		write_short(g_SprTrail); // sprite
		write_byte(10); // life
		write_byte(10); // width
		write_byte(200); // r
		write_byte(50); // g
		write_byte(0); // b
		write_byte(200); // brightness
		message_end();
		
		entity_set_int(entity, EV_INT_iuser1, 0);
		entity_set_int(entity, EV_NADE_TYPE, NADE_TYPE_FIRE);
	}
}

public OnThinkGrenade(entity)
{
	if (!is_valid_ent(entity))
		return HAM_IGNORED;
	
	// Check if it's time to go off
	if (entity_get_float(entity, EV_FL_dmgtime) > get_gametime())
		return HAM_IGNORED;
	
	if (entity_get_int(entity, EV_NADE_TYPE) != NADE_TYPE_FIRE)
		return HAM_IGNORED;

	FireExplode(entity);
	return HAM_SUPERCEDE;
}

public OnPlayerPreThink(id)
{
	if (!is_user_alive(id))
		return;
	
	// Player is on fire
	if (g_IsOnFire[id])
	{
		new Float:origin[3];
		entity_get_vector(id, EV_VEC_origin, origin);

		// If player in water or burn time is end
		new flags = entity_get_int(id, EV_INT_flags);
		if ((flags & FL_INWATER) || g_BurnDuration[id] < 1)
		{
			SetPlayerOffFire(id, true);
			return;
		}

		// Don't update too fast
		if (get_gametime() >= g_NextHurtTime[id])
		{
			// Flame sprite
			message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
			write_byte(TE_SPRITE); // TE id
			write_coord_f(origin[0]+random_num(-5, 5)); // x
			write_coord_f(origin[1]+random_num(-5, 5)); // y
			write_coord_f(origin[2]+random_num(-10, 10)); // z
			write_short(g_SprFlame); // sprite
			write_byte(random_num(3, 5)); // scale
			write_byte(200); // brightness
			message_end();

			new Float:health = entity_get_float(id, EV_FL_health);
			if (health - CvarDamage > 0)
				entity_set_float(id, EV_FL_health, health - CvarDamage);
			else
				ExecuteHamB(Ham_Killed, id, is_user_connected(g_BurnAttacker[id]) ? g_BurnAttacker[id] : id, 1);

			g_NextHurtTime[id] = get_gametime() + CvarUpdateTime; // record the last hurt time
			g_BurnDuration[id] --;
		}
	}
}

public OnPlayerSpawn_P(id)
{
	if (is_user_alive(id))
	{
		SetPlayerOffFire(id, false);
	}
}

public OnPlayerKilled(id)
{
	SetPlayerOffFire(id, true);
}

public OnClientDisconnect(id)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_BurnAttacker[i] == id)
			g_BurnAttacker[id] = id;
	}

	SetPlayerOffFire(id, false);
}

public ctg_OnChangePlayerClass_P(id, class_id)
{
	if (!ctg_IsZombie(id))
		SetPlayerOffFire(id, true);
}

FireExplode(ent)
{
	new Float:origin[3];
	entity_get_vector(ent, EV_VEC_origin, origin);

	new count = entity_get_int(ent, EV_INT_iuser1);
	entity_set_int(ent, EV_INT_iuser1, ++count);

	if (count == 1)
	{
		emit_sound(ent, CHAN_BODY, SOUND_EXPLO, VOL_NORM, ATTN_NORM, 0, PITCH_NORM + random_num(-5, 5));

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_WORLDDECAL);
		write_coord_f(origin[0]);
		write_coord_f(origin[1]);
		write_coord_f(origin[2]);
		write_byte(random_num(46, 48));
		message_end();

		entity_set_float(ent, EV_FL_fuser1, get_gametime());
		entity_set_int(ent, EV_INT_effects, entity_get_int(ent, EV_INT_effects) | EF_NODRAW);
	}

	emit_sound(ent, CHAN_WEAPON, SOUND_FLAMEBURST, VOL_NORM, ATTN_NORM, 0, PITCH_NORM + random_num(-5, 5));
	CreateBlast(ent, origin);
	RadiusBurn(ent);

	if (count >= 3)
	{
		client_print(0, print_chat, "removed grenade entity");
		remove_entity(ent);
		return;
	}

	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 1.0);
}

RadiusBurn(ent)
{
	new Float:origin[3];
	entity_get_vector(ent, EV_VEC_origin, origin);

	new owner = entity_get_edict(ent, EV_ENT_owner);
	new victim = FM_NULLENT;

	while ((victim = find_ent_in_sphere(victim, origin, CvarRadius)) != 0)
	{
		if (!is_user_alive(victim) || !ctg_IsZombie(victim))
			continue;
		
		SetPlayerOnFire(victim, owner);
	}
}

SetPlayerOnFire(id, attacker)
{
	static msgDamage;
	msgDamage || (msgDamage = get_user_msgid("Damage"));

	message_begin(MSG_ONE_UNRELIABLE, msgDamage, _, id);
	write_byte(0); // damage save
	write_byte(0); // damage take
	write_long(DMG_BURN); // damage type
	write_coord(0); // x
	write_coord(0); // y
	write_coord(0); // z
	message_end();

	// If player is already on fire
	if (g_IsOnFire[id])
	{
		// Only update the duration
		g_BurnDuration[id] = min(g_BurnDuration[id] + CvarDuration, CvarMaxDuration);
		client_print(0, print_chat, "g_BurnDuration = %d", g_BurnDuration[id]);
	}
	else
	{
		// Set a new fire
		g_IsOnFire[id] = true;
		g_BurnStartTime[id] = get_gametime();
		g_NextHurtTime[id] = get_gametime();
		g_BurnDuration[id] = CvarDuration;
	}

	g_BurnAttacker[id] = attacker;

	emit_sound(id, CHAN_VOICE, SOUND_BURN, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

SetPlayerOffFire(id, bool:effect=false)
{
	// If player has not been burned yet
	if (!g_IsOnFire[id])
		return;
	
	new Float:origin[3];
	entity_get_vector(id, EV_VEC_origin, origin);

	// Play the effect?
	if (effect)
	{
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_SMOKE); // TE id
		write_coord_f(origin[0]); // x
		write_coord_f(origin[1]); // y
		write_coord_f(origin[2]-36.0); // z
		write_short(g_SprSmoke); // sprite
		write_byte(random_num(10, 15)); // scale
		write_byte(random_num(10, 20)); // framerate
		message_end();
	}

	if (pev_valid(id))
		emit_sound(id, CHAN_VOICE, SOUND_BURN, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM);

	// Remove the fire
	g_IsOnFire[id] = false;
	g_BurnDuration[id] = 0;
}

CreateBlast(ent, const Float:origin[3])
{
	new Float:ratio = CvarRadius / 240.0;
	new life = floatround(4 * ratio);
	new count = entity_get_int(ent, EV_INT_iuser1);
	new brightness = count == 1 ? 200 : 125;

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_BEAMCYLINDER);
	write_coord_f(origin[0]); // position
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_coord_f(origin[0]); // axis
	write_coord_f(origin[1]);
	write_coord_f(origin[2] + 385.0 * ratio);
	write_short(g_SprWave); // sprite
	write_byte(0); // startframe
	write_byte(0); // framerate
	write_byte(life); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(200); // red
	write_byte(50); // green
	write_byte(0); // blue
	write_byte(brightness); // brightness
	write_byte(0); // speed
	message_end()

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_BEAMCYLINDER);
	write_coord_f(origin[0]); // position
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_coord_f(origin[0]); // axis
	write_coord_f(origin[1]);
	write_coord_f(origin[2] + 470.0 * ratio);
	write_short(g_SprWave); // sprite
	write_byte(0); // startframe
	write_byte(0); // framerate
	write_byte(life); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(200); // red
	write_byte(25); // green
	write_byte(0); // blue
	write_byte(brightness); // brightness
	write_byte(0); // speed
	message_end()

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_BEAMCYLINDER);
	write_coord_f(origin[0]); // position
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_coord_f(origin[0]); // axis
	write_coord_f(origin[1]);
	write_coord_f(origin[2] + 555.0 * ratio);
	write_short(g_SprWave); // sprite
	write_byte(0); // startframe
	write_byte(0); // framerate
	write_byte(life); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(200); // red
	write_byte(50); // green
	write_byte(0); // blue
	write_byte(brightness); // brightness
	write_byte(0); // speed
	message_end()

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_DLIGHT); // TE_DLIGHT
	write_coord_f(origin[0]); // position
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_byte(50); // radius
	if (count == 1)
	{
		write_byte(200); // r
		write_byte(50); // g
		write_byte(0); // b
	}
	else
	{
		write_byte(150); // r
		write_byte(25); // g
		write_byte(0); // b
	}
	write_byte(10); // life
	write_byte(60); // decay rate
	message_end();

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_EXPLOSION);
	write_coord_f(origin[0]); // position
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_short(g_SprExplo); // sprite
	write_byte(25); // scale
	write_byte(30);
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND);
	message_end();
}