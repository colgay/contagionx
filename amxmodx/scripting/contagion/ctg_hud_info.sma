#include <amxmodx>
#include <fun>
#include <cstrike>
#include <ctg_const>
#include <ctg_playerclass>
#include <oo>

public plugin_init()
{
	register_plugin("[CTG] HUD Info", CTG_VERSION, "holla");

	set_task(0.5, "TaskUpdateHud", .flags="b");
}

public TaskUpdateHud()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_alive(i))
		{
			ShowHud(i);
		}
	}
}

ShowHud(id)
{
	new classname[STRLEN_SHORT] = "Unknown";
	new color[3] = {255, 255, 255};
	new PlayerClass:class_obj = ctg_playerclass_get(id);

	if (class_obj != @null)
	{
		new PlayerClassInfo:info_obj = any:oo_call(class_obj, "GetClassInfo");
		if (info_obj != @null)
			oo_get_str(info_obj, "name", classname, charsmax(classname));

		if (oo_isa(class_obj, "Human", true))
		{
			color = {0, 255, 0};
		}
		else if (oo_isa(class_obj, "Zombie", true))
		{
			color = {200, 200, 0};
		}
	}

	set_hudmessage(color[0], color[1], color[2], 0.01, 0.925, 0, 0.0, 0.6, 0.0, 0.3, 4);
	show_hudmessage(id, "HP: %d | AP: %d | $%d | Class: %s", 
		get_user_health(id),
		get_user_armor(id),
		cs_get_user_money(id),
		classname
	);
}