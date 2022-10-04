#include <amxmodx>
#include <amxmisc>
#include <json>
#include <ctg_util>
#include <oo>

public Class:CPlayerClassAssets;
public Class:CPlayerClass;
public Class:CPlayer;
public Class:CPlayerHandler;

public Object:g_objPlayerHandler;

public plugin_precache()
{
	CPlayerClassAssets = class<"PlayerClassAssets">;
	{
		new Class:c = CPlayerClassAssets;

		var<c>@Public.m_name(FP_STRING);
		var<c>@Public.m_desc(FP_STRING);
		var<c>@Public.m_team(FP_CELL);
		var<c>@Public.m_flags(FP_CELL);
		var<c>@Public.m_models(FP_CELL);
		var<c>@Public.m_viewmodels(FP_CELL);
		var<c>@Public.m_weaponmodels(FP_CELL);
		var<c>@Public.m_sounds(FP_CELL);
		var<c>@Public.m_cvars(FP_ARRAY);

		ctor<c>Ctor(FP_STRING, FP_STRING, FP_CELL, FP_CELL); // (const name[], const desc[], team, flags)
		dtor<c>Dtor(VOID);

		method<c>@Public.LoadAssets(VOID);
		method<c>@Public.LoadJson(FP_STRING); // (const filename[])
	}

	CPlayerClass = class<"PlayerClass">;
	{
		new Class:c = CPlayerClass;

		var<c>@Public.m_objPlayer(FP_CELL);
		var<c>@Public.m_objAssets(FP_CELL);

		ctor<c>Ctor(FP_CELL); // (Object:objPlayer)
		dtor<c>Dtor(VOID);

		//method<c>@Public.Connect();
		//method<c>@Public.Disconnect();

		method<c>@Public.SetAssets(FP_CELL); // (Object:objAssets)
	}

	CPlayer = class<"Player">;
	{
		new Class:c = CPlayer;

		var<c>@Public.m_id(FP_CELL);
		var<c>@Public.m_objPlayerClass(FP_CELL)

		ctor<c>Ctor(FP_CELL); // (player_id)
		dtor<c>Dtor(VOID);

		method<c>@Public.Connect(VOID);
		method<c>@Public.Disconnect(VOID);

		//method<c>@Public.ChangePlayerClass(FP_STRING); // (const classname[])
	}

	CPlayerHandler = class<"PlayerHandler">;
	{
		new Class:c = CPlayerHandler;

		var<c>@Public.m_objPlayers(FP_ARRAY);

		ctor<c>Ctor(VOID);
		dtor<c>Dtor(VOID);

		method<c>@Public.Connect(FP_CELL); // (id)
		method<c>@Public.Disconnect(FP_CELL); // (id)
		method<c>@Public.GetPlayer(FP_CELL); // (id)
	}
}

public plugin_init()
{
	register_plugin("Contagion", CTG_VERSION, "colg");

	g_objPlayerHandler = new<PlayerHandler>("Ctor");
}

public PlayerClassAssets@Ctor(Object:this, const name[], const desc[], PlayerTeam:team, flags)
{
	set{@this.m_name* = name};
	set{@this.m_desc* = desc};
	set{@this.m_team* = team};
	set{@this.m_flags* = flags};

	set{@this.m_models* = ArrayCreate(32)};
	set{@this.m_viewmodels* = TrieCreate()};
	set{@this.m_weaponmodels* = TrieCreate()};
	set{@this.m_sounds* = TrieCreate()};

	callvoid{@this.LoadAssets()};
}

public PlayerClassAssets@Dtor(Object:this)
{
	new Array:models = Array:get{@this.m_models};
	new Trie:viewmodels = Trie:get{@this.m_viewmodels};
	new Trie:weaponmodels = Trie:get{@this.m_weaponmodels};
	new Trie:sounds = Trie:get{@this.m_sounds};

	ArrayDestroy(models);
	TrieDestroy(viewmodels);
	TrieDestroy(weaponmodels);
	TrieDestroy(sounds);
}

public PlayerClassAssets@LoadAssets(Object:this)
{
	call{@this.LoadJson("Player.json")}; // default
}

