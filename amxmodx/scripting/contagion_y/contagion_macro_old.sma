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
	class<"PlayerClassInfo">@
	{
		new const c[] = "PlayerClassInfo";

		ivar<c>@Public["m_Name"]:OO_ARRAY[32]@
		ivar<c>@Public["m_Desc"]:OO_ARRAY[32]@
		ivar<c>@Public["m_Team"]:OO_CELL@
		ivar<c>@Public["m_Flags"]:OO_CELL@
		ivar<c>@Public["m_Models"]:OO_CELL@ // Array:
		ivar<c>@Public["m_ViewModels"]:OO_CELL@ // Trie:
		ivar<c>@Public["m_WeaponModels"]:OO_CELL@ // Trie:
		ivar<c>@Public["m_Sounds"]:OO_CELL@ // Trie:
		ivar<c>@Public["m_Cvars"]:OO_ARRAY[4]@

		// (const name[], const desc[], team, flags)
		ctor<c>@Public."Ctor"(OO_STRING_CONST, OO_STRING_CONST, OO_CELL, OO_CELL)@
		dtor<c>@Public."Dtor"()@

		// (const cvar_prefix[], hp, Float:gravity, Float:speed, Float:knockback)
		msg<c>@Public."CreateCvars"(OO_STRING_CONST, OO_CELL, OO_CELL, OO_CELL, OO_CELL)@

		void_msg<c>@Public."LoadAssets"()@
		msg<c>@Public."LoadJson"(OO_STRING_CONST)@ // (const filename[])
	}

	class<"PlayerClass">@
	{
		new const c[] = "PlayerClass";

		ivar<c>@Public["m_oPlayer"]:OO_CELL@ // Obj:
		ivar<c>@Public["m_oPlayerClassInfo"]:OO_CELL@ // Obj:

		ctor<c>@Public."Ctor"(OO_CELL)@ // (Obj:oPlayer)
		dtor<c>@Public."Dtor"()@

		void_msg<c>@Public."GetPlayerIndex"()@
		void_msg<c>@Public."SetPlayerClassInfo"()@
		void_msg<c>@Public."SetPlayerProps"()@
		void_msg<c>@Public."SetMaxSpeed"()@
		msg<c>@Public."SetWeaponModel"(OO_CELL)@ // (entity)

		// (id, channel, const sample[], Float:volume, Float:attenuation, flags, pitch)
		msg<c>@Public."ChangeSound"(OO_CELL, OO_CELL, OO_STRING_CONST, OO_CELL, OO_CELL, OO_CELL, OO_CELL)@
	}

	class<"Player">@
	{
		new const c[] = "Player";

		ivar<c>@Public["m_PlayerId"]:OO_CELL@
		ivar<c>@Public["m_oPlayerClass"]:OO_CELL@ // Obj:

		ctor<c>@Public."Ctor"(OO_CELL)@ // (id)
		dtor<c>@Public."Dtor"()@

		void_msg<c>@Public."Connect"()@
		void_msg<c>@Public."Disconnect"()@
		void_msg<c>@Public."GetPlayerClass"()@
		msg<c>@Public."ChangePlayerClass"(OO_STRING_CONST)@ // (const classname[])
	}

	class<"PlayerHandler">@
	{
		new const c[] = "PlayerHandler";

		ivar<c>@Public["m_oPlayers"]:OO_ARRAY[MAX_PLAYERS+1]@

		void_ctor<c>@Public."Ctor"()@
		void_dtor<c>@Public."Dtor"()@

		msg<c>@Public."Connect"(OO_CELL)@ // (id)
		msg<c>@Public."Disconnect"(OO_CELL)@ // (id)
		msg<c>@Public."GetPlayer"(OO_CELL)@ // (id)
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

	g_oPlayerHandler = alloc<"PlayerHandler">();
}

/* ---------- [PlayerClassInfo] ---------- */

public PlayerClassInfo@Ctor(const name[], const desc[], team, flags)
{
	new Obj:this = THIS@;

	write_a#this["m_Name"][0..32] << { name[0..strlen(name)] }
	write_a#this["m_Desc"][0..32] << { desc[0..strlen(desc)] }
	write#this["m_Team"] << { team }
	write#this["m_Flags"] << { flags }

	write#this["m_Models"] << { ArrayCreate(32) } 
	write#this["m_ViewModels"] << { TrieCreate() }
	write#this["m_WeaponModels"] << { TrieCreate() }
	write#this["m_Sounds"] << { TrieCreate() }

	void_send#this."LoadAssets"();
}

