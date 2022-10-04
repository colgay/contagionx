#if defined _ctg_util_included
	#endinput
#endif
#define _ctg_util_included

stock Obj:GetXVarObject(const xvar_name[])
{
	new xvar = get_xvar_id(xvar_name);
	if (xvar)
		return Obj:get_xvar_num(xvar);

	return @null;
}

stock PrecachePlayerModel(const model[])
{
	static model_path[128];
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", model, model);
	if (file_exists(model_path)) precache_model(model_path);

	// Support modelT.mdl files
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", model, model);
	if (file_exists(model_path)) precache_model(model_path);
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