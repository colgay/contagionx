#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <json>
#include <oo>

#include <ctg_const>
#include <ctg_util>

#define DEBUG

new PlayerClass:g_objPlayerClass[MAX_PLAYERS + 1] = {@null, ...};

new g_fwChangePlayerClass[ForwardType];
new g_fwRet;

public oo_init()
{
	// Player Class Information
	oo_class("PlayerClassInfo")
	{
		new const cl[] = "PlayerClassInfo";
		oo_var(cl, "name", STRLEN_SHORT); // string
		oo_var(cl, "desc", STRLEN_NORMAL); // string
		oo_var(cl, "models", 1); // Array:
		oo_var(cl, "v_models", 1); // Trie:
		oo_var(cl, "p_models", 1); // Trie:
		oo_var(cl, "sounds", 1); // Trie:
		oo_var(cl, "cvars", 1); // Trie:

		// (const name[], const desc[])
		oo_ctor(cl, "Ctor", @string, @string);
		oo_dtor(cl, "Dtor");

		// (const prefix[], const name[], const string[]);
		oo_mthd(cl, "CreateCvar", @string, @string, @string, @cell);
		oo_mthd(cl, "GetCvar", @string); // (const name[])
		oo_mthd(cl, "GetCvarFloat", @string); // Float:(const name[])
		oo_mthd(cl, "GetCvarString", @string, @stringex, @cell); // (const name[], output[], maxlen)
		oo_mthd(cl, "LoadJson", @string); // bool:(const filename[])
	}

	// Player Class
	oo_class("PlayerClass");
	{
		new const cl[] = "PlayerClass";
		oo_var(cl, "player_index", 1);

		oo_ctor(cl, "Ctor", @cell); // (player_index)
		oo_dtor(cl, "Dtor");

		oo_mthd(cl, "AssignProps");
		oo_mthd(cl, "OnClassChange", @cell);  // (id, bool:assign_props)
		oo_mthd(cl, "ChangeWeaponModel", @cell); // bool:(entity)
		oo_mthd(cl, "ChangeMaxSpeed"); // bool:()
		oo_mthd(cl, "GetClassInfo"); // PlayerClasInfo:()

		// bool:(id, channel, const sample[], Float:vol, Float:attn, flags, pitch)
		oo_mthd(cl, "ChangeSound", @cell, @cell, @string, @float, @float, @cell, @cell);
	}
}

public plugin_init()
{
	register_plugin("[CTG] Player Class", CTG_VERSION, "holla");

	register_forward(FM_EmitSound, "OnEmitSound");
	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "OnPlayerResetMaxspeed_Post", 1);
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", 1)

	static weaponname[STRLEN_SHORT];
	for (new i = CSW_P228; i <= CSW_P90; i++)
	{
		get_weaponname(i, weaponname, charsmax(weaponname));
		if (weaponname[0])
			RegisterHam(Ham_Item_Deploy, weaponname, "OnItemDeploy_Post", 1);
	}

	RegisterHam(Ham_Touch, "weaponbox", "OnWeaponTouch");
	RegisterHam(Ham_Touch, "weapon_shield", "OnWeaponTouch");
	RegisterHam(Ham_Touch, "armoury_entity", "OnWeaponTouch");

	g_fwChangePlayerClass[FW_PRE] = CreateMultiForward("ctg_on_playerclass_change", ET_CONTINUE, FP_CELL, FP_STRING);
	g_fwChangePlayerClass[FW_POST] = CreateMultiForward("ctg_on_playerclass_change_post", ET_IGNORE, FP_CELL, FP_STRING);
}

// ---------- [AMXX Natives] ----------

public plugin_natives()
{
	register_library("ctg_playerclass");

	register_native("ctg_playerclass_change", "native_playerclass_change");
	register_native("ctg_playerclass_get", "native_playerclass_get");
	register_native("ctg_playerclass_is", "native_playerclass_is");
}

// native PlayerClass:ctg_playerclass_change(id, const class[])
public PlayerClass:native_playerclass_change(plugin_id, num_params)
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return @null;
	}

	static class[STRLEN_SHORT];
	get_string(2, class, charsmax(class));

	if (class[0] == '^0')
	{
		if (g_objPlayerClass[id] != @null)
		{
			oo_delete(g_objPlayerClass[id]);
			g_objPlayerClass[id] = @null;
		}

		return @null;
	}

	if (!oo_class_exists(class))
	{
		log_error(AMX_ERR_NATIVE, "Class (%s) not exists", class);
		return @null;
	}

	if (!oo_subclass_of(class, "PlayerClass"))
	{
		log_error(AMX_ERR_NATIVE, "Class (%s) is not the subclass of (PlayerClass)", class);
		return @null;
	}

	return ChangePlayerClass(id, class, bool:get_param(3));
}