public PlayerClassInfo@Dtor()
{
	/*
	new Obj:this = THIS;

	new Array:playermodels = Array:read#this["m_Models"];
	new Trie:viewmodels = Trie:read#this["m_ViewModels"];
	new Trie:weaponmodels = Trie:read#this["m_WeaponModels"];
	new Trie:sounds = Trie:read#this["m_Sounds"];

	// delete sound arrays
	new TrieIter:iter = TrieIterCreate(sounds);
	{
		new Array:sound_array = Invalid_Array;

		while (!TrieIterEnded(iter))
		{
			TrieIterGetCell(iter, sound_array);
			if (sound_array != Invalid_Array)
				ArrayDestroy(sound_array);

			TrieIterNext(iter);
		}

		TrieIterDestroy(iter);
	}

	ArrayDestroy(playermodels); // why is &ref
	TrieDestroy(viewmodels);
	TrieDestroy(weaponmodels);
	TrieDestroy(sounds);
	*/
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

	write_a#THIS@["m_Cvars"][0..4] << { pcvars[0..4] }
}

public PlayerClassInfo@LoadAssets() // override this
{
	send#THIS@."LoadJson"("player");
}

public PlayerClassInfo@LoadJson(const filename[])
{
	new Obj:this = THIS@;

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
			new Array:aModels = Array:read#this["m_Models"];
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
			new Trie:tViewModels = Trie:read#this["m_ViewModels"];
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
			new Trie:tWeaponModels = Trie:read#this["m_WeaponModels"];
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
			new Trie:tSounds = Trie:read#this["m_Sounds"];

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

	new Obj:this = THIS@;
	write#this["m_oPlayer"] << { o_player }

	void_send#this."SetPlayerClassInfo"();
	//void_send#this."SetPlayerProps"();
}

public PlayerClass@Dtor()
{
	server_print("PlayerClass@Dtor()");
}

public PlayerClass@GetPlayerIndex()
{
	new Obj:o_player = Obj:read#THIS@["m_oPlayer"];
	if (o_player == @null)
		return 0;
	
	return read#o_player["m_PlayerId"];
}

public PlayerClass@SetPlayerClassInfo() // override this?
{
	write#THIS@["m_oPlayerClassInfo"] << { @null }

	server_print("called original");
}

public PlayerClass@SetPlayerProps()
{
	new Obj:this = THIS@;

	new Obj:o_info = Obj:read#this["m_oPlayerClassInfo"];
	if (o_info == @null)
		return;

	new pcvars[2];
	read_a#o_info["m_Cvars"][0..2] >> { pcvars[0..2] }

	new id = void_send#this."GetPlayerIndex"();

	if (pcvars[0]) // has health
		set_user_health(id, get_pcvar_num(pcvars[0]));

	if (pcvars[1]) // has gravity
		set_user_gravity(id, get_pcvar_float(pcvars[1]));

	new Array:models = Array:read#o_info["m_Models"];
	new model_size = ArraySize(models);
	if (model_size > 0) // has model
	{
		static buffer[32];
		ArrayGetString(models, random(model_size), buffer, charsmax(buffer));
		cs_set_user_model(id, buffer);
	}

	ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id); // update maxspeed
}

