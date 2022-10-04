#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <json>
#include <ctg_const>

new Array:g_PlayerClasses;
new Trie:g_PlayerClassUniqueId;
new g_PlayerClassCount;

new g_PlayerClassId[MAX_PLAYERS + 1];
new PlayerTeam:g_PlayerTeam[MAX_PLAYERS + 1];

new g_fwChangePlayerClass[Forward_e];
new g_fwRet;

public plugin_init()
{
	register_plugin("Contagion", CTG_VERSION, "colg");

	new name[50];
	for (new i = CSW_P228; i <= CSW_P90; i++)
	{
		get_weaponname(i, name, charsmax(name));
		if (name[0]) RegisterHam(Ham_Item_Deploy, name, "OnItemDeploy_P", 1, true);
	}

	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "OnPlayerResetMaxSpeed_P", 1, true);

	register_forward(FM_EmitSound, "OnEmitSound");

	g_fwChangePlayerClass[FwPre] = CreateMultiForward("ctg_OnChangePlayerClass", ET_STOP2, FP_CELL, FP_CELL);
	g_fwChangePlayerClass[FwPost] = CreateMultiForward("ctg_OnChangePlayerClass_P", ET_CONTINUE, FP_CELL, FP_CELL);
}

public plugin_natives()
{
	register_library("contagion");

	register_native("ctg_CreatePlayerClass", "native_CreatePlayerClass");
	register_native("ctg_CreatePlayerClassCvars", "native_CreatePlayerClassCvars");
	register_native("ctg_HasPlayerClassParent", "native_HasPlayerClassParent");
	register_native("ctg_GetPlayerClassData", "native_GetPlayerClassData");
	register_native("ctg_GetPlayerClassCount", "native_GetPlayerClassCount");
	register_native("ctg_FindPlayerClass", "native_FindPlayerClass");
	register_native("ctg_ChangePlayerClass", "native_ChangePlayerClass");
	register_native("ctg_GetPlayerClassSound", "native_GetPlayerClassSound");
	//register_native("ctg_GetPlayerClassModel", "native_GetPlayerClassModel");

	register_native("ctg_GetPlayerClassId", "native_GetPlayerClassId");
	register_native("ctg_SetPlayerClassId", "native_SetPlayerClassId");
	register_native("ctg_GetPlayerTeam", "native_GetPlayerTeam");
	register_native("ctg_SetPlayerTeam", "native_SetPlayerTeam");

	g_PlayerClasses = ArrayCreate(PlayerClass_e);
	g_PlayerClassUniqueId = TrieCreate();
}

