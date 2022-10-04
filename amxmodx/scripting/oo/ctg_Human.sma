#include <amxmodx>
#include <ctg_const>
#include <oo>

new Object:g_oHumanInfo;

public oo_init()
{
    new Class:hm = oo_class("Human", "PlayerClass");
    {
        oo_method(hm, MT_METHOD, "AssignClassInfo");
        oo_method(hm, MT_CTOR, "Ctor", FP_CELL); // (Object:oPlayer)
        oo_method(hm, MT_DTOR, "Dtor");
    }
}

public plugin_precache()
{
    g_oHumanInfo = oo_new("PlayerClassInfo", "Ctor", "human", "Human", "", Team_Human, 0);
}

public plugin_init()
{
    register_plugin("[CTG] Human", CTG_VERSION, "colg");

    oo_call(g_oHumanInfo, "CreateCvars", "human", 100, 1.0, 1.0, 1.0);
}

public Human@Ctor(Object:oPlayer)
{
    oo_call(oo_this(), "PlayerClass@Ctor", oPlayer);
}

public Human@Dtor()
{
}

public Human@AssignClassInfo()
{
    oo_set(oo_this(), "m_oClassInfo", g_oHumanInfo);
}