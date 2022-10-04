#if defined _ctg_util_included
	#endinput
#endif
#define _ctg_util_included

#tryinclude <cstrike>
#tryinclude <fakemeta>
#tryinclude <hamsandwich>
#tryinclude <json>
#tryinclude <ctg_const>

#define eget(#%2[%1].%3) get_ent_data(%1,#%2,#%3)
#define eget_e(#%2[%1].%3) get_ent_data_entity(%1,#%2,#%3)
#define eget_f(#%2[%1].%3) get_ent_data_float(%1,#%2,#%3)
#define eget_s(%4=#%2[%1].%3) get_ent_data_string(%1,#%2,#%3,%4,charsmax(%4))
#define eget_v(%4=#%2[%1].%3) get_ent_data_vector(%1,#%2,#%3,%4)

// macro define
#define eset(#%2[%1].%3=%4) set_ent_data(%1,#%2,#%3,%4)
#define eset_e(#%2[%1].%3=%4) set_ent_data_entity(%1,#%2,#%3,%4)
#define eset_f(#%2[%1].%3=%4) set_ent_data_float(%1,#%2,#%3,%4)
#define eset_s(#%2[%1].%3=%4) set_ent_data_string(%1,#%2,#%3,%4)
#define eset_v(#%2[%1].%3=%4) set_ent_data_vector(%1,#%2,#%3,%4)

#define eget2(#%2[%1].%3[%4]) get_ent_data(%1,#%2,#%3,%4)
#define eget2_e(#%2[%1].%3[%4]) get_ent_data_entity(%1,#%2,#%3,%4)
#define eget2_f(#%2[%1].%3[%4]) get_ent_data_float(%1,#%2,#%3,%4)
#define eget2_s(%4=#%2[%1].%3[%5]) get_ent_data_string(%1,#%2,#%3,%4,charsmax(%4),%5)
#define eget2_v(%4=#%2[%1].%3[%5]) get_ent_data_vector(%1,#%2,#%3,%4,%5)

#define eset2(%4=#%2[%1].%3[%5]) set_ent_data(%1,#%2,#%3,%4,%5)
#define eset2_e((%4=#%2[%1].%3[%5]) set_ent_data_entity(%1,#%2,#%3,%4,%5)
#define eset2_f(%4=#%2[%1].%3[%5]) set_ent_data_float(%1,#%2,#%3,%4,%5)
#define eset2_s(%4=#%2[%1].%3[%5]) set_ent_data_string(%1,#%2,#%3,%4,%5)
#define eset2_v(%4=#%2[%1].%3[%5]) set_ent_data_vector(%1,#%2,#%3,%4,%5)

#define gr_get(#%1.%2) get_gamerules_int(#%1,#%2)
#define gr_get_f(#%1.%2) get_gamerules_float(#%1,#%2)

#define gr_set(#%1.%2=%0) set_gamerules_int(#%1,#%2,%0)
#define gr_set_f(#%1.%2=%0) set_gamerules_float(#%1,#%2,%0)

stock PrecachePlayerModel(const model[])
{
	static model_path[128];
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", model, model);
	precache_model(model_path);

	// Support modelT.mdl files
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", model, model);
	if (file_exists(model_path)) precache_model(model_path);
}

stock CountPlayers(bool:alive=true, class_id=CTG_NULL, bool:check_parents=false)
{
	new count = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i) || !(CS_TEAM_T <= cs_get_user_team(i) <= CS_TEAM_CT))
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

stock ctg_IsA(id, class_id, depth=-1)
{
	return ctg_CheckPlayerClass(ctg_GetPlayerClassId(id), class_id, depth);
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