// native PlayerClass:ctg_playerclass_get_obj(id)
public PlayerClass:native_playerclass_get(plugin_id, num_params)
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return @null;
	}

	return g_objPlayerClass[id];
}

public bool:native_playerclass_is(plugin_id, num_params)
{
	new id = get_param(1);
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "Player (%d) not connected", id);
		return @null;
	}

	static class[STRLEN_SHORT];
	get_string(2, class, charsmax(class));

	if (g_objPlayerClass[id] == @null)
		return class[0] == '^0';

	return oo_isa(g_objPlayerClass[id], class, bool:get_param(3));
}

// ---------- [AMXX Forwards] ----------

public client_disconnected(id)
{
	if (g_objPlayerClass[id] != @null)
	{
		oo_delete(g_objPlayerClass[id]);
		g_objPlayerClass[id] = @null;
	}
}

// Ham_CS_Player_ResetMaxSpeed
public OnPlayerResetMaxspeed_Post(id)
{
	new PlayerClass:class_obj = g_objPlayerClass[id];
	if (class_obj != @null)
		return oo_call(class_obj, "ChangeMaxSpeed") ? HAM_HANDLED : HAM_IGNORED;

	return HAM_IGNORED;
}

public OnPlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return;
	
	new PlayerClass:class_obj = g_objPlayerClass[id];
	if (class_obj != @null)
		oo_call(class_obj, "AssignProps")
}

// Ham_Item_Deploy
public OnItemDeploy_Post(entity)
{
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	new id = get_ent_data_entity(entity, "CBasePlayerItem", "m_pPlayer");
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	new PlayerClass:class_obj = g_objPlayerClass[id];
	if (class_obj != @null)
		return oo_call(class_obj, "ChangeWeaponModel", entity) ? FMRES_HANDLED : FMRES_IGNORED;

	return FMRES_IGNORED;
}

// FM_EmitSound
public OnEmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	new PlayerClass:class_obj = g_objPlayerClass[id];
	if (class_obj != @null)
		return oo_call(class_obj, "ChangeSound", id, channel, sample, volume, attn, flags, pitch) ? FMRES_SUPERCEDE : FMRES_IGNORED;

	return FMRES_IGNORED;
}

public OnWeaponTouch(ent, toucher)
{
	if (!is_user_alive(toucher))
		return HAM_IGNORED;

	new PlayerClass:class_obj = g_objPlayerClass[toucher];
	if (class_obj != @null)
		return oo_call(class_obj, "CanPickupItem") ? HAM_IGNORED : HAM_SUPERCEDE;

	return HAM_IGNORED;
}

// ---------- [PlayerClassInfo] ----------

// Constructor
public PlayerClassInfo@Ctor(const name[], const desc[])
{
#if defined DEBUG
	server_print("PlayerClassInfo@Ctor(%s, %s)", name, desc);
#endif

	new this = @this;

	oo_set_str(this, "name", name);
	oo_set_str(this, "desc", desc);

	oo_set(this, "models", ArrayCreate(32));
	oo_set(this, "v_models", TrieCreate());
	oo_set(this, "p_models", TrieCreate());
	oo_set(this, "sounds", TrieCreate());
	oo_set(this, "cvars", TrieCreate());
}

// Destructor
public PlayerClassInfo@Dtor()
{
#if defined DEBUG
	server_print("PlayerClassInfo@Dtor()");
#endif

	new this = @this;

	new Array:models_a = Array:oo_get(this, "models");
	new Trie:vmodels_t = Trie:oo_get(this, "v_models");
	new Trie:pmodels_t = Trie:oo_get(this, "p_models");
	new Trie:sounds_t = Trie:oo_get(this, "sounds");
	new Trie:cvars_t = Trie:oo_get(this, "cvars");

	// destroy leftover sound arrays
	new TrieIter:iter = TrieIterCreate(sounds_t);
	{
		new Array:sounds_a = Invalid_Array;

		while (!TrieIterEnded(iter))
		{
			TrieIterGetCell(iter, sounds_a);
			ArrayDestroy(sounds_a);
			TrieIterNext(iter);
		}

		TrieIterDestroy(iter);
	}

	ArrayDestroy(models_a);
	TrieDestroy(vmodels_t);
	TrieDestroy(pmodels_t);
	TrieDestroy(sounds_t);
	TrieDestroy(cvars_t);
}

