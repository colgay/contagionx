#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <oo>
#include <ctg_playerclass>
#include <ctg_const>
#include <ctg_util>
#include <weaponammo>

new CvarPrimarys[STRLEN_LONG];
new CvarSecondarys[STRLEN_NORMAL];

new g_WeaponChosen[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("[CTG] Menu: Weapons", CTG_VERSION, "holla");

	register_clcmd("say /guns", "CmdSayGuns");

	new pcvar = create_cvar("ctg_prim_weapons", "mac10,tmp,ump45,p90,scout");
	bind_pcvar_string(pcvar, CvarPrimarys, charsmax(CvarPrimarys));

	pcvar = create_cvar("ctg_sec_weapons", "glock18,usp,p228,fiveseven");
	bind_pcvar_string(pcvar, CvarSecondarys, charsmax(CvarSecondarys));
}

public CmdSayGuns(id)
{
	if (!is_user_alive(id) || !ctg_playerclass_is(id, "Human", false))
		return PLUGIN_CONTINUE;

	if (!ShowWeaponMenu(id, g_WeaponChosen[id]+1))
	{
		client_print(id, print_chat, "你已經選擇過武器");
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}

public ctg_on_playerclass_set_props(this, id)
{
	g_WeaponChosen[id] = 0;

	if (oo_isa(this, "Human"))
	{
		ShowWeaponMenu(id, CS_WEAPONSLOT_PRIMARY);
	}
}

public ShowWeaponMenu(id, slot)
{
	if (slot > CS_WEAPONSLOT_SECONDARY)
		return 0;

	static left[STRLEN_SHORTER], right[STRLEN_LONG];
	static wpn_name[STRLEN_SHORT], wpn_id;
	static menu, item_name[STRLEN_SHORT];
	right = (slot == CS_WEAPONSLOT_PRIMARY) ? CvarPrimarys : CvarSecondarys;

	if (slot == CS_WEAPONSLOT_PRIMARY)
		menu = menu_create("Choose a Primary Weapon", "HandleWeaponMenu");
	else
		menu = menu_create("Choose a Secondary Weapon", "HandleWeaponMenu");

	do
	{
		strtok2(right, left, charsmax(left), right, charsmax(right), ',', 1);
		formatex(wpn_name, charsmax(wpn_name), "weapon_%s", left);
		wpn_id = get_weaponid(wpn_name);
		if (~CSW_SLOTS_BITS[slot] & (1<<wpn_id)) // invalid weapon
			continue;

		item_name = left;
		strtoupper(item_name);

		menu_additem(menu, item_name, wpn_name);
	}
	while (right[0] != '^0');

	if (menu_items(menu) < 1)
	{
		menu_destroy(menu);
		return 0;
	}

	menu_display(id, menu);
	return 1;
}

public HandleWeaponMenu(id, menu, item)
{
	if (item == MENU_EXIT || !is_user_alive(id) || !ctg_playerclass_is(id, "Human", false))
	{
		menu_destroy(menu);
		return;
	}

	static wpn_name[STRLEN_SHORT];
	menu_item_getinfo(menu, item, _, wpn_name, charsmax(wpn_name));
	menu_destroy(menu);

	new wpn_id = get_weaponid(wpn_name);
	new desired_chosen = (CSW_SLOTS_BITS[CS_WEAPONSLOT_PRIMARY] & (1<<wpn_id)) ? 0 : 1;

	if (g_WeaponChosen[id] > desired_chosen)
	{
		menu_destroy(menu);
		return;
	}

	DropPlayerWeapons(id, desired_chosen + 1);
	give_item(id, wpn_name);
	GiveAmmoByWeapon(id, wpn_id, AMMOFULL);

	g_WeaponChosen[id] = desired_chosen + 1;

	if (g_WeaponChosen[id] == 1)
		ShowWeaponMenu(id, CS_WEAPONSLOT_SECONDARY);
}