#if defined _ctg_playerclass_included
	#endinput
#endif
#define _ctg_playerclass_included

native PlayerClass:ctg_playerclass_change(id, const class[], bool:assign_props=true);
native PlayerClass:ctg_playerclass_get_obj(id);
native bool:ctg_playerclass_is(id, const class[], bool:superclass=false);

forward ctg_on_playerclass_change(id, const class[]);
forward ctg_on_playerclass_change_post(id, const class[]);