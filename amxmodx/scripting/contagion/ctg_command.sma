#include <amxmodx>
#include <amxmisc>
#include <oo>

#include <ctg_const>
#include <ctg_playerclass>

public plugin_init()
{
	register_plugin("[CTG] Command", CTG_VERSION, "holla");

	register_concmd("ctg_change_class", "CmdChangeClass", ADMIN_KICK, "<name or #userid> [class]");
}

public CmdChangeClass(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	static arg1[STRLEN_SHORT], arg2[STRLEN_SHORT];
	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));

	new player = cmd_target(id, arg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
	if (!player)
		return PLUGIN_HANDLED;
	
	if (!oo_class_exists(arg2) || !oo_subclass_of(arg2, "PlayerClass"))
	{
		console_print(id, "invalid class name");
		return PLUGIN_HANDLED;
	}

	ctg_playerclass_change(player, arg2);
	return PLUGIN_HANDLED;
}