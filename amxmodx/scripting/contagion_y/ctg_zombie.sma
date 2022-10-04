#include <amxmodx>
#include <oo>

#include <ctg_const>

new Obj:g_oZombieClassInfo;

public oo_init()
{
	oo_decl_subclass("ZombieClassInfo" : "PlayerClassInfo");
	{
		new const cl[] = "ZombieClassInfo";

		// (const name[], const desc[], team, flags)
		oo_decl_ctor(cl, "Ctor", OO_STRING, OO_STRING, OO_CELL, OO_CELL);
		
		oo_decl_method(cl, "LoadAssets");
	}

	oo_decl_subclass("Zombie" : "PlayerClass");
	{
		new const cl[] = "Zombie";

		oo_decl_ctor(cl, "Ctor", OO_CELL); // (Obj:oPlayer)
		oo_decl_method(cl, "SetPlayerClassInfo");
	}
}

public plugin_precache()
{
	g_oZombieClassInfo = oo_new("ZombieClassInfo", "Zombie", "Infected", Team_Zombie, 0);
}

public plugin_init()
{
	register_plugin("[CTG] Zombie", CTG_VERSION, "colg");

	oo_call(g_oZombieClassInfo, "CreateCvars", "zombie", 128, 0.6, 1.25, 0.0);
}

public ZombieClassInfo@Ctor(const name[], const desc[], team, flags)
{
	oo_super_ctor("PlayerClassInfo", name, desc, team, flags);
}

public ZombieClassInfo@LoadAssets() // override
{
	oo_call(oo_this(), "LoadJson", "zombie");
}

public Zombie@Ctor(Obj:o_player)
{
	oo_super_ctor("PlayerClass", o_player);
}

public Zombie@SetPlayerClassInfo() // override
{
	oo_set(oo_this()["m_oPlayerClassInfo"] = g_oZombieClassInfo);
}