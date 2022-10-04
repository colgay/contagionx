#include <amxmodx>

public plugin_init()
{
    register_clcmd("ha", "CmdHa");
}

public CmdHa(id)
{
    set_hudmessage(0, 225, 0, -1.0, 0.55, 2, 0.1, 3.0, 0.0, 0.00, -1)
    show_hudmessage(id, "diu nei lo mo, eat cheese burger, ni hao, xijinping")
}