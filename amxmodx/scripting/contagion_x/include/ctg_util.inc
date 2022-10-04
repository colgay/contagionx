#if defined _ctg_util_included
	#endinput
#endif
#define _ctg_util_included

#include <ctg_core>

stock PrecachePlayerModel(const model[])
{
	static model_path[128];
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", model, model);
	precache_model(model_path);

	// Support modelT.mdl files
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", model, model);
	if (file_exists(model_path)) precache_model(model_path);
}

stock GetPlayerClassSound(class_id, const key[], const default_sound[][])
{
	new Array:sound = ctg_GetPlayerClassSound(class_id, key);
	if (sound == Invalid_Array)
	{
		sound = ArrayCreate(100);
		for (new i = 0; i < sizeof default_sound; i++)
		{
			ArrayPushString(sound, default_sound[i]);
			precache_sound(default_sound[i]);
		}
	}

	return sound;
}

stock GetRandomSoundArray(Array:array)
{
	static sound[100];
	ArrayGetString(array, random(ArraySize(array)), sound, charsmax(sound));

	return sound; // directly return the string
}

stock bool:ctg_IsA(id, class_id, max_depth=-1)
{
	new start_id = ctg_GetPlayerClassId(id);
	if (start_id == CTG_NULL)
		return false;
	
	return ctg_HasPlayerClassParent(start_id, class_id, max_depth);
}

stock CountPlayers(bool:alive=true, class_id=CTG_NULL, bool:check_parents=false)
{
	new count = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i) || !(CS_TEAM_T <= get_ent_data(i, "CBasePlayer", "m_iTeam") <= CS_TEAM_CT))
			continue;

		if (alive && !is_user_alive(i))
			continue;

		if (class_id != CTG_NULL && !ctg_IsA(i, class_id, check_parents ? -1 : 0))
			continue;

		count++;
	}

	return count;
}

stock CountSpawnablePlayers()
{
	new count = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i) || !(CS_TEAM_T <= cs_get_user_team(i) <= CS_TEAM_CT))
			continue;
		
		if (GetPlayerCsMenu(i) == CS_Menu_ChooseAppearance)
			continue;

		count++;
	}

	return count;
}

stock CsMenu:GetPlayerCsMenu(id)
{
	return CsMenu:get_ent_data(id, "CBasePlayer", "m_iMenu");
}

stock DropPlayerWeapons(id, slot=0)
{
	for (new i = 1; i <= 5; i++)
	{
		if (slot && slot != i)
			continue;
		
		new weapon_ent = get_ent_data_entity(id, "CBasePlayer", "m_rgpPlayerItems", i);
		
		while (pev_valid(weapon_ent))
		{
			if (ExecuteHamB(Ham_CS_Item_CanDrop, weapon_ent))
			{
				static class[32];
				pev(weapon_ent, pev_classname, class, charsmax(class));
				
				engclient_cmd(id, "drop", class);
			}
			
			// Find next weapon
			weapon_ent = get_ent_data_entity(weapon_ent, "CBasePlayerItem", "m_pNext");
		}
	}
}