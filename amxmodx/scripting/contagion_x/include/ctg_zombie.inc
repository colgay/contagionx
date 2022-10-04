#if defined _ctg_zombie_included
	#endinput
#endif
#define _ctg_zombie_included

#include <ctg_boss>

native ctg_Zombie();
native ctg_IsZombie(id);
native ctg_RegisterZombieClass(class_id);
native ctg_GetZombieClassId(index);
native ctg_GetZombieClassCount();
native ctg_GetNextZombieClass(id);
native ctg_SetNextZombieClass(id, class_id);