public PlayerClass@SetWeaponModel(ent)
{
	new Obj:this = THIS@;

	new Obj:o_info = Obj:read#this["m_oPlayerClassInfo"];
	if (o_info == @null)
		return;

	new classname[32];
	pev(ent, pev_classname, classname, charsmax(classname));

	static model[128];
	new id = void_send#this."GetPlayerIndex"();

	if (TrieGetString(Trie:read#o_info["m_ViewModels"], classname, model, charsmax(model)))
	{
		set_pev(id, pev_viewmodel2, model);
	}

	if (TrieGetString(Trie:read#o_info["m_WeaponModels"], classname, model, charsmax(model)))
	{
		set_pev(id, pev_weaponmodel2, model);
	}
}

public PlayerClass@SetMaxSpeed()
{
	new Obj:this = THIS@;

	new Obj:o_info = Obj:read#this["m_oPlayerClassInfo"];
	if (o_info == @null)
		return;

	new pcvar;
	read_a#o_info["m_Cvars"][2..3] >> { pcvar[0..1] }

	if (pcvar)
	{
		new id = void_send#this."GetPlayerIndex"();
		
		new Float:maxspeed = get_user_maxspeed(id);
		new Float:value = get_pcvar_float(pcvar);
		set_user_maxspeed(id, (value <= 10.0) ? maxspeed * value : value);
	}
}

public PlayerClass@ChangeSound(id, channel, const sample[], Float:volume, Float:attenuation, flags, pitch)
{
	new Obj:this = THIS@;

	new Obj:o_info = Obj:read#this["m_oPlayerClassInfo"];
	if (o_info == @null)
		return 0;

	static sound[128], Array:sound_array;

	if (TrieGetCell(Trie:read#o_info["m_Sounds"], sample, sound_array))
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

	new Obj:this = THIS@;
	write#this["m_PlayerId"] << { id }
	write#this["m_oPlayerClass"] << { @null }
}

public Player@Dtor()
{
	server_print("Player@Dtor()");

	new Obj:this = THIS@;

	new Obj:o_playerclass = Obj:read#this["m_oPlayerClass"];
	if (o_playerclass != @null)
	{
		delete@(o_playerclass);
	}
}

public Player@GetPlayerClass()
{
	return read#THIS@["m_oPlayerClass"];
}

public Player@Connect()
{
	new player_id = read#THIS@["m_PlayerId"];
	server_print("Player@Connect(%d)", player_id);
}

public Player@Disconnect()
{
	new player_id = read#THIS@["m_PlayerId"];
	server_print("Player@Disconnect(%d)", player_id);
}

public Player@ChangePlayerClass(const classname[])
{
	new Obj:this = THIS@;
	new player_id = read#this["m_PlayerId"];

	new Obj:o_playerclass = Obj:read#this["m_oPlayerClass"];
	if (o_playerclass != @null)
	{
		// delete if exists
		delete@(o_playerclass);
		write#this["m_oPlayerClass"] << { @null }
	}

	o_playerclass = new<classname>(this);
	write#this["m_oPlayerClass"] << { o_playerclass }
	void_send#o_playerclass."SetPlayerProps"();

	server_print("ChangePlayerClass(%s) -> {id=%d, name=%n, obj=%d}", classname, player_id, player_id, o_playerclass);
}

/* ---------- [PlayerHandler] ---------- */

public PlayerHandler@Ctor()
{
	new Obj:o_player[MAX_PLAYERS+1] = {@null, ...};
	write_a#THIS@["m_oPlayers"][1..MaxClients] << { o_player[1..MaxClients] }
}

public PlayerHandler@Dtor()
{
	new Obj:o_player[MAX_PLAYERS+1] = {@null, ...};
	read_a#THIS@["m_oPlayers"][1..MaxClients] >> { o_player[1..MaxClients] }

	for (new i = 1; i <= MaxClients; i++)
	{
		if (o_player[i] != Obj:@null)
		{
			delete@(o_player[i]);
		}
	}
}

public PlayerHandler@Connect(id)
{
	new Obj:this = THIS@;

	new Obj:o_player;
	read_a#this["m_oPlayers"][id..id+1] >> { o_player[0..1] }

	if (o_player == @null)
	{
		o_player = new<"Player">(id);
		write_a#this["m_oPlayers"][id..id+1] << { o_player[0..1] }
		void_send#o_player."Connect"();
	}
}

public PlayerHandler@Disconnect(id)
{
	new Obj:this = THIS@;

	new Obj:o_player;
	read_a#this["m_oPlayers"][id..(id+1)] >> { o_player[0..1] }

	if (o_player != @null)
	{
		void_send#o_player."Disconnect"();

		delete@(o_player);
		o_player = @null;
		write_a#this["m_oPlayers"][id..(id+1)] << { o_player[0..1] }
	}
}

public Obj:PlayerHandler@GetPlayer(id)
{
	new Obj:o_player;
	read_a#THIS@["m_oPlayers"][id..(id+1)] >> { o_player[0..1] }

	return o_player;
}

/* ---------- [Forwards] ---------- */

public client_connectex(id)
{
	send#g_oPlayerHandler."Connect"(id);
}

public client_disconnected(id)
{
	send#g_oPlayerHandler."Disconnect"(id);
}

public OnItemDeploy_Post(ent)
{
	if (!pev_valid(ent))
		return;

	new player = get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
	if (player)
	{
		new Obj:o_player = Obj:send#g_oPlayerHandler."GetPlayer"(player);
		if (o_player == @null)
			return;

		new Obj:o_playerclass = Obj:void_send#o_player."GetPlayerClass"();
		if (o_playerclass == @null)
			return;

		send#o_playerclass."SetWeaponModel"(ent);
	}
}

public OnPlayerResetMaxSpeed_Post(id)
{
	if (is_user_alive(id))
	{
		RequestFrame("CsGetTeam", id);
		RequestFrame("PdataGetTeam", id);

		new Obj:o_player = Obj:send#g_oPlayerHandler."GetPlayer"(id);
		if (o_player == @null)
			return;

		new Obj:o_playerclass = Obj:void_send#o_player."GetPlayerClass"();
		if (o_playerclass == @null)
			return;

		void_send#o_playerclass."SetMaxSpeed"();
	}
}

public CsGetTeam(id)
{
	for (new i = 0; i < 10000000; i++)
	{
		cs_get_user_team(id);
	}
}

public PdataGetTeam(id)
{
	for (new i = 0; i < 10000000; i++)
	{
		get_pdata_int(id, 114);
	}
}

public OnEmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (is_user_alive(id))
	{
		new Obj:o_player = Obj:send#g_oPlayerHandler."GetPlayer"(id);
		if (o_player == @null)
			return FMRES_IGNORED;

		new Obj:o_playerclass = Obj:void_send#o_player."GetPlayerClass"();
		if (o_playerclass == @null)
			return FMRES_IGNORED;

		if (send#o_playerclass."ChangeSound"(id, channel, sample, volume, attn, flags, pitch))
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