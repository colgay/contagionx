#include <amxmodx>
#include <oo>
#include <ctg_const>

new Array:g_aHumanClasses;
new g_HumanClassCount;

public oo_init()
{
	oo_class("HumanClassInfo", "PlayerClassInfo");
	{
		new const cl[] = "HumanClassInfo";
		oo_ctor(cl, "Ctor", @string, @string);
		oo_dtor(cl, "Dtor");
	}

	g_aHumanClasses = ArrayCreate(1);
}

public plugin_init()
{
	register_plugin("[CTG] Human Class", CTG_VERSION, "holla");
}

public HumanClassInfo@Ctor(const name[], const desc[])
{
	oo_super_ctor("PlayerClassInfo", name, desc);
	ArrayPushCell(g_aHumanClasses, @this);
	g_HumanClassCount++;
}

ShowHumanClassMenu(id, time=-1)
{
	static item_name[STRLEN_NORMAL];
	static class_name[STRLEN_SHORT];
	static class_desc[STRLEN_SHORT];
	static HumanClassInfo:info_obj;

	new menu = menu_create("Choose a Human Class", "HandleHumanClassMenu");

	for (new i = 0; i < g_HumanClassCount; i++)
	{
		info_obj = any:ArrayGetCell(g_aHumanClasses, i);
		oo_get_str(info_obj, "name", class_name, charsmax(class_name));
		oo_get_str(info_obj, "desc", class_desc, charsmax(class_desc));

		formatex(item_name, charsmax(item_name), "%s \y%s", class_name, class_desc);
		menu_additem(menu, item_name, info_obj);
	}

	if (menu_items(menu) < 1)
	{
		menu_destroy(menu);
		return;
	}

	menu_display(id, menu, time);
}

public HandleHumanClassMenu(id, menu, item)
{
	
}