// Create a cvar for a player class
public PlayerClassInfo@CreateCvar(const prefix[], const name[], const string[], flags)
{
#if defined DEBUG
	server_print("PlayerClassInfo@CreateCvar(%s, %s, %s, %d)", prefix, name, string, flags);
#endif

	new this = @this;

	static cvar_name[STRLEN_NORMAL];
	formatex(cvar_name, charsmax(cvar_name), "ctg_%s_%s", prefix, name); // actual cvar name

	new pcvar = create_cvar(cvar_name, string, flags);
	new Trie:cvars_t = Trie:oo_get(this, "cvars");

	TrieSetCell(cvars_t, name, pcvar);
	return pcvar;
}

// Get cvar value of a player class (integer)
public PlayerClassInfo@GetCvar(const name[])
{
#if defined DEBUG
	server_print("PlayerClassInfo@GetCvar(%s)", name);
#endif

	new this = @this;
	new Trie:cvars_t = Trie:oo_get(this, "cvars");
	new pcvar;

	if (TrieGetCell(cvars_t, name, pcvar))
		return get_pcvar_num(pcvar);

	return 0;
}

// Get cvar value of a player class (float)
public Float:PlayerClassInfo@GetCvarFloat(const name[])
{
#if defined DEBUG
	server_print("PlayerClassInfo@GetCvarFloat(%s)", name);
#endif

	new this = @this;
	new Trie:cvars_t = Trie:oo_get(this, "cvars");
	new pcvar;

	if (TrieGetCell(cvars_t, name, pcvar))
		return get_pcvar_float(pcvar);

	return 0.0;
}

// Get cvar value of a player class (string)
public PlayerClassInfo@GetCvarString(const name[], output[], maxlen)
{
#if defined DEBUG
	server_print("PlayerClassInfo@GetCvarString(%s)", name);
#endif

	new this = @this;
	new Trie:cvars_t = Trie:oo_get(this, "cvars");
	new pcvar;

	if (TrieGetCell(cvars_t, name, pcvar))
		return get_pcvar_string(pcvar, output, maxlen);

	return 0;
}

// Load json file for a player class
public bool:PlayerClassInfo@LoadJson(const filename[])
{
#if defined DEBUG
	server_print("PlayerClassInfo@LoadJson(%s)", filename);
#endif

	new this = @this;

	static filepath[STRLEN_LONG];
	get_configsdir(filepath, charsmax(filepath));
	format(filepath, charsmax(filepath), "%s/contagion/playerclass/%s.json", filepath, filename);

	new JSON:json = json_parse(filepath, true, true);
	if (json == Invalid_JSON) // invalid json file
		return false;
	
	static key[STRLEN_LONG], value[STRLEN_LONG];

	// player models
	new JSON:models_j = json_object_get_value(json, "models");
	if (models_j != Invalid_JSON)
	{
		new Array:models_a = Array:oo_get(this, "models");
		for (new i = json_array_get_count(models_j) - 1; i >= 0; i--)
		{
			json_array_get_string(models_j, i, value, charsmax(value));
			ArrayPushString(models_a, value);
			PrecachePlayerModel(value);
		}
		json_free(models_j);
	}

	new JSON:vmodels_j = json_object_get_value(json, "v_models");
	if (vmodels_j != Invalid_JSON)
	{
		new JSON:value_j = Invalid_JSON;
		new Trie:vmodels_t = Trie:oo_get(this, "v_models");
		for (new i = json_object_get_count(vmodels_j) - 1; i >= 0; i--)
		{
			json_object_get_name(vmodels_j, i, key, charsmax(key));
			value_j = json_object_get_value_at(vmodels_j, i);
			json_get_string(value_j, value, charsmax(value));
			json_free(value_j);
			TrieSetString(vmodels_t, key, value);
			if (file_exists(value)) // safe check
				precache_model(value);
		}
		json_free(vmodels_j);
	}

	new JSON:pmodels_j = json_object_get_value(json, "p_models");
	if (pmodels_j != Invalid_JSON)
	{
		new JSON:value_j = Invalid_JSON;
		new Trie:pmodels_t = Trie:oo_get(this, "p_models");
		for (new i = json_object_get_count(pmodels_j) - 1; i >= 0; i--)
		{
			json_object_get_name(pmodels_j, i, key, charsmax(key));
			value_j = json_object_get_value_at(pmodels_j, i);
			json_get_string(value_j, value, charsmax(value));
			json_free(value_j);
			TrieSetString(pmodels_t, key, value);
			if (file_exists(value)) // safe check
				precache_model(value);
		}
		json_free(pmodels_j);
	}

	new JSON:sounds_j = json_object_get_value(json, "sounds");
	if (sounds_j != Invalid_JSON)
	{
		new Array:sounds_a = Invalid_Array;
		new JSON:value_j = Invalid_JSON;
		new Trie:sounds_t = Trie:oo_get(this, "sounds");
		for (new i = json_object_get_count(sounds_j) - 1; i >= 0; i--)
		{
			json_object_get_name(sounds_j, i, key, charsmax(key));
			value_j = json_object_get_value_at(sounds_j, i);
			if (TrieGetCell(sounds_t, key, sounds_a))
			{
				ArrayDestroy(sounds_a);
				TrieDeleteKey(sounds_t, key);
			}
			sounds_a = ArrayCreate(STRLEN_LONG);
			for (new i = json_array_get_count(value_j) - 1; i >= 0; i--)
			{
				json_array_get_string(value_j, i, value, charsmax(value));
				ArrayPushString(sounds_a, value);
				precache_sound(value);
			}
			json_free(value_j);
			if (ArraySize(sounds_a) > 0)
				TrieSetCell(sounds_t, key, sounds_a);
			else
				ArrayDestroy(sounds_a);
		}
		json_free(sounds_j);
	}

	json_free(json);

	server_print("Loaded json (%s)", filepath);
	return true;
}

