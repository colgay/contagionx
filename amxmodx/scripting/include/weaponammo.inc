#if defined _weaponammo_included
	#endinput
#endif
#define _weaponammo_included

#define AMMOFULL -1

#define BPAMMO_MAX_MULTIPLIER 2.0

#define CsAmmoMax[%0] floatround(CS_AMMO_DATA[%0][AMMO_MAX] * BPAMMO_MAX_MULTIPLIER)
#define CsAmmoAmount[%0] CS_AMMO_DATA[%0][AMMO_AMT]

enum _:AmmoData
{
	AMMO_AMT,
	AMMO_COST,
	AMMO_MAX
};

// {Amount, Cost, Max}
new const CS_AMMO_DATA[][AmmoData] = 
{
	{-1,  -1,  -1},
	{10, 125,  30}, // 338magnum
	{30,  80,  90}, // 762nato
	{30,  60, 200}, // 556natobox
	{30,  60,  90}, // 556nato
	{ 8,  65,  32}, // buckshot
	{12,  25, 100}, // 45acp
	{50,  50, 100}, // 57mm
	{ 7,  40,  35}, // 50ae
	{13,  50,  52}, // 357sig
	{30,  20, 120},  // 9mm
	{ 1,  -1,   2}, // Flashbang
	{ 1,  -1,   1}, // HEGrenade
	{ 1,  -1,   1}, // SmokeGrenade
	{-1,  -1,   1} // C4
};

new const CS_AMMO_NAME[][] =
{
	"",
	"338magnum",
	"762nato",
	"556natobox",
	"556nato",
	"buckshot",
	"45acp",
	"57mm",
	"50ae",
	"357sig",
	"9mm",
	"Flashbang",
	"HEGrenade",
	"SmokeGrenade",
	"C4"
};

new const CSW_AMMO_TYPE[] = 
{
	0,
	9, //p228
	0,
	2, //scout
	12, //hegrenade
	5, //xm1014
	14, //c4
	6, //mac10
	4, //aug
	13, //smoke
	10, //elite
	7, //fiveseven
	6, //ump45
	4, //sg550
	4, //galil
	4, //famas
	6, //usp
	10, //glock
	1, //awp
	10, //mp5
	3, //m249
	5, //m3
	4, //m4a1
	10, //tmp
	2, //g3sg1
	11, //flash
	8, //deagle
	4, //sg552
	2, //ak47
	0,
	7 //p90
}

stock GetEntAmmoType(ent)
{
	if (pev_valid(ent))
		return get_ent_data(ent, "CBasePlayerWeapon", "m_iPrimaryAmmoType");
	
	return 0;
}

stock bool:GiveAmmo(player, type, amount=0, max=0)
{
	if (!amount)
		amount = CsAmmoAmount[type];
	else if (amount == AMMOFULL)
		amount = CsAmmoMax[type];

	if (!max)
		max = CsAmmoMax[type];
	
	new ammo = get_ent_data(player, "CBasePlayer", "m_rgAmmo", type);
	ExecuteHamB(Ham_GiveAmmo, player, amount, CS_AMMO_NAME[type], max);
	
	if (ammo >= max)
		return false;
	
	return true;
}

stock bool:GiveAmmoByWeapon(player, weapon_id, amount=0, max=0)
{
	if (!(CSW_P228 <= weapon_id <= CSW_P90))
		return false;

	new type = CSW_AMMO_TYPE[weapon_id];
	return GiveAmmo(player, type, amount, max);
}