#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <oo>

#include <ctg_const>
#include <ctg_playerclass>

public plugin_init()
{
	register_plugin("[CTG] Player", CTG_VERSION, "holla");

	RegisterHam(Ham_Touch, "weaponbox", "OnWeaponTouch");
	RegisterHam(Ham_Touch, "weapon_shield", "OnWeaponTouch");
	RegisterHam(Ham_Touch, "armoury_entity", "OnWeaponTouch");
}

public OnWeaponTouch(ent, toucher)
{
	if (!pev_valid(ent) || !is_user_alive(toucher))
		return HAM_IGNORED;
	
	new PlayerClass:class_obj = ctg_playerclass_get_obj(toucher);
	return (class_obj != @null && !oo_call(class_obj, "CanPickupItem")) ? HAM_SUPERCEDE : HAM_IGNORED;
}