// ctg_CreatePlayerClass(parent_id=CTG_NULL, const name[], const unique_id[], const desc[]="", team=Team_None, flags=0, plugin_id=CTG_NULL)
public native_CreatePlayerClass(plugin_id, num_params)
{
	new parent_id = get_param(1);
	new PlayerTeam:team = PlayerTeam:get_param(5);
	new flags = get_param(6);

	new plugin = get_param(7);
	plugin = (plugin == CTG_NULL) ? plugin_id : plugin;

	static name[32], desc[64], unique_id[32];
	get_string(2, name, charsmax(name));
	get_string(3, unique_id, charsmax(unique_id));
	get_string(4, desc, charsmax(desc));

	static data[PlayerClass_e];
	if (parent_id != CTG_NULL)
	{
		if (!(CTG_NULL < parent_id < g_PlayerClassCount))
		{
			log_error(AMX_ERR_NATIVE, "[CTG] Invalid parent class id (%d).", parent_id);
			return CTG_NULL;
		}

		ArrayGetArray(g_PlayerClasses, parent_id, data);
		data[PlCls_Parent] = parent_id;
	}
	else
	{
		data[PlCls_Cvars][PlClsCvar_Hp] = CTG_NULL;
		data[PlCls_Cvars][PlClsCvar_Gravity] = CTG_NULL;
		data[PlCls_Cvars][PlClsCvar_Speed] = CTG_NULL;
		data[PlCls_Cvars][PlClsCvar_Knockback] = CTG_NULL;

		data[PlCls_Assets][PlClsAsset_PlayerModels] = Invalid_Array;
		data[PlCls_Assets][PlClsAsset_ViewModels] = Invalid_Trie;
		data[PlCls_Assets][PlClsAsset_WeapModels] = Invalid_Trie;
		data[PlCls_Assets][PlClsAsset_Sounds] = Invalid_Trie;
		//data[PlCls_Assets][PlClsAsset_Models] = Invalid_Trie;

		data[PlCls_Parent] = CTG_NULL;
	}

	data[PlCls_Name] = name;
	data[PlCls_Desc] = desc;
	data[PlCls_UniqueId] = unique_id;
	data[PlCls_Flags] = flags;
	data[PlCls_Team] = (team == Team_None) ? data[PlCls_Team] : team;
	data[PlCls_Plugin] = plugin;

	LoadPlayerClassAssets(data[PlCls_UniqueId], data[PlCls_Assets]);

	ArrayPushArray(g_PlayerClasses, data);
	TrieSetCell(g_PlayerClassUniqueId, data[PlCls_UniqueId], g_PlayerClassCount);
	g_PlayerClassCount++;

	return (g_PlayerClassCount - 1); 
}

// ctg_CreatePlayerClassCvars(class_id, const name[], hp, Float:gravity, Float:speed, Float:knockback)
public native_CreatePlayerClassCvars(plugin_id, num_params)
{
	new class_id = get_param(1);
	if (!(CTG_NULL < class_id < g_PlayerClassCount))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] Invalid class id (%d).", class_id);
		return 0;
	}

	new name[32];
	get_string(2, name, charsmax(name));

	new hp = get_param(3);
	new Float:gravity = get_param_f(4);
	new Float:speed = get_param_f(5);
	new Float:knockback = get_param_f(6);

	static data[PlayerClass_e];
	ArrayGetArray(g_PlayerClasses, class_id, data);

	static cvar_name[64], cvar_value[32];
	formatex(cvar_name, charsmax(cvar_name), "ctg_%s_hp", name);
	num_to_str(hp, cvar_value, charsmax(cvar_value));
	data[PlCls_Cvars][PlClsCvar_Hp] = create_cvar(cvar_name, cvar_value);

	formatex(cvar_name, charsmax(cvar_name), "ctg_%s_gravity", name);
	float_to_str(gravity, cvar_value, charsmax(cvar_value));
	data[PlCls_Cvars][PlClsCvar_Gravity] = create_cvar(cvar_name, cvar_value);

	formatex(cvar_name, charsmax(cvar_name), "ctg_%s_speed", name);
	float_to_str(speed, cvar_value, charsmax(cvar_value));
	data[PlCls_Cvars][PlClsCvar_Speed] = create_cvar(cvar_name, cvar_value);

	formatex(cvar_name, charsmax(cvar_name), "ctg_%s_knockback", name);
	float_to_str(knockback, cvar_value, charsmax(cvar_value));
	data[PlCls_Cvars][PlClsCvar_Knockback] = create_cvar(cvar_name, cvar_value);

	ArraySetArray(g_PlayerClasses, class_id, data);
	return 1;
}

// ctg_HasPlayerClassParent(start_id, parent_id, max_depth=-1)
public native_HasPlayerClassParent(plugin_id, num_params)
{
	new start_id = get_param(1);
	if (!(CTG_NULL < start_id < g_PlayerClassCount))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] Invalid start class id (%d).", start_id);
		return 0;
	}

	new parent_id = get_param(2);
	if (!(CTG_NULL < parent_id < g_PlayerClassCount))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] Invalid parent class id (%d).", parent_id);
		return 0;
	}

	static data[PlayerClass_e];

	new max_depth = get_param(3);
	new depth = 0;
	new class_id = start_id;

	do {
		if (class_id == parent_id)
			return 1;
		
		ArrayGetArray(g_PlayerClasses, class_id, data);
		class_id = data[PlCls_Parent];

	} while ((max_depth == -1 || depth++ < max_depth) && class_id != CTG_NULL)

	return 0;
}

