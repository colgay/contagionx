#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <json>
#include <oo>

#include <ctg_const>

public oo_init()
{
	oo_decl_class("PlayerClassInfo");
	{
		new const cl[] = "PlayerClassInfo";

		oo_decl_var(cl, "m_Name", OO_ARRAY[32]);
		oo_decl_var(cl, "m_Desc", OO_ARRAY[32]);
		oo_decl_var(cl, "m_Team", OO_CELL);
		oo_decl_var(cl, "m_Flags", OO_CELL);
		oo_decl_var(cl, "m_Models", OO_CELL); // Array:
		oo_decl_var(cl, "m_ViewModels", OO_CELL); // Trie:
		oo_decl_var(cl, "m_WeaponModels", OO_CELL); // Trie:
		oo_decl_var(cl, "m_Sounds", OO_CELL); // Trie:
		oo_decl_var(cl, "m_Cvars", OO_ARRAY[4]);

		// (const name[], const desc[], team, flags)
		oo_decl_ctor(cl, "Ctor", OO_STRING, OO_STRING, OO_CELL, OO_CELL);
		oo_decl_dtor(cl, "Dtor");

		// (const cvar_prefix[], hp, Float:gravity, Float:speed, Float:knockback)
		oo_decl_method(cl, "CreateCvars", OO_STRING, OO_CELL, OO_CELL, OO_CELL, OO_CELL);

		oo_decl_method(cl, "LoadAssets");
		oo_decl_method(cl, "LoadJson", OO_STRING); // (const filename[])
	}

	oo_decl_class("PlayerClass");
	{
		new const cl[] = "PlayerClass";

		oo_decl_var(cl, "m_oPlayer", OO_CELL); // Obj:
		oo_decl_var(cl, "m_oPlayerClassInfo", OO_CELL); // Obj:

		oo_decl_ctor(cl, "Ctor", OO_CELL); // (Obj:oPlayer)
		oo_decl_dtor(cl, "Dtor");

		oo_decl_method(cl, "GetPlayerIndex");
		oo_decl_method(cl, "SetPlayerClassInfo");
		oo_decl_method(cl, "SetPlayerProps");
		oo_decl_method(cl, "SetMaxSpeed");
		oo_decl_method(cl, "SetWeaponModel", OO_CELL); // (entity)

		// (id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
		oo_decl_method(cl, "ChangeSound", OO_CELL, OO_CELL, OO_STRING, OO_CELL, OO_CELL, OO_CELL, OO_CELL);
	}

	oo_decl_class("Player")
	{
		new const cl[] = "Player";

		oo_decl_var(cl, "m_PlayerId", OO_CELL);
		oo_decl_var(cl, "m_Team", OO_CELL);
		oo_decl_var(cl, "m_oPlayerClass", OO_CELL); // Obj:

		oo_decl_ctor(cl, "Ctor", OO_CELL); // (id)
		oo_decl_dtor(cl, "Dtor");

		oo_decl_method(cl, "GetTeam");
		oo_decl_method(cl, "Connect");
		oo_decl_method(cl, "Disconnect");
		oo_decl_method(cl, "GetPlayerClass");
		oo_decl_method(cl, "ChangePlayerClass", OO_STRING); // (const classname[])
	}

	oo_decl_class("PlayerHandler")
	{
		new const cl[] = "PlayerHandler";

		oo_decl_var(cl, "m_oPlayers", OO_ARRAY[MAX_PLAYERS+1]);

		oo_decl_ctor(cl, "Ctor");
		oo_decl_dtor(cl, "Dtor");

		oo_decl_method(cl, "Connect", OO_CELL); // (id)
		oo_decl_method(cl, "Disconnect", OO_CELL); // (id)
		oo_decl_method(cl, "GetPlayer", OO_CELL); // (id)
	}
}

public Obj:g_oPlayerHandler;

