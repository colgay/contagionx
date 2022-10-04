#include <amxmodx>
#include <ctg_core>
#include <ctg_zombie>

public plugin_init()
{
	register_plugin("[CTG] Menu: Zombie Class", CTG_VERSION, "colg");

	register_clcmd("zombieclass", "CmdZombieClass");
}

public plugin_natives()
{
	register_native("ctg_ShowZombieClassMenu", "native_ShowZombieClassMenu");
}

public native_ShowZombieClassMenu()
{
	new id = get_param(1);
	ShowZombieClassMenu(id);
}

public CmdZombieClass(id)
{
	ShowZombieClassMenu(id);
	return PLUGIN_HANDLED;
}

public ShowZombieClassMenu(id)
{
	static data[PlayerClass_e], buffer[100];

	new menu = menu_create("Zombie Classes", "HandleZombieClassMenu");
	new count = ctg_GetZombieClassCount();
	new class_id;

	for (new i = 0; i < count; i++)
	{
		class_id = ctg_GetZombieClassId(i);
		ctg_GetPlayerClassData(class_id, data);

		if (ctg_GetNextZombieClass(id) == class_id)
			formatex(buffer, charsmax(buffer), "\r%s \y%s", data[PlCls_Name], data[PlCls_Desc]);
		else
			formatex(buffer, charsmax(buffer), "\w%s \y%s", data[PlCls_Name], data[PlCls_Desc]);

		menu_additem(menu, buffer);
	}

	if (menu_items(menu) < 1)
	{
		menu_destroy(menu);
		return;
	}

	menu_display(id, menu);
}

public HandleZombieClassMenu(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	static data[PlayerClass_e];

	new class_id = ctg_GetZombieClassId(item);
	ctg_GetPlayerClassData(class_id, data);
	ctg_SetNextZombieClass(id, class_id);

	client_print_color(id, id, "%s You chose (%s) as your next zombie class.", CTG_PREFIX, data[PlCls_Name])

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}