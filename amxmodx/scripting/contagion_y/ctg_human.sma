#include <amxmodx>
#include <oo>

#include <ctg_const>

new Obj:g_oHumanClassInfo;

public oo_init()
{
	oo_decl_subclass("HumanClassInfo" : "PlayerClassInfo");
	{
		new const cl[] = "HumanClassInfo";

		// (const name[], const desc[], team, flags)
		oo_decl_ctor(cl, "Ctor", OO_STRING, OO_STRING, OO_CELL, OO_CELL);
		oo_decl_method(cl, "LoadAssets");
	}

	oo_decl_subclass("Human" : "PlayerClass");
	{
		new const cl[] = "Human";

		oo_decl_ctor(cl, "Ctor", OO_CELL); // (Obj:oPlayer)
		oo_decl_method(cl, "SetPlayerClassInfo");
	}
}

public plugin_precache()
{
	g_oHumanClassInfo = oo_new("HumanClassInfo", "Human", "Survivor", Team_Human, 0);
}

public plugin_init()
{
	register_plugin("[CTG] Human", CTG_VERSION, "colg");

	oo_call(g_oHumanClassInfo, "CreateCvars", "human", 77, 0.9, 0.9, 0.0);
}

public HumanClassInfo@Ctor(const name[], const desc[], team, flags)
{
	oo_super_ctor("PlayerClassInfo", name, desc, team, flags);
}

public HumanClassInfo@LoadAssets() // override
{
	oo_call(oo_this(), "LoadJson", "human");
}

public Human@Ctor(Obj:o_player)
{
	oo_super_ctor("PlayerClass", o_player);
}

public Human@SetPlayerClassInfo() // override
{
	oo_set(oo_this()["m_oPlayerClassInfo"] = g_oHumanClassInfo);
}