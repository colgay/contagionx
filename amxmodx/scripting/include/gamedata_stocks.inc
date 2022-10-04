#if defined _gamedatastocks_included
	#endinput
#endif
#define _gamedatastocks_included

stock any:getPlayerData(entity, const member[], element = 0)
{
    return get_ent_data(entity, "CBasePlayer", member, element);
}

stock setPlayerData(entity, const member[], any:value, element = 0)
{
    set_ent_data(entity, "CBasePlayer", member, value, element);
}

stock Float:getPlayerDataF(entity, const member[], element = 0)
{
    return get_ent_data_float(entity, "CBasePlayer", member, element);
}

stock setPlayerDataF(entity, const member[], Float:value, element = 0)
{
    set_ent_data_float(entity, "CBasePlayer", member, value, element);
}

stock any:getWeaponData(entity, const member[], element = 0)
{
    return get_ent_data(entity, "CBasePlayerWeapon", member, element);
}

stock setWeaponData(entity, const member[], any:value, element = 0)
{
    set_ent_data(entity, "CBasePlayerWeapon", member, value, element);
}

stock any:getGameRules2(const member[], element = 0)
{
    return get_gamerules_int("CGameRules", member, element);
}

stock any:getGameRules(const member[], element = 0)
{
    return get_gamerules_int("CHalfLifeMultiplay", member, element);
}

stock Float:getGameRulesF(const member[], element = 0)
{
    return get_gamerules_float("CHalfLifeMultiplay", member, element);
}


stock setGameRules2(const member[], any:value, element = 0)
{
    set_gamerules_int("CGameRules", member, value, element);
}

stock setGameRules(const member[], any:value, element = 0)
{
    set_gamerules_int("CHalfLifeMultiplay", member, value, element);
}

stock setGameRulesF(const member[], Float:value, element = 0)
{
    set_gamerules_float("CHalfLifeMultiplay", member, value, element);
}

stock getPlayerDataEnt(entity, const member[], element = 0)
{
    return get_ent_data_entity(entity, "CBasePlayer", member, element);
}