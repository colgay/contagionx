#include <amxmodx>
#include <xs>

public plugin_init()
{
    new uuid[40];
    for (new i = 0; i < 10000000; i++)
    {
        UUID_Generate(uuid, charsmax(uuid));
    }
}

stock UUID_Generate(output[], len, seed=0)
{
    static counter;

    if (seed != 0)
        xs_seed(seed);
    
    formatex(output, len, "%d-%d-%d", get_systime(), xs_irand(), counter++);
    hash_string(output, Hash_Sha1, output, len);
}