// ctg_GetPlayerClassData(class_id, data[PlayerClass_e])
public native_GetPlayerClassData(plugin_id, num_params)
{
	new class_id = get_param(1);
	if (!(CTG_NULL < class_id < g_PlayerClassCount))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] Invalid class id (%d).", class_id);
		return 0;
	}

	static data[PlayerClass_e];
	ArrayGetArray(g_PlayerClasses, class_id, data);
	set_array(2, data, PlayerClass_e);
	return 1;
}

// ctg_GetPlayerClassCount()
public native_GetPlayerClassCount(plugin_id, num_params)
{
	return g_PlayerClassCount;
}

// ctg_FindPlayerClass(const unique_id[])
public native_FindPlayerClass(plugin_id, num_params)
{
	new unique_id[32];
	get_string(1, unique_id, charsmax(unique_id));

	new class_id = CTG_NULL;
	if (TrieGetCell(g_PlayerClassUniqueId, unique_id, class_id))
		return class_id;

	return CTG_NULL;
}

// ctg_ChangePlayerClass(id, class_id=CTG_NULL, const classname[]="")
public native_ChangePlayerClass(plugin_id, num_params)
{
	new id = get_param(1);
	new class_id = get_param(2);

	new classname[32];
	get_string(3, classname, charsmax(classname));

	if (class_id == CTG_NULL && classname[0])
	{
		class_id = FindPlayerClass(classname);

		if (class_id == CTG_NULL)
		{
			log_error(AMX_ERR_NATIVE, "[CTG] Invalid class name (%s).", classname);
			return 0;
		}
	}
	else if (!(CTG_NULL < class_id < g_PlayerClassCount))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] Invalid class id (%d).", class_id);
		return 0;
	}

	ChangePlayerClass(id, class_id);
	return 1;
}

public Array:native_GetPlayerClassSound()
{
	new class_id = get_param(1);
	if (!(CTG_NULL < class_id < g_PlayerClassCount))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] Invalid class id (%d).", class_id);
		return Invalid_Array;
	}

	static key[64], Array:array;
	get_string(2, key, charsmax(key));

	static data[PlayerClass_e];
	ArrayGetArray(g_PlayerClasses, class_id, data);

	if (TrieGetCell(data[PlCls_Assets][PlClsAsset_Sounds], key, array))
	{
		return array;
	}

	return Invalid_Array;
}
/*
public native_GetPlayerClassModel()
{
	new class_id = get_param(1);
	if (!(CTG_NULL < class_id < g_PlayerClassCount))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] Invalid class id (%d).", class_id);
		return 0;
	}

	static key[64], value[100];
	get_string(2, key, charsmax(key));

	static data[PlayerClass_e];
	ArrayGetArray(g_PlayerClasses, class_id, data);

	if (TrieGetString(data[PlCls_Assets][PlClsAsset_Models], key, value, charsmax(value)))
	{
		set_string(3, value, get_param(4));
		return 1;
	}

	return 0;
}
*/
public native_GetPlayerClassId()
{
	new id = get_param(1);
	if (!(1 <= id <= MaxClients))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] player index (%d) out of range.", id);
		return CTG_NULL;
	}

	return g_PlayerClassId[id];
}

public native_SetPlayerClassId()
{
	new id = get_param(1);
	if (!(1 <= id <= MaxClients))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] player index (%d) out of range.", id);
		return 0;
	}

	new value = get_param(2);

	g_PlayerClassId[id] = value;
	return 1;
}

