#include <amxmodx>
#include <engine>

public plugin_init()
{
    register_clcmd("onna", "onna")
    register_think("npc_onna","npc_think");
}

public plugin_precache()
{
    precache_model("models/player/vip/vip.mdl")
}

public onna(id)
{
    new Float:origin[3]
    entity_get_vector(id,EV_VEC_origin,origin)

    new ent = create_entity("info_target")

    entity_set_origin(ent,origin);
    origin[2] += 300.0
    entity_set_origin(id,origin)

    entity_set_float(ent,EV_FL_takedamage,1.0)
    entity_set_float(ent,EV_FL_health,100.0)

    entity_set_string(ent,EV_SZ_classname,"npc_onna");
    entity_set_model(ent,"models/player/vip/vip.mdl");
    entity_set_int(ent,EV_INT_solid, 2)

    entity_set_byte(ent,EV_BYTE_controller1,125);
    entity_set_byte(ent,EV_BYTE_controller2,125);
    entity_set_byte(ent,EV_BYTE_controller3,125);
    entity_set_byte(ent,EV_BYTE_controller4,125);

    new Float:maxs[3] = {16.0,16.0,36.0}
    new Float:mins[3] = {-16.0,-16.0,-36.0}
    entity_set_size(ent,mins,maxs)

    entity_set_float(ent,EV_FL_animtime,2.0)
    entity_set_float(ent,EV_FL_framerate,1.0)
    entity_set_int(ent,EV_INT_sequence,0);

    entity_set_float(ent,EV_FL_nextthink,halflife_time() + 0.01)

    drop_to_floor(ent)
    return 1;
}

public npc_think(id)
{
    // Put your think stuff here.
    entity_set_float(id,EV_FL_nextthink,halflife_time() + 0.01)
}