public plugin_init()
{
	register_plugin("Contagion", CTG_VERSION, "colg");

	new wpn_name[32];
	for (new i = CSW_P228; i <= CSW_P90; i++)
	{
		get_weaponname(i, wpn_name, charsmax(wpn_name));
		if (wpn_name[0]) RegisterHam(Ham_Item_Deploy, wpn_name, "OnItemDeploy_Post", 1, true);
	}

	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "OnPlayerResetMaxSpeed_Post", 1, true);

	register_forward(FM_EmitSound, "OnEmitSound");

	g_oPlayerHandler = oo_new("PlayerHandler");
}

/* ---------- [PlayerClassInfo] ---------- */

public PlayerClassInfo@Ctor(const name[], const desc[], team, flags)
{
	new Obj:this = oo_this();

	oo_set_arr@( this["m_Name"][0..0] = name[0..strlen(name)] );
	oo_set_arr@( this["m_Desc"][0..0] = name[0..strlen(desc)] );
	oo_set(this["m_Team"] = team);
	oo_set(this["m_Flags"] = flags);

	oo_set(this["m_Models"] = ArrayCreate(32));
	oo_set(this["m_ViewModels"] = TrieCreate());
	oo_set(this["m_WeaponModels"] = TrieCreate());
	oo_set(this["m_Sounds"] = TrieCreate());

	oo_call(this, "LoadAssets");
}

public PlayerClassInfo@Dtor()
{
}

public PlayerClassInfo@CreateCvars(const cvar_prefix[], hp, Float:gravity, Float:speed, Float:knockback)
{
	static cvar_name[50], cvar_value[16];

	new pcvars[4];
	formatex(cvar_name, charsmax(cvar_name), "ctg_%s_hp", cvar_prefix);
	num_to_str(hp, cvar_value, charsmax(cvar_value));
	pcvars[0] = create_cvar(cvar_name, cvar_value);

	formatex(cvar_name, charsmax(cvar_name), "ctg_%s_gravity", cvar_prefix);
	float_to_str(gravity, cvar_value, charsmax(cvar_value));
	pcvars[1] = create_cvar(cvar_name, cvar_value);

	formatex(cvar_name, charsmax(cvar_name), "ctg_%s_speed", cvar_prefix);
	float_to_str(speed, cvar_value, charsmax(cvar_value));
	pcvars[2] = create_cvar(cvar_name, cvar_value);

	formatex(cvar_name, charsmax(cvar_name), "ctg_%s_knockback", cvar_prefix);
	float_to_str(knockback, cvar_value, charsmax(cvar_value));
	pcvars[3] = create_cvar(cvar_name, cvar_value);

	oo_set_arr(oo_this()["m_Cvars"] = pcvars);
}

public PlayerClassInfo@LoadAssets() // override this
{
	oo_call(oo_this(), "LoadJson", "player");
}

