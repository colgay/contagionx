#include <amxmodx>
#include <cstrike>
#include <ctg_core>

new g_Money[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("[CTG] Money", CTG_VERSION, "colg");

	register_message(get_user_msgid("Money"), "OnMsgMoney");
}

public OnMsgMoney(msgid, msgdest, id)
{
	cs_set_user_money(id, g_Money[id], get_msg_arg_int(2));
	return PLUGIN_HANDLED;
}

public client_disconnected(id)
{
	g_Money[id] = 0;
}

public plugin_natives()
{
	register_library("ctg_money");

	register_native("ctg_SetMoney", "native_SetMoney");
	register_native("ctg_GetMoney", "native_GetMoney");
}

public native_SetMoney()
{
	new id = get_param(1);
	g_Money[id] = get_param(2);
	cs_set_user_money(id, g_Money[id], get_param(3));
}

public native_GetMoney()
{
	new id = get_param(1);
	return g_Money[id];
}