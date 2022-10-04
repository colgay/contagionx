#if defined _zombiemod_included
  #endinput
#endif
#define _zombiemod_included

native zm_isZombie(id);
native zm_createZombieType(const name[], const desc[], const class[], flags);
native zm_getZombieType(id);

native zm_multiplyPainShock(Float:val);
native zm_multiplyKnockBack(Float:val);

forward zm_InfectPlayer(id, attacker);
forward zm_ZombieKnifeDeploy(id);
forward zm_ResetMaxSpeed(id);

forward zm_PainShock(id);
forward zm_KnockBack(id);