public PlayerClassInfo@LoadJson(const filename[])
{
	new Obj:this = oo_this();

	static path[100];
	get_configsdir(path, charsmax(path));

	format(path, charsmax(path), "%s/contagion/playerclass/%s.json", path, filename);

	new JSON:json = json_parse(path, true, true);
	if (json != Invalid_JSON)
	{
		static key[128], value[128];

		new JSON:playermodels = json_object_get_value(json, "playermodels");
		if (playermodels != Invalid_JSON)
		{
			new Array:aModels = Array:oo_get(this["m_Models"]);
			for (new i = json_array_get_count(playermodels) - 1; i >= 0; i--)
			{
				json_array_get_string(playermodels, i, value, charsmax(value));
				ArrayPushString(aModels, value);
				PrecachePlayerModel(value);
			}
			json_free(playermodels);
		}

		new JSON:viewmodels = json_object_get_value(json, "viewmodels");
		if (viewmodels != Invalid_JSON)
		{
			new JSON:vmodel_val = Invalid_JSON;
			new Trie:tViewModels = Trie:oo_get(this["m_ViewModels"]);
			for (new i = json_object_get_count(viewmodels) - 1; i >= 0; i--)
			{
				json_object_get_name(viewmodels, i, key, charsmax(key));
				vmodel_val = json_object_get_value_at(viewmodels, i);
				json_get_string(vmodel_val, value, charsmax(value));
				json_free(vmodel_val);
				TrieSetString(tViewModels, key, value);
				if (value[0])
					precache_model(value);
			}
			json_free(viewmodels);
		}

		new JSON:weapmodels = json_object_get_value(json, "weaponmodels");
		if (weapmodels != Invalid_JSON)
		{
			new JSON:pmodel_val = Invalid_JSON;
			new Trie:tWeaponModels = Trie:oo_get(this["m_WeaponModels"]);
			for (new i = json_object_get_count(weapmodels) - 1; i >= 0; i--)
			{
				json_object_get_name(weapmodels, i, key, charsmax(key));
				pmodel_val = json_object_get_value_at(weapmodels, i);
				json_get_string(pmodel_val, value, charsmax(value));
				json_free(pmodel_val);
				TrieSetString(tWeaponModels, key, value);
				if (value[0])
					precache_model(value);
			}
			json_free(weapmodels);
		}

		new JSON:sounds = json_object_get_value(json, "sounds");
		if (sounds != Invalid_JSON)
		{
			new Array:sound_array = Invalid_Array;
			new JSON:sound_val = Invalid_JSON;
			new Trie:tSounds = Trie:oo_get(this["m_Sounds"]);
			for (new i = json_object_get_count(sounds) - 1; i >= 0; i--)
			{
				json_object_get_name(sounds, i, key, charsmax(key));
				sound_val = json_object_get_value_at(sounds, i);
				sound_array = ArrayCreate(100);
				for (new i = json_array_get_count(sound_val) - 1; i >= 0; i--)
				{
					json_array_get_string(sound_val, i, value, charsmax(value));
					ArrayPushString(sound_array, value);
					if (value[0])
						precache_sound(value);
				}
				json_free(sound_val);
				TrieSetCell(tSounds, key, sound_array);
			}
			json_free(sounds);
		}

		json_free(json);
	}

	server_print("[CTG] Loaded PlayerClass (%s)", path);
}

/* ---------- [PlayerClass] ---------- */

public PlayerClass@Ctor(Obj:o_player)
{
	server_print("PlayerClass@Ctor(%d)", o_player);
	client_print(0, print_console, "PlayerClass@Ctor(%d)", o_player);

	new Obj:this = oo_this();
	oo_set(this["m_oPlayer"] = o_player);

	oo_call(this, "SetPlayerClassInfo");
	//void_send#this."SetPlayerProps");
}

public PlayerClass@Dtor()
{
	server_print("PlayerClass@Dtor()");
	client_print(0, print_console, "PlayerClass@Dtor()");
}

public PlayerClass@GetPlayerIndex()
{
	new Obj:o_player = Obj:oo_get(oo_this()["m_oPlayer"]);
	if (o_player == @null)
		return 0;
	
	return oo_get(o_player["m_PlayerId"]);
}

public PlayerClass@SetPlayerClassInfo() // override this?
{
	oo_set(oo_this()["m_oPlayerClassInfo"] = @null);
}

public PlayerClass@SetPlayerProps()
{
	new Obj:this = oo_this();

	new Obj:o_info = Obj:oo_get(this["m_oPlayerClassInfo"]);
	if (o_info == @null)
		return;

	new pcvars[2];
	oo_get_arr@(pcvars[0..2] = o_info["m_Cvars"][0..2]);

	new id = oo_call(this, "GetPlayerIndex");

	if (pcvars[0]) // has health
		set_user_health(id, get_pcvar_num(pcvars[0]));

	if (pcvars[1]) // has gravity
		set_user_gravity(id, get_pcvar_float(pcvars[1]));

	new Array:models = Array:oo_get(o_info["m_Models"]);
	new model_size = ArraySize(models);
	if (model_size > 0) // has model
	{
		static buffer[32];
		ArrayGetString(models, random(model_size), buffer, charsmax(buffer));
		cs_set_user_model(id, buffer);
	}

	ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id); // update maxspeed

	new ent = get_ent_data_entity(id, "CBasePlayer", "m_pActiveItem");
	if (pev_valid(ent)) ExecuteHamB(Ham_Item_Deploy, ent); // update weapon model
}

