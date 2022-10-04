#include <amxmodx>
#include <amxmisc>
#include <json>
#include <oo>

public oo_init()
{
	new Class:pci = oo_class("PlayerClassInfo");
	{
		oo_var(pci, DT_ARRAY[32], "m_Name");
		oo_var(pci, DT_ARRAY[32], "m_Desc");
		oo_var(pci, DT_CELL, "m_Team");
		oo_var(pci, DT_CELL, "m_Flags");
		oo_var(pci, DT_CELL, "m_Models"); // Array:
		oo_var(pci, DT_CELL, "m_ViewModels"); // Trie:
		oo_var(pci, DT_CELL, "m_WeaponModels"); // Trie:
		oo_var(pci, DT_CELL, "m_Sounds"); // Trie:
		oo_var(pci, DT_ARRAY[4], "m_Cvars");

		// (const filename[], const name[], const desc[], team, flags)
		oo_method(pci, MT_CTOR, "Ctor", FP_STRING, FP_STRING, FP_STRING, FP_CELL, FP_CELL);
		oo_method(pci, MT_DTOR, "Dtor");

		// (const cvar_prefix[], hp, Float:gravity, Float:speed, Float:knockback)
		oo_method(pci, MT_METHOD, "CreateCvars", FP_STRING, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
		oo_method(pci, MT_METHOD, "LoadJson", FP_STRING); // (const filename[])
	}
}

public plugin_init()
{
	register_plugin("[CTG] Player Class Info", "0.1", "colg");
}

public PlayerClassInfo@Ctor(const filename[], const name[], const desc[], team, flags)
{
	new Object:this = oo_this();

	oo_set(this, "m_Name", name);
	oo_set(this, "m_Desc", desc);
	oo_set(this, "m_Team", team);
	oo_set(this, "m_Flags", flags);

	oo_set(this, "m_Models", ArrayCreate(32));
	oo_set(this, "m_ViewModels", TrieCreate());
	oo_set(this, "m_WeaponModels", TrieCreate());
	oo_set(this, "m_Sounds", TrieCreate());

	oo_call(this, "LoadJson", filename);

	server_print("haha: %s, name: %s", filename, name);
}

public PlayerClassInfo@Dtor()
{
	new Object:this = oo_this();

	new Array:models = Array:oo_get(this, "m_Models");
	new Trie:viewmodels = Trie:oo_get(this, "m_ViewModels");
	new Trie:weaponmodels = Trie:oo_get(this, "m_WeaponModels");
	new Trie:sounds = Trie:oo_get(this, "m_Sounds");

	ArrayDestroy(models);
	TrieDestroy(viewmodels);
	TrieDestroy(weaponmodels);

	new TrieIter:iter = TrieIterCreate(sounds);
	{
		new Array:sound_array;

		while (!TrieIterEnded(iter))
		{
			TrieIterGetCell(iter, sound_array);
			ArrayDestroy(sound_array);
			TrieIterNext(iter);
		}
	}
	TrieIterDestroy(iter);

	TrieDestroy(sounds);
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

	oo_set(oo_this(), "m_Cvars", pcvars);
}

public PlayerClassInfo@LoadJson(const filename[])
{
	new Object:this = oo_this();

	static path[100];
	get_configsdir(path, charsmax(path));
	format(path, charsmax(path), "%s/contagion/playerclass/%s.json", path, filename);

	server_print("ha: %s", filename);

	new JSON:json = json_parse(path, true, true);
	if (json != Invalid_JSON)
	{
		static key[128], value[128];

		new JSON:playermodels = json_object_get_value(json, "models");
		if (playermodels != Invalid_JSON)
		{
			new Array:aModels = Array:oo_get(this, "m_Models");
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
			new Trie:tViewModels = Trie:oo_get(this, "m_ViewModels");
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
			new Trie:tWeaponModels = Trie:oo_get(this, "m_WeaponModels");
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
			new Trie:tSounds = Trie:oo_get(this, "m_Sounds");
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