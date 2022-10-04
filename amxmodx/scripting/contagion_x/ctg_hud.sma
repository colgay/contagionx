#include <amxmodx>
#include <amxmisc>
#include <ctg_core>

new Float:g_LastUpdateTime;

public plugin_init()
{
	register_plugin("Test", CTG_VERSION, "colg");

	register_event("Health", "EventHealth", "be", "1>0");

	set_task_ex(1.0, "TaskUpdateHud", 0, _, _, SetTask_Repeat)
}

public EventHealth(id)
{
	new Float:time = get_gametime() - g_LastUpdateTime;
	if (time >= 0.1)
		ShowHud(id, 1.0 - time);
}

public TaskUpdateHud()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_alive(i))
			continue;

		ShowHud(i, 1.0);
	}

	g_LastUpdateTime = get_gametime();
}

ShowHud(id, Float:holdtime)
{
	static data[PlayerClass_e];
	ctg_GetPlayerClassData(ctg_GetPlayerClassId(id), data);

	set_hudmessage(0, 255, 0, 0.02, 0.9, 0, 0.0, holdtime, 0.0, 0.5, 4);
	show_hudmessage(id, "HP: %d | Class: %s", get_user_health(id), data[PlCls_Name]);
}