public PlayerClass@SetWeaponModel(ent)
{
	new Obj:this = oo_this();

	new Obj:o_info = Obj:oo_get(this["m_oPlayerClassInfo"]);
	if (o_info == @null)
		return;

	new classname[32];
	pev(ent, pev_classname, classname, charsmax(classname));

	static model[128];
	new id = oo_call(this, "GetPlayerIndex");

	if (TrieGetString(Trie:oo_get(o_info["m_ViewModels"]), classname, model, charsmax(model)))
	{
		set_pev(id, pev_viewmodel2, model);
	}

	if (TrieGetString(Trie:oo_get(o_info["m_WeaponModels"]), classname, model, charsmax(model)))
	{
		set_pev(id, pev_weaponmodel2, model);
	}
}

public PlayerClass@SetMaxSpeed()
{
	new Obj:this = oo_this();

	new Obj:o_info = Obj:oo_get(this["m_oPlayerClassInfo"]);
	if (o_info == @null)
		return;

	new pcvar;
	oo_get_arr@(pcvar[0..1] = o_info["m_Cvars"][2..3]);

	if (pcvar)
	{
		new id = oo_call(this, "GetPlayerIndex");
		
		new Float:maxspeed = get_user_maxspeed(id);
		new Float:value = get_pcvar_float(pcvar);
		set_user_maxspeed(id, (value <= 10.0) ? maxspeed * value : value);
	}
}

public PlayerClass@ChangeSound(id, channel, const sample[], Float:volume, Float:attenuation, flags, pitch)
{
	new Obj:this = oo_this();

	new Obj:o_info = Obj:oo_get(this["m_oPlayerClassInfo"]);
	if (o_info == @null)
		return 0;

	static sound[128], Array:sound_array;

	if (TrieGetCell(Trie:oo_get(o_info["m_Sounds"]), sample, sound_array))
	{
		ArrayGetString(sound_array, random(ArraySize(sound_array)), sound, charsmax(sound));
		emit_sound(id, channel, sound, volume, attenuation, flags, pitch);
		return 1;
	}

	return 0
}

/* ---------- [Player] ---------- */

public Player@Ctor(id)
{
	server_print("Player@Ctor(%d)", id);

	new Obj:this = oo_this();
	oo_set(this["m_PlayerId"] = id);
	oo_set(this["m_oPlayerClass"] = @null);
}

public Player@Dtor()
{
	server_print("Player@Dtor()");

	new Obj:this = oo_this();

	new Obj:o_playerclass = Obj:oo_get(this["m_oPlayerClass"]);
	if (o_playerclass != @null)
		oo_delete(o_playerclass);
}

public Player@GetPlayerClass()
{
	return oo_get(oo_this()["m_oPlayerClass"]);
}

public Player@Connect()
{
	new player_id = oo_get(oo_this()["m_PlayerId"]);
	server_print("Player@Connect(%d)", player_id);
}

public Player@Disconnect()
{
	new player_id = oo_get(oo_this()["m_PlayerId"]);
	server_print("Player@Disconnect(%d)", player_id);
}

public Player@ChangePlayerClass(const classname[])
{
	new Obj:this = oo_this();
	new player_id = oo_get(this["m_PlayerId"]);

	new Obj:o_playerclass = Obj:oo_call(this, "GetPlayerClass");
	if (o_playerclass != @null)
	{
		// delete if exists
		oo_delete(o_playerclass);
		oo_set(this["m_oPlayerClass"] = @null);
	}

	o_playerclass = oo_new(classname, this);
	if (o_playerclass == @null) return;

	oo_set(this["m_oPlayerClass"] = o_playerclass);
	oo_call(o_playerclass, "SetPlayerProps");

	new Obj:o_info;
	oo_get(o_info = o_playerclass["m_oPlayerClassInfo"]);
	if (o_info == @null) return;

	oo_set(this["m_Team"] = oo_get(o_info["m_Team"]));

	server_print("Player@ChangePlayerClass(%s) -> {id=%d, name=%n, obj=%d}", classname, player_id, player_id, o_playerclass);
	client_print(0, print_console, "Player@ChangePlayerClass(%s) -> {id=%d, name=%n, obj=%d}^n===============", classname, player_id, player_id, o_playerclass);
}

