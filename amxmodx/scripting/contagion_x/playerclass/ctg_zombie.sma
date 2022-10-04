#include <amxmodx>
#include <ctg_core>

new CZombie;
new bool:g_IsZombie[MAX_PLAYERS + 1];
new g_NextZombieClassId[MAX_PLAYERS + 1] = {CTG_NULL, ...};

new Array:g_ZombieClasses;
new g_ZombieClassCount;

public plugin_precache()
{
	CZombie = ctg_CreatePlayerClass(_, "Zombie", "zombie", "", Team_Zombie);
}

public plugin_init()
{
	register_plugin("[CTG] Zombie", CTG_VERSION, "colg");

	ctg_CreatePlayerClassCvars(CZombie, "zombie", 1000, 1.0, 1.0, 1.0);
}

public plugin_natives()
{
	register_library("ctg_zombie");
	
	register_native("ctg_Zombie", "native_Zombie");
	register_native("ctg_IsZombie", "native_IsZombie");

	register_native("ctg_RegisterZombieClass", "native_RegisterZombieClass");
	register_native("ctg_GetZombieClassId", "native_GetZombieClassId");
	register_native("ctg_GetZombieClassCount", "native_GetZombieClassCount");
	register_native("ctg_GetNextZombieClass", "native_GetNextZombieClass");
	register_native("ctg_SetNextZombieClass", "native_SetNextZombieClass");

	g_ZombieClasses = ArrayCreate(1);
}

public native_Zombie()
{
	return CZombie;
}

public native_IsZombie()
{
	new id = get_param(1);

	return _:g_IsZombie[id];
}

public native_RegisterZombieClass()
{
	new class_id = get_param(1);
	if (!IS_VALID_CLASSID(class_id))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] Invalid class id (%d).", class_id);
		return CTG_NULL;
	}

	ArrayPushCell(g_ZombieClasses, class_id);
	g_ZombieClassCount++;

	return (g_ZombieClassCount - 1);
}

public native_GetZombieClassCount()
{
	return g_ZombieClassCount;
}

public native_GetZombieClassId()
{
	new index = get_param(1);
	if (!(CTG_NULL < index < g_ZombieClassCount))
	{
		log_error(AMX_ERR_NATIVE, "[CTG] Invalid zombie class id (%d).", index);
		return CTG_NULL;
	}

	return ArrayGetCell(g_ZombieClasses, index);
}

public native_SetNextZombieClass()
{
	new id = get_param(1);

	g_NextZombieClassId[id] = get_param(2);
}

public native_GetNextZombieClass()
{
	new id = get_param(1);

	return g_NextZombieClassId[id];
}

public ctg_OnChangePlayerClass(id, class_id) // pre
{
	if (class_id == CZombie)
	{
		if (g_ZombieClassCount > 0)
		{
			if (g_NextZombieClassId[id] == CTG_NULL)
				class_id = ArrayGetCell(g_ZombieClasses, random(g_ZombieClassCount));

			ctg_ChangePlayerClass(id, class_id); // call again. support for the zombie classes
			return PLUGIN_HANDLED; // stop the original forward
		}
	}

	return PLUGIN_CONTINUE;
}

public ctg_OnChangePlayerClass_P(id, class_id)
{
	if (ctg_GetPlayerTeam(id) == Team_Zombie)
	{
		g_IsZombie[id] = true;
	}
	else
	{
		g_IsZombie[id] = false;
	}
}

public client_disconnected(id)
{
	g_IsZombie[id] = false;
	g_NextZombieClassId[id] = CTG_NULL;
}