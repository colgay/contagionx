#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <oo>
#include <ctg_const>

public oo_init()
{
	new Class:pl = oo_class("Player");
	{
		oo_var(pl, DT_CELL, "m_Index");
		oo_var(pl, DT_CELL, "m_Team"); // PlayerTeam:
		oo_var(pl, DT_CELL, "m_oClass"); // Object:

		oo_method(pl, MT_CTOR, "Ctor", FP_CELL); // (player_id)
		oo_method(pl, MT_DTOR, "Dtor");

		oo_method(pl, MT_METHOD, "Connect");
		oo_method(pl, MT_METHOD, "Disconnect");
		oo_method(pl, MT_METHOD, "ChangeClass", FP_STRING); // (const classname[])
	}
}

public Player@Ctor(player_id)
{
	new Object:this = oo_this();
	oo_set(this, "m_Index", player_id);
	oo_set(this, "m_Team", Team_None);
	oo_set(this, "m_oClass", @null);
}

public Player@ChangeClass(const class[])
{
	new Object:this = oo_this();

	new Object:oClass = Object:oo_get(this, "m_oClass");
	if (oClass != @null)
	{
		// delete old player class
		oo_delete(oClass);
		oo_set(this, "m_oClass", @null);
	}

	new Class:cClass = oo_get_class_id(class);
	if (cClass != CNull && oo_parent_of(cClass, "PlayerClass")) // check valid class
	{
		oClass = oo_new(class, "Ctor", this); // create new class
		oo_set(this, "m_oClass", oClass);

		new Object:oClassInfo = Object:oo_get(oClass, "m_oClassInfo");
		oo_set(this, "m_Team", oo_get(oClassInfo, "m_Team")); // set player team 

		oo_call(oClass, "SetProperties");
		oo_call(g_oGameRules, "ChangePlayerClass", this);
	}
}

public Player@Dtor() { }
public Player@Connect() { }
public Player@Disconnect() { }

new Object:g_Players[MAX_PLAYERS+1] = {@null, ...};
new Object:g_oGameRules;

public plugin_init()
{
	register_plugin("[CTG] Player", CTG_VERSION, "colg");
	
	register_forward(FM_EmitSound, "OnEmitSound");

	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "OnPlayerResetMaxspeed_Post", 1);

	new weapon_name[32];
	for (new i = CSW_P228; i <= CSW_P90; i++)
	{
		get_weaponname(i, weapon_name, charsmax(weapon_name));
		if (weapon_name[0])
			RegisterHam(Ham_Item_Deploy, weapon_name, "OnItemDeploy_Post", 1);
	}

	register_clcmd("say zombie", "CmdZombie");
	register_clcmd("say human", "CmdHuman");

	xvar = get_xvar_id("g_oGameRules");
	g_oGameRules = Object:get_xvar_num(xvar);
}

public plugin_natives()
{
	register_native("ctg_GetPlayerObject", "native_GetPlayerObject");
}

public native_GetPlayerObj()
{
	new id = get_param(1);
	if (!(1 <= id <= MaxClients))
		return @null;
	
	return g_Players[id];
}

public CmdZombie(id)
{
	oo_call(g_Players[id], "ChangeClass", "Zombie");
}

public CmdHuman(id)
{
	oo_call(g_Players[id], "ChangeClass", "Human");
}

public OnPlayerResetMaxspeed_Post(id)
{
	if (is_user_alive(id))
	{
		new Object:oClass = Object:oo_get(g_Players[id], "m_oClass");
		if (oClass != @null)
			oo_call(oClass, "SetMaxSpeed");
	}
}

public OnItemDeploy_Post(ent)
{
	if (pev_valid(ent))
	{
		new player = get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
		if (is_user_alive(player))
		{
			new Object:oClass = Object:oo_get(g_Players[player], "m_oClass");
			if (oClass != @null)
				oo_call(oClass, "SetWeaponModel", ent);
		}
	}
}

public OnEmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (is_user_alive(id))
	{
		new Object:oClass = Object:oo_get(g_Players[id], "m_oClass");
		if (oClass != @null)
		{
			if (oo_call(oClass, "ChangeSound", id, channel, sample, volume, attn, flags, pitch))
				return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public client_connect(id)
{
	g_Players[id] = oo_new("Player", "Ctor", id);
	oo_call(g_Players[id], "Connect");
}

public client_disconnected(id)
{
	oo_call(g_Players[id], "Disconnect");
	oo_delete(g_Players[id]);
	g_Players[id] = @null;
}