public Player@GetTeam()
{
	return oo_get(oo_this()["m_Team"]);
}

/* ---------- [PlayerHandler] ---------- */

public PlayerHandler@Ctor()
{
}

public PlayerHandler@Dtor()
{
	new Obj:o_player[MAX_PLAYERS+1] = {@null, ...};
	oo_get_arr@(o_player[1..MaxClients] = oo_this()["m_oPlayers"][1..MaxClients]);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (o_player[i] != @null)
		{
			oo_delete(o_player[i]);
		}
	}
}

public PlayerHandler@Connect(id)
{
	new Obj:this = oo_this();

	new Obj:o_player;
	oo_get_arr@(o_player[0..1] = this["m_oPlayers"][id..id+1]);

	if (o_player == @null)
	{
		o_player = oo_new("Player", id);
		oo_set_arr@(this["m_oPlayers"][id..id+1] = o_player[0..1]);
		oo_call(o_player, "Connect");
	}
}

public PlayerHandler@Disconnect(id)
{
	new Obj:this = oo_this();

	new Obj:o_player;
	oo_get_arr@(o_player[0..1] = this["m_oPlayers"][id..id+1]);

	if (o_player != @null)
	{
		oo_call(o_player, "Disconnect");

		oo_delete(o_player);
		o_player = @null;
		oo_set_arr@(this["m_oPlayers"][id..id+1] = o_player[0..1]);
	}
}

public Obj:PlayerHandler@GetPlayer(id)
{
	new Obj:o_player;
	oo_get_arr@(o_player[0..1] = oo_this()["m_oPlayers"][id..id+1]);

	return o_player;
}

/* ---------- [Forwards] ---------- */

public client_connectex(id)
{
	oo_call(g_oPlayerHandler, "Connect", id);
}

public client_disconnected(id)
{
	oo_call(g_oPlayerHandler, "Disconnect", id);
}

public OnItemDeploy_Post(ent)
{
	if (!pev_valid(ent))
		return;

	new player = get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
	if (player)
	{
		new Obj:o_player = Obj:oo_call(g_oPlayerHandler, "GetPlayer", player);
		if (o_player == @null)
			return;

		new Obj:o_playerclass = Obj:oo_call(o_player, "GetPlayerClass");
		if (o_playerclass == @null)
			return;

		oo_call(o_playerclass, "SetWeaponModel", ent);
	}
}

public OnPlayerResetMaxSpeed_Post(id)
{
	if (is_user_alive(id))
	{
		new Obj:o_player = Obj:oo_call(g_oPlayerHandler, "GetPlayer", id);
		if (o_player == @null)
			return;

		new Obj:o_playerclass = Obj:oo_call(o_player, "GetPlayerClass");
		if (o_playerclass == @null)
			return;

		oo_call(o_playerclass, "SetMaxSpeed");
	}
}

public OnEmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (is_user_alive(id))
	{
		new Obj:o_player = Obj:oo_call(g_oPlayerHandler, "GetPlayer", id);
		if (o_player == @null)
			return FMRES_IGNORED;

		new Obj:o_playerclass = Obj:oo_call(o_player, "GetPlayerClass");
		if (o_playerclass == @null)
			return FMRES_IGNORED;

		if (oo_call(o_playerclass, "ChangeSound", id, channel, sample, volume, attn, flags, pitch))
			return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

stock PrecachePlayerModel(const model[])
{
	static model_path[128];
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", model, model);
	precache_model(model_path);

	// Support modelT.mdl files
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", model, model);
	if (file_exists(model_path)) precache_model(model_path);
}