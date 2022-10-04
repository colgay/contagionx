#include <amxmodx>
#include <oo>

public oo_init()
{
	new Class:ani = oo_class("Animal");
	{
		oo_var(ani, DT_CELL, "m_health");
		oo_var(ani, DT_ARRAY[3], "m_items");

		oo_method(ani, MT_CTOR, "Ctor", FP_CELL, FP_ARRAY);
		oo_method(ani, MT_METHOD, "Eat");
		oo_method(ani, MT_DTOR, "Dtor");
	}

	new Class:cat = oo_class("Cat", "Animal");
	{
		oo_var(cat, DT_CELL, "m_cute");

		oo_method(cat, MT_CTOR, "Ctor", FP_CELL, FP_ARRAY, FP_CELL);
		oo_method(cat, MT_METHOD, "Eat");
		oo_method(cat, MT_METHOD, "Meow", FP_VAL_BYREF);
		oo_method(cat, MT_DTOR, "Dtor");
	}

	new Class:dog = oo_class("Dog", "Animal");
	{
		oo_var(dog, DT_CELL, "m_volume");

		oo_method(dog, MT_CTOR, "Ctor", FP_CELL, FP_ARRAY, FP_CELL);
		oo_method(dog, MT_METHOD, "Eat");
		oo_method(dog, MT_METHOD, "Bark", FP_STRING);
		oo_method(dog, MT_DTOR, "Dtor");
	}
}

public plugin_init()
{
	new Object:animal = oo_new("Animal", "Ctor", 100, {0, 0, 0});
	oo_call(animal, "Eat");

	new Object:cat = oo_new("Cat", "Ctor", 50, {1, 1, 1}, 0);
	oo_call(cat, "Eat");

	new diu = 0;
	oo_call(cat, "Meow", diu);
	//server_print("now diu = %d", diu);

	new Object:dog = oo_new("Dog", "Ctor", 75, {2, 2, 2}, 0);
	oo_call(dog, "Eat");

	new joe[3];
	oo_call(dog, "Bark", joe);

	server_print("joe = {%d,%d,%d}", joe[0], joe[1], joe[2])

	oo_delete(animal);
	oo_delete(cat);
	oo_delete(dog);
}

public Animal@Ctor(health, items[3])
{
	new Object:this = oo_this();
	oo_set(this, "m_health", health);
	oo_set(this, "m_items", items);
	server_print("Animal@Ctor(items{%d, %d, %d})", items[0], items[1], items[2])
}

public Animal@Eat()
{
	new Object:this = oo_this();
	oo_set(this, "m_health", oo_get(this, "m_health") + 3);
	server_print("Animal@Eat() : m_health=%d", oo_get(this, "m_health"));
}

public Animal@Dtor()
{
	server_print("Animal@Dtor()");
}

public Cat@Ctor(health, items[3], cute)
{
	new Object:this = oo_this();
	oo_call(this, "Animal@Ctor", health, items);
	oo_set(this, "m_cute", cute);
	server_print("Cat@Ctor(items{%d, %d, %d})", items[0], items[1], items[2])
}

public Cat@Eat()
{
	new Object:this = oo_this();
	oo_set(this, "m_health", oo_get(this, "m_health") + 1);
	server_print("Cat@Eat() : m_health=%d", oo_get(this, "m_health"));
}

public Cat@Meow(&cute)
{
	server_print("haha");
	cute = 999;
}

public Cat@Dtor(cute)
{
	server_print("Cat@Dtor()");
}

public Dog@Ctor(health, items[3], volume)
{
	new Object:this = oo_this();
	oo_call(this, "Animal@Ctor", health, items);
	oo_set(this, "m_volume", volume);
	server_print("Dog@Ctor(items{%d, %d, %d})", items[0], items[1], items[2])
}

public Dog@Eat()
{
	new Object:this = oo_this();
	oo_set(this, "m_health", oo_get(this, "m_health") + 2);
	server_print("Dog@Eat() : m_health=%d", oo_get(this, "m_health"));
}

public Dog@Bark(volume[])
{
	volume[0] = 689;
	volume[1] = 777;
	volume[2] = 999;
}

public Dog@Dtor(cute)
{
	server_print("Dog@Dtor()");
}