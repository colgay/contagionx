#include <amxmodx>
#include <ctg_core>
#include <ctg_zombie>

enum _:ZombieClasses_
{
	Zombie_Normal,
	Zombie_Speedy,
	Zombie_Light,
	Zombie_Heavy,
};

enum _:ZombieClassInfo_
{
	ZmClsInfo_Name[32],
	ZmClsInfo_UniqueId[32],
	ZmClsInfo_Desc[32],
	ZmClsInfo_Flags,
	ZmClsInfo_Hp,
	Float:ZmClsInfo_Gravity,
	Float:ZmClsInfo_Speed,
	Float:ZmClsInfo_Knockback,
};

new CZombies[ZombieClasses_];
new CZombie;

new g_ZombieClasses[ZombieClasses_][ZombieClassInfo_] = {
	{"Normal Zombie", "zombie_normal", "Balance", 0, 1500, 1.0, 0.98, 1.0},
	{"Speedy Zombie", "zombie_speedy", "Speedy", 0, 750, 1.0, 1.15, 1.5},
	{"Light Zombie", "zombie_light", "Low gravity", 0, 1000, 0.7, 1.0, 2.0},
	{"Heavy Zombie", "zombie_heavy", "High HP, Low knockback", 0, 3000, 1.0, 0.9, 0.5}
};

public plugin_precache()
{
	CZombie = ctg_Zombie();

	for (new i = 0; i < sizeof CZombies; i++)
	{
		CZombies[i] = ctg_CreatePlayerClass(CZombie, g_ZombieClasses[i][ZmClsInfo_Name], 
							g_ZombieClasses[i][ZmClsInfo_UniqueId], g_ZombieClasses[i][ZmClsInfo_Desc], 
							Team_Zombie, g_ZombieClasses[i][ZmClsInfo_Flags]);
		
		ctg_RegisterZombieClass(CZombies[i]);
	}
}

public plugin_init()
{
	register_plugin("[CTG] Zombie Classes", CTG_VERSION, "colg");

	for (new i = 0; i < sizeof CZombies; i++)
	{
		ctg_CreatePlayerClassCvars(CZombies[i], g_ZombieClasses[i][ZmClsInfo_UniqueId],
							g_ZombieClasses[i][ZmClsInfo_Hp], g_ZombieClasses[i][ZmClsInfo_Gravity],
							g_ZombieClasses[i][ZmClsInfo_Speed], g_ZombieClasses[i][ZmClsInfo_Knockback]);
	}
}