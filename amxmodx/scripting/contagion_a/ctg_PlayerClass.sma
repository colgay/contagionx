
public oo_init()
{
	oo_class("PlayerClassInfo");
	{
		new const cls[] = "PlayerClassInfo";

		oo_var(cls, "name", 32);
		oo_var(cls, "desc", 32);
		oo_var(cls, "team", 1);
		oo_var(cls, "flags", 1);
		oo_var(cls, "models", 1); // Array:
		oo_var(cls, "v_models", 1); // Trie:
		oo_var(cls, "p_models", 1); // Trie:
		oo_var(cls, "sounds", 1); // Trie:
		oo_var(cls, "cvars", 1); // Trie:
		oo_var(cls, "index", 1);

		// (const name[], const desc[], team, flags)
		oo_ctor(cls, "Ctor", @string, @string, @cell, @cell);
		oo_dtor(cls, "Dtor");

		// (const name[], const string[], flags, const desc[])
		oo_method(cls, "CreateCvar", @string, @string, @cell, @string);

		oo_method(cls, "LoadAssets");
		oo_method(cls, "LoadJson", @string);
	}

	oo_class("PlayerClass");
	{
		new const cls[] = "PlayerClass";

		oo_var(cls, "player_id", 1);

		oo_ctor(cls, "Ctor", @cell);
		oo_dtor(cls, "Dtor");

		oo_method(cls, "GetInfo");
		oo_method(cls, "SetProps");
		oo_method(cls, "SetMaxSpeed");
		oo_method(cls, "SetWeaponModel", @cell); // (ent)

		// (channel, const sample[], Float:volume, Float:attn, flags, pitch)
		oo_method(cls, "ChangeSound", @cell, @string, @float, @float, @cell, @cell);
	}
}

public PlayerClassInfo@Ctor(const name[], const desc[], PlayerTeam:team, flags)
{
	@init_this(this);

	oo_set_str(this, "name", name);
	oo_set_str(this, "desc", desc);
	oo_set_cell(this, "team", team);
	oo_set_cell(this, "flags", flags);

	oo_set_cell(this, "models", ArrayCreate(32));
	oo_set_cell(this, "v_models", TrieCreate());
	oo_set_cell(this, "p_models", TrieCreate());
	oo_set_cell(this, "sounds", TrieCreate());
	oo_set_cell(this, "cvars", TrieCreate());

	oo_call(this, "LoadAssets");
}