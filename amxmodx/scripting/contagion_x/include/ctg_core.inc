#if defined _ctg_core_included
	#endinput
#endif
#define _ctg_core_included

#include <ctg_const>
#include <ctg_human>
#include <ctg_zombie>

#define IS_VALID_CLASSID(%0) (CTG_NULL < %0 < ctg_GetPlayerClassCount())

native ctg_CreatePlayerClass(parent_id=CTG_NULL, const name[], const unique_id[], const desc[]="", PlayerTeam:team=Team_None, flags=0, plugin_id=CTG_NULL);
native ctg_CreatePlayerClassCvars(class_id, const name[], hp=100, Float:gravity=1.0, Float:speed=1.0, Float:knockback=1.0);
native bool:ctg_HasPlayerClassParent(start_id, parent_id, max_depth=-1);
native ctg_GetPlayerClassData(class_id, data[PlayerClass_e]);
native ctg_GetPlayerClassCount();
native ctg_FindPlayerClass(const unique_id[]);
native ctg_ChangePlayerClass(id, class_id=CTG_NULL, const classname[]="");
native ctg_GetPlayerClassId(id);
native ctg_SetPlayerClassId(id, class_id);
native PlayerTeam:ctg_GetPlayerTeam(id);
native ctg_SetPlayerTeam(id, PlayerTeam:team);
native Array:ctg_GetPlayerClassSound(class_id, const key[]);

forward ctg_OnChangePlayerClass(id, class_id);
forward ctg_OnChangePlayerClass_P(id, class_id);