public PlayerTeam:native_GetPlayerTeam()
{
	new id = get_param(1);
	if (!(1 <= id <= MaxClients))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] player index (%d) out of range.", id);
		return Team_None;
	}

	return g_PlayerTeam[id];
}

public native_SetPlayerTeam()
{
	new id = get_param(1);
	if (!(1 <= id <= MaxClients))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] player index (%d) out of range.", id);
		return 0;
	}

	new team = get_param(2);

	g_PlayerTeam[id] = PlayerTeam:team;
	return 1;
}


public OnItemDeploy_P(ent)
{
	if (!pev_valid(ent))
		return;

	new player = get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
	if (player && g_PlayerClassId[player] != CTG_NULL)
	{
		new classname[32];
		pev(ent, pev_classname, classname, charsmax(classname));

		static data[PlayerClass_e], model[128];
		ArrayGetArray(g_PlayerClasses, g_PlayerClassId[player], data);

		if (data[PlCls_Assets][PlClsAsset_ViewModels] != Invalid_Trie 
			&& TrieGetString(data[PlCls_Assets][PlClsAsset_ViewModels], classname, model, charsmax(model)))
		{
			set_pev(player, pev_viewmodel2, model);
		}

		if (data[PlCls_Assets][PlClsAsset_WeapModels] != Invalid_Trie
			&& TrieGetString(data[PlCls_Assets][PlClsAsset_WeapModels], classname, model, charsmax(model)))
		{
			set_pev(player, pev_weaponmodel2, model);
		}
	}
}

public OnPlayerResetMaxSpeed_P(id)
{
	if (is_user_alive(id) && g_PlayerClassId[id] != CTG_NULL)
	{
		static data[PlayerClass_e];
		ArrayGetArray(g_PlayerClasses, g_PlayerClassId[id], data);

		if (data[PlCls_Cvars][PlClsCvar_Speed] != CTG_NULL) // has speed
		{
			new Float:maxspeed = get_user_maxspeed(id);
			new Float:value = get_pcvar_float(data[PlCls_Cvars][PlClsCvar_Speed]);
			set_user_maxspeed(id, (value <= 10.0) ? maxspeed * value : value);
		}
	}
}

public OnEmitSound(id, channel, const sample[], Float:volume, Float:attenuation, flags, pitch)
{
	if (is_user_alive(id) && g_PlayerClassId[id] != CTG_NULL)
	{
		static data[PlayerClass_e], sound[128], Array:sound_array;
		ArrayGetArray(g_PlayerClasses, g_PlayerClassId[id], data);

		if (data[PlCls_Assets][PlClsAsset_Sounds] != Invalid_Trie && TrieGetCell(data[PlCls_Assets][PlClsAsset_Sounds], sample, sound_array))
		{
			ArrayGetString(sound_array, random(ArraySize(sound_array)), sound, charsmax(sound));
			emit_sound(id, channel, sound, volume, attenuation, flags, pitch);
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public client_disconnected(id)
{
	g_PlayerClassId[id] = CTG_NULL;
	g_PlayerTeam[id] = Team_None;
}

FindPlayerClass(const unique_id[])
{
	new class_id;
	if (TrieGetCell(g_PlayerClassUniqueId, unique_id, class_id))
		return class_id;
	
	return CTG_NULL;
}

LoadPlayerClassAssets(const unique_id[], data[PlayerClassAssets_e])
{
	static path[100];
	get_configsdir(path, charsmax(path));

	format(path, charsmax(path), "%s/contagion/playerclass/%s.json", path, unique_id);

	new JSON:json = json_parse(path, true, true);
	if (json != Invalid_JSON)
	{
		static key[128], value[128];

		new JSON:playermodels = json_object_get_value(json, "playermodels");
		if (playermodels != Invalid_JSON)
		{
			data[PlClsAsset_PlayerModels] = ArrayCreate(32);
			for (new i = json_array_get_count(playermodels) - 1; i >= 0; i--)
			{
				json_array_get_string(playermodels, i, value, charsmax(value));
				ArrayPushString(data[PlClsAsset_PlayerModels], value);
				PrecachePlayerModel(value);
			}
			json_free(playermodels);
		}

		new JSON:viewmodels = json_object_get_value(json, "viewmodels");
		if (viewmodels != Invalid_JSON)
		{
			new JSON:vmodel_val = Invalid_JSON;
			data[PlClsAsset_ViewModels] = TrieCreate();
			for (new i = json_object_get_count(viewmodels) - 1; i >= 0; i--)
			{
				json_object_get_name(viewmodels, i, key, charsmax(key));
				vmodel_val = json_object_get_value_at(viewmodels, i);
				json_get_string(vmodel_val, value, charsmax(value));
				json_free(vmodel_val);
				TrieSetString(data[PlClsAsset_ViewModels], key, value);
				if (value[0])
					precache_model(value);
			}
			json_free(viewmodels);
		}

		new JSON:weapmodels = json_object_get_value(json, "weaponmodels");
		if (weapmodels != Invalid_JSON)
		{
			new JSON:pmodel_val = Invalid_JSON;
			data[PlClsAsset_WeapModels] = TrieCreate();
			for (new i = json_object_get_count(weapmodels) - 1; i >= 0; i--)
			{
				json_object_get_name(weapmodels, i, key, charsmax(key));
				pmodel_val = json_object_get_value_at(weapmodels, i);
				json_get_string(pmodel_val, value, charsmax(value));
				json_free(pmodel_val);
				TrieSetString(data[PlClsAsset_WeapModels], key, value);
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
			data[PlClsAsset_Sounds] = TrieCreate();

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
				TrieSetCell(data[PlClsAsset_Sounds], key, sound_array);
			}
			json_free(sounds);
		}
/*
		new JSON:models = json_object_get_value(json, "models");
		if (models != Invalid_JSON)
		{
			new JSON:model_val = Invalid_JSON;
			data[PlClsAsset_Models] = TrieCreate();
			for (new i = json_object_get_count(models) - 1; i >= 0; i--)
			{
				json_object_get_name(models, i, key, charsmax(key));
				model_val = json_object_get_value_at(models, i);
				json_get_string(model_val, value, charsmax(value));
				json_free(model_val);
				TrieSetString(data[PlClsAsset_Models], key, value);
				if (value[0])
					precache_model(value);
			}
			json_free(models);
		}
*/
		json_free(json);
	}
}

ChangePlayerClass(id, class_id)
{
	ExecuteForward(g_fwChangePlayerClass[FwPre], g_fwRet, id, class_id);

	if (g_fwRet >= PLUGIN_HANDLED)
		return;
	
	static data[PlayerClass_e], buffer[32];
	ArrayGetArray(g_PlayerClasses, class_id, data);

	g_PlayerTeam[id] = data[PlCls_Team];
	g_PlayerClassId[id] = class_id;

	if (data[PlCls_Cvars][PlClsCvar_Hp] != CTG_NULL) // has hp
		set_user_health(id, get_pcvar_num(data[PlCls_Cvars][PlClsCvar_Hp]));
	
	if (data[PlCls_Cvars][PlClsCvar_Gravity] != CTG_NULL) // has gravity
		set_user_gravity(id, get_pcvar_float(data[PlCls_Cvars][PlClsCvar_Gravity]));

	if (data[PlCls_Assets][PlClsAsset_PlayerModels] != Invalid_Array) // has model
	{
		ArrayGetString(data[PlCls_Assets][PlClsAsset_PlayerModels], random(ArraySize(data[PlCls_Assets][PlClsAsset_PlayerModels])), buffer, charsmax(buffer));
		cs_set_user_model(id, buffer);
	}

	ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id); // update maxspeed

	ExecuteForward(g_fwChangePlayerClass[FwPost], g_fwRet, id, class_id);
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