#include <amxmodx>
#include <ctg_const>
#include <oo>

new Object:g_oZombieInfo;

public oo_init()
{
    new Class:zb = oo_class("Zombie", "PlayerClass");
    {
        oo_method(zb, MT_METHOD, "AssignClassInfo");
        oo_method(zb, MT_CTOR, "Ctor", FP_CELL); // (Object:oPlayer)
        oo_method(zb, MT_DTOR, "Dtor");
    }
}

public plugin_precache()
{
    g_oZombieInfo = oo_new("PlayerClassInfo", "Ctor", "zombie", "Zombie", "", Team_Zombie, 0);
}

public plugin_init()
{
    register_plugin("[CTG] Zombie", CTG_VERSION, "colg");

    oo_call(g_oZombieInfo, "CreateCvars", "zombie", 250, 0.5, 1.2, 1.0);
}

public Zombie@Ctor(Object:oPlayer)
{
    oo_call(oo_this(), "PlayerClass@Ctor", oPlayer);
}

public Zombie@Dtor()
{
}

public Zombie@AssignClassInfo()
{
    oo_set(oo_this(), "m_oClassInfo", g_oZombieInfo);
}