// ---------- [PlayerClass] ----------

// Constructor
public PlayerClass@Ctor(player_index)
{
#if defined DEBUG
	server_print("PlayerClass@Ctor(%d)", player_index);
#endif

	new this = @this;
	oo_set(this, "player_index", player_index);
}

// Destructor
public PlayerClass@Dtor()
{
#if defined DEBUG
	server_print("PlayerClass@Dtor()");
#endif
}

// Get class information object of the player class
public PlayerClass@GetClassInfo()
{
#if defined DEBUG
	server_print("PlayerClass@GetClassInfo()");
#endif

	return @null;
}

// Assign player properties
public bool:PlayerClass@AssignProps()
{
#if defined DEBUG
	server_print("PlayerClass@AssignProps()");
#endif

	new this = @this;

	new PlayerClassInfo:classinfo_obj = any:oo_call(this, "GetClassInfo");
	if (classinfo_obj != @null) // no object assigned
		return false;

	new player = oo_get(this, "player_index");
	if (!is_user_alive(player)) // player not alive
		return false;
	
	new Trie:cvars_t = any:oo_get(classinfo_obj, "cvars");
	new pcvar;
	
	// check health cvar
	if (TrieGetCell(cvars_t, "hp", pcvar))
		set_pev(player, pev_health, get_pcvar_float(pcvar));
	
	// check gravity cvar
	if (TrieGetCell(cvars_t, "gravity", pcvar))
		set_pev(player, pev_gravity, get_pcvar_float(pcvar));
	
	// check speed cvar
	if (TrieGetCell(cvars_t, "speed", pcvar))
		ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, player);

	// check models array
	new Array:models_a = any:oo_get(classinfo_obj, "models");
	if (ArraySize(models_a) > 0)
	{
		static modelname[STRLEN_SHORT];
		ArrayGetRandomString(models_a, modelname, charsmax(modelname));
		cs_set_user_model(player, modelname);
	}

	new activeitem = get_ent_data_entity(player, "CBasePlayer", "m_pActiveItem");
	if (pev_valid(activeitem)) // valid weapon entity
	{
		static classname[STRLEN_SHORT];
		pev(activeitem, pev_classname, classname, charsmax(classname));

		// update weapon model?
		if (TrieKeyExists(Trie:oo_get(classinfo_obj, "v_models"), classname) || TrieKeyExists(Trie:oo_get(classinfo_obj, "p_models"), classname))
			ExecuteHamB(Ham_Item_Deploy, activeitem);
	}

	return true;
}

// Change player weapon model
public bool:PlayerClass@ChangeWeaponModel(entity)
{
#if defined DEBUG
	server_print("PlayerClass@ChangeWeaponModel(%d)", entity);
#endif

	new this = @this;

	new PlayerClassInfo:classinfo_obj = any:oo_call(this, "GetClassInfo");
	if (classinfo_obj != @null) // no object assigned
		return false;

	static classname[STRLEN_SHORT];
	pev(entity, pev_classname, classname, charsmax(classname));

	new player = oo_get(this, "player_index");
	if (!is_user_alive(player)) // player not alive
		return false;

	new bool:has_changed = false;
	static modelpath[STRLEN_LONG], Trie:models_t;
	
	// check v_model
	models_t = any:oo_get(classinfo_obj, "v_models");
	if (TrieGetString(models_t, classname, modelpath, charsmax(modelpath)))
	{
		set_pev(player, pev_viewmodel2, modelpath);
		has_changed = true;
	}

	// check p_model
	models_t = any:oo_get(classinfo_obj, "p_models");
	if (TrieGetString(models_t, classname, modelpath, charsmax(modelpath)))
	{
		set_pev(player, pev_weaponmodel2, modelpath);
		has_changed = true;
	}

	return has_changed;
}

// Change player maxspeed
public bool:PlayerClass@ChangeMaxSpeed()
{
#if defined DEBUG
	server_print("PlayerClass@ChangeMaxSpeed()");
#endif

	new this = @this;

	new PlayerClassInfo:classinfo_obj = any:oo_call(this, "GetClassInfo");
	if (classinfo_obj != @null) // no object assigned
		return false;

	new Float:speed_val = Float:oo_call(classinfo_obj, "GetCvarFloat", "speed");
	if (speed_val <= 0.0) // no cvar created
		return false;

	new player = oo_get(this, "player_index");
	if (!is_user_alive(player)) // player not alive
		return false;
	
	new Float:curr_speed;
	pev(player, pev_maxspeed, curr_speed);
	set_pev(player, pev_maxspeed, (speed_val <= 5.0) ? curr_speed * speed_val : speed_val);
	return true;
}

// Change player sounds
public bool:PlayerClass@ChangeSound(id, channel, const sample[], Float:vol, Float:attn, flags, pitch)
{
#if defined DEBUG
	server_print("PlayerClass@ChangeSound(%d, %d, %s, %f, %f, %d, %d)", id, channel, sample, vol, attn, flags, pitch);
#endif

	new this = @this;

	new PlayerClassInfo:classinfo_obj = any:oo_call(this, "GetClassInfo");
	if (classinfo_obj != @null) // no object assigned
		return false;

	new Array:sounds_a = Invalid_Array;
	new Trie:sounds_t = any:oo_get(classinfo_obj, "sounds");

	if (!TrieGetCell(sounds_t, sample, sounds_a)) // no sound replacement
		return false;
	
	if (sounds_a == Invalid_Array) // invalid sound array
		return false;
	
	new player = oo_get(this, "player_index");
	if (!is_user_alive(player)) // player not alive
		return false;

	static soundpath[STRLEN_LONG];
	ArrayGetRandomString(sounds_a, soundpath, charsmax(soundpath));
	emit_sound(player, channel, soundpath, vol, attn, flags, pitch);

#if defined DEBUG
	server_print("sound changed to (%s)", soundpath);
#endif
	return true;
}

public PlayerClass@OnClassChange(bool:assign_props)
{
	#if defined DEBUG
		server_print("PlayerClass@OnClassChange()");
	#endif

	if (assign_props)
		oo_call(@this, "AssignProps");
}

// ---------- [Utilities] ----------

// Change player class
PlayerClass:ChangePlayerClass(id, const class[], bool:assign_props)
{
	//if (!oo_class_exists(class) || !oo_subclass_of(class, "PlayerClass"))
	//	return @null;

	// pre
	ExecuteForward(g_fwChangePlayerClass[FW_PRE], g_fwRet, id, class);

	// stop forward
	if (g_fwRet >= PLUGIN_HANDLED)
		return @null;

	// check if object exists
	if (g_objPlayerClass[id] != @null)
	{
		oo_delete(g_objPlayerClass[id]); // delete object before we create a new one
		g_objPlayerClass[id] = @null;
	}

	// new object
	g_objPlayerClass[id] = oo_new(class, id);

	oo_call(g_objPlayerClass[id], "OnClassChange", assign_props);

	// post
	ExecuteForward(g_fwChangePlayerClass[FW_POST], g_fwRet, id, class);
	return g_objPlayerClass[id];
}