public bool:PlayerClassAssets@LoadJson(Object:this, const filename[])
{
	static filepath[100];
	get_configsdir(filepath, charsmax(filepath));
	format(filepath, charsmax(filepath), "%s/Contagion/PlayerClass/%s.json", filepath, filename);

	new JSON:json = json_parse(filepath, true, true);
	if (json != Invalid_JSON)
	{
		static key[128], value[128];

		new JSON:models = json_object_get_value(json, "models");
		if (models != Invalid_JSON)
		{
			new Array:aModels = Array:get{@this.m_models};
			for (new i = json_array_get_count(models) - 1; i >= 0; i--)
			{
				json_array_get_string(models, i, value, charsmax(value));
				ArrayPushString(aModels, value);
				PrecachePlayerModel(value);
			}
			json_free(models);
		}

		new JSON:viewmodels = json_object_get_value(json, "viewmodels");
		if (viewmodels != Invalid_JSON)
		{
			new JSON:vmodel_val = Invalid_JSON;
			new Trie:tViewModels = Trie:get{@this.m_viewmodels};
			for (new i = json_object_get_count(viewmodels) - 1; i >= 0; i--)
			{
				json_object_get_name(viewmodels, i, key, charsmax(key));
				vmodel_val = json_object_get_value_at(viewmodels, i);
				json_get_string(vmodel_val, value, charsmax(value));
				json_free(vmodel_val);
				TrieSetString(tViewModels, key, value);
				precache_model(value);
			}
			json_free(viewmodels);
		}

		new JSON:weapmodels = json_object_get_value(json, "weaponmodels");
		if (weapmodels != Invalid_JSON)
		{
			new JSON:pmodel_val = Invalid_JSON;
			new Trie:tWeaponModels = Trie:get{@this.m_weaponmodels};
			for (new i = json_object_get_count(weapmodels) - 1; i >= 0; i--)
			{
				json_object_get_name(weapmodels, i, key, charsmax(key));
				pmodel_val = json_object_get_value_at(weapmodels, i);
				json_get_string(pmodel_val, value, charsmax(value));
				json_free(pmodel_val);
				TrieSetString(tWeaponModels, key, value);
				precache_model(value);
			}
			json_free(weapmodels);
		}

		new JSON:sounds = json_object_get_value(json, "sounds");
		if (sounds != Invalid_JSON)
		{
			new JSON:sound_val = Invalid_JSON;
			new Trie:tSounds = Trie:get{@this.m_sounds};
			for (new i = json_object_get_count(sounds) - 1; i >= 0; i--)
			{
				json_object_get_name(sounds, i, key, charsmax(key));
				sound_val = json_object_get_value_at(sounds, i);
				json_get_string(sound_val, value, charsmax(value));
				json_free(sound_val);
				TrieSetString(tSounds, key, value);
				precache_sound(value);
			}
			json_free(sounds);
		}

		json_free(json);
		return true;
	}

	server_print("load");

	return false;
}

public PlayerClass@Ctor(Object:this, Object:objPlayer)
{
	set{@this.m_objPlayer* = objPlayer};
}

public PlayerClass@Dtor(Object:this)
{
}

public PlayerClass@SetAssets(Object:this, Object:objAssets)
{
	set{@this.m_objAssets* = objAssets};
}

public Player@Ctor(Object:this, player_id)
{
	set{@this.m_id* = player_id};
	//server_print("player@ctor(%d)", player_id);
}

public Player@Dtor(Object:this)
{
	//server_print("player@dtor()");
}

public Player@Connect(Object:this)
{
	get{@this.m_id}
	//server_print("player@connect(%d)", get{@this.m_id});
}

public Player@Disconnect(Object:this)
{
	get{@this.m_id}
	//server_print("player@disconnect(%d)", get{@this.m_id});
}

public PlayerHandler@Ctor(Object:this)
{
	new Object:objPlayers[MAX_PLAYERS+1] = {Object:OO_NULL, ...};
	seta{@this.m_objPlayers* = objPlayers[sizeof objPlayers]};
}

public PlayerHandler@Dtor(Object:this)
{
	new Object:objPlayers[MAX_PLAYERS+1] = {Object:OO_NULL, ...};
	geta{objPlayers[sizeof objPlayers] = *@this.m_objPlayers};

	for (new i = 0; i < sizeof objPlayers; i++)
	{
		if (objPlayers[i] != Object:OO_NULL)
		{
			delete(objPlayers[i]);
		}
	}
}

public PlayerHandler@Connect(Object:this, id)
{
	new Object:objPlayers[MAX_PLAYERS+1];
	geta{objPlayers[sizeof objPlayers] = *@this.m_objPlayers};

	if (objPlayers[id] == Object:OO_NULL)
	{
		objPlayers[id] = new<Player>("Ctor", id);
		seta{@this.m_objPlayers* = objPlayers[sizeof objPlayers]}

		callvoid{@objPlayers[id].Connect()};
	}
}

public PlayerHandler@Disconnect(Object:this, id)
{
	new Object:objPlayers[MAX_PLAYERS+1];
	geta{objPlayers[sizeof objPlayers] = *@this.m_objPlayers};

	if (objPlayers[id] != Object:OO_NULL)
	{
		callvoid{@objPlayers[id].Disconnect()};

		delete(objPlayers[id]);
		objPlayers[id] = Object:OO_NULL;
		seta{@this.m_objPlayers* = objPlayers[sizeof objPlayers]}
	}
}

public Object:PlayerHandler@GetPlayer(Object:this, id)
{
	new Object:objPlayers[MAX_PLAYERS+1];
	geta{objPlayers[sizeof objPlayers] = *@this.m_objPlayers};

	return objPlayers[id];
}

public client_connectex(id)
{
	new str1[32], str2[32];
	new Float:time1 = get_gametime();
	float_to_str(time1, str1, charsmax(str1));

	call{@g_objPlayerHandler.Connect(id)};

	new Float:time2 = get_gametime();
	float_to_str(time2, str2, charsmax(str2));

	server_print("time = %s %s", str1, str2);
}

public client_disconnected(id)
{
	call{@g_objPlayerHandler.Disconnect(id)};	
}