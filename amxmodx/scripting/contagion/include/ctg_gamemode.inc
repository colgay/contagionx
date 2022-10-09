#if defined _ctg_gamemode_included
	#endinput
#endif
#define _ctg_gamemode_included

#define SetEntNextThink(%0,%1) entity_set_float(%0, EV_FL_nextthink, get_gametime() + %1)

native GameMode:ctg_gamemode_get_current();
native bool:ctg_gamemode_set_next(const clasname[]);
native ctg_gamemode_set_default(const classname[]);