#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <oo>
#include <ctg_const>

public oo_init()
{
	new Class:pc = oo_class("PlayerClass");
	{
		oo_var(pc, DT_CELL, "m_oPlayer"); // Object:
		oo_var(pc, DT_CELL, "m_oClassInfo"); // Object:

		oo_method(pc, MT_CTOR, "Ctor", FP_CELL); // (Object:oPlayer)
		oo_method(pc, MT_DTOR, "Dtor");

		oo_method(pc, MT_METHOD, "AssignClassInfo");
		oo_method(pc, MT_METHOD, "GetPlayerIndex");
		oo_method(pc, MT_METHOD, "SetProperties");
		oo_method(pc, MT_METHOD, "SetWeaponModel", FP_CELL); // (ent)
		oo_method(pc, MT_METHOD, "SetMaxSpeed");
		oo_method(pc, MT_METHOD, "ChangeSound", FP_CELL, FP_CELL, FP_STRING, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	}
}

public PlayerClass@Ctor(Object:oPlayer)
{
	new Object:this = oo_this();
	oo_set(this, "m_oPlayer", oPlayer);
	oo_call(this, "AssignClassInfo");
}

public PlayerClass@AssignClassInfo()
{
	oo_set(oo_this(), "m_oClassInfo", @null);
}

public PlayerClass@GetPlayerIndex()
{
	new Object:oPlayer = Object:oo_get(oo_this(), "m_oPlayer");
	return oo_get(oPlayer, "m_Index");
}

public PlayerClass@SetProperties()
{
	new Object:this = oo_this();
	new Object:oClassInfo = Object:oo_get(this, "m_oClassInfo");
	new id = oo_call(this, "GetPlayerIndex");	

	new pcvar[4];
	oo_get(oClassInfo, "m_Cvars", pcvar);

	if (pcvar[0]) // has health
		set_user_health(id, get_pcvar_num(pcvar[0]));
	
	if (pcvar[1]) // has gravity
		set_user_gravity(id, get_pcvar_float(pcvar[1]));

	new Array:models = Array:oo_get(oClassInfo, "m_Models");
	new model_size = ArraySize(models);
	if (model_size > 0) // has model
	{
		new buffer[32];
		ArrayGetString(models, random(model_size), buffer, charsmax(buffer));
		cs_set_user_model(id, buffer);
	}

	ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id); // update maxspeed

	new ent = get_ent_data_entity(id, "CBasePlayer", "m_pActiveItem");
	if (pev_valid(ent)) ExecuteHamB(Ham_Item_Deploy, ent); // update view model
}

public PlayerClass@SetWeaponModel(ent)
{
	new Object:this = oo_this();

	new Object:oClassInfo = Object:oo_get(this, "m_oClassInfo");

	new classname[32];
	pev(ent, pev_classname, classname, charsmax(classname));

	new model[100]
	new player = oo_call(this, "GetPlayerIndex");

	server_print("player is %n", player);

	// has v_model
	if (TrieGetString(Trie:oo_get(oClassInfo, "m_ViewModels"), classname, model, charsmax(model)))
	{
		set_pev(player, pev_viewmodel2, model);
	}

	// has p_model
	if (TrieGetString(Trie:oo_get(oClassInfo, "m_WeaponModels"), classname, model, charsmax(model)))
	{
		set_pev(player, pev_weaponmodel2, model);
	}

	server_print("abc");
}

public PlayerClass@SetMaxSpeed()
{
	new Object:this = oo_this();
	new Object:oClassInfo = Object:oo_get(this, "m_oClassInfo");

	new pcvar[4];
	oo_get(oClassInfo, "m_Cvars", pcvar);

	if (pcvar[2]) // has maxspeed
	{
		new player = oo_call(this, "GetPlayerIndex");

		new Float:maxspeed = get_user_maxspeed(player);
		new Float:value = get_pcvar_float(pcvar[2]);

		set_user_maxspeed(player, (value <= 10.0) ? maxspeed * value : value);
	}
}

public bool:PlayerClass@ChangeSound(id, channel, const sample[], &Float:volume, Float:attenuation, flags, pitch)
{
	new Object:this = oo_this();
	new Object:oClassInfo = Object:oo_get(this, "m_oClassInfo");

	new sound[100], Array:sound_array;
	if (TrieGetCell(Trie:oo_get(oClassInfo, "m_Sounds"), sample, sound_array))
	{
		new player = oo_call(this, "GetPlayerIndex");
		ArrayGetString(sound_array, random(ArraySize(sound_array)), sound, charsmax(sound));
		emit_sound(player, channel, sound, volume, attenuation, flags, pitch);
		return true;
	}

	return false;
}

public PlayerClass@Dtor() { }

public plugin_init()
{
	register_plugin("[CTG] Player Class", CTG_VERSION, "colg");
}