#include <amxmodx>
#include <amxmisc>
#include <oo>
#include <ctg_const>
#include <ctg_util>

new Obj:g_oPlayerHandler;

public plugin_init()
{
	register_plugin("[CTG] Test", CTG_VERSION, "colg");

	register_concmd("playerclass", "CmdPlayerClass");

	g_oPlayerHandler = GetXVarObject("g_oPlayerHandler");

	if (g_oPlayerHandler == @null)
	{
		set_fail_state("[CTG] XVar object (g_oPlayerHandler) not found");
		return;
	}
}

public CmdPlayerClass(id)
{
	new name[32];
	read_argv(1, name, charsmax(name));

	new target = cmd_target(id, name, CMDTARGET_ALLOW_SELF|CMDTARGET_ONLY_ALIVE);
	if (target)
	{
		new classname[32];
		read_argv(2, classname, charsmax(classname));

		if (!oo_class_exists(classname))
		{
			client_print(0, print_console, "Class (%s) doesn't exists.", classname);
			return PLUGIN_HANDLED;
		}

		if (oo_subclass_of(classname, "PlayerClass"))
		{
			new Obj:o_player = Obj:oo_call(g_oPlayerHandler, "GetPlayer", target);
			if (o_player != @null)
			{
				oo_call(o_player, "ChangePlayerClass", classname);
			}
		}
	}

	return PLUGIN_HANDLED;
}