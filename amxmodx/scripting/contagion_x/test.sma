#include <amxmodx>
#include <amxmisc>
#include <ctg_core>

public plugin_init()
{
	register_plugin("Test", CTG_VERSION, "colg");

	register_concmd("playerclass", "CmdPlayerClass");
	register_concmd("get_playerclass", "CmdGetPlayerClass");
}

public CmdPlayerClass(id)
{
	new name[32];
	read_argv(1, name, charsmax(name));

	new target = cmd_target(id, name, CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ALLOW_SELF|CMDTARGET_ONLY_ALIVE);
	if (!target)
	{
		client_print(id, print_console, "[CTG] Invalid target (%s)", name);
		return PLUGIN_HANDLED;
	}

	new classname[32];
	read_argv(2, classname, charsmax(classname));

	new class_id = ctg_FindPlayerClass(classname);
	if (class_id == CTG_NULL)
	{
		client_print(id, print_console, "[CTG] Invalid classname (%s)", classname);
		return PLUGIN_HANDLED;
	}

	ctg_ChangePlayerClass(target, class_id);
	client_print(0, print_console, "[CTG] Change (%n) playerclass to (%s)", target, classname);
	return PLUGIN_HANDLED;
}

public CmdGetPlayerClass(id)
{
	new class_id = ctg_GetPlayerClassId(id);
	
	static data[PlayerClass_e];
	ctg_GetPlayerClassData(class_id, data);

	client_print(id, print_console, "[CTG] your current playerclass is (%s)", data[PlCls_Name]);
	return PLUGIN_HANDLED;
}