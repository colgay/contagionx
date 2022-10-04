#include <amxmodx>
#include <oo>

public oo_init()
{
	@class ("Animal");
	{
		@init_class("Animal");

		@var (OO_CELL:m_Age);
		@var (OO_ARRAY[32]:m_LastEatFood);

		@construct :Ctor(@cell);
		@destruct :Dtor();

		@method :Eat(@string);
		@method :Sleep(@cell);
		//@method Recycle(@byref);
	}

	@subclass ("Cat", "Animal");
	{
		@init_class("Cat");

		@construct :Ctor(@cell);
		@destruct :Dtor();

		@method :Eat(@string);
	}

	@subclass ("Dog", "Animal");
	{
		@init_class("Dog");

		@construct :Ctor(@cell);
		@destruct :Dtor();

		@method :Sleep(@cell);
	}
}

public plugin_init()
{
	register_plugin("Test OO", "0.1", "haha");

	server_print("^n------- animal ---------")
	new Animal:animal = any:@new("Animal", 5);
	@call:animal.Sleep(5);
	@call:animal.Eat("nothing");
	@delete(animal);

	server_print("^n------- cat ---------")
	new Cat:cat = any:@new("Cat", 10);
	@call:cat.Eat("fish");
	@delete(cat);

	server_print("^n------- dog ---------")
	new Dog:dog = any:@new("Dog", 20);
	@call:dog.Sleep(10);
	@delete(dog);
}

public Animal@Ctor(age)
{
	@set (_this.m_Age: = age);
}

public Animal@Eat(const food[])
{
	@sets (_this.m_LastEatFood[] << food);
	server_print("Animal@Eat(const food[]: ^"%s^")", food);
	
	new member_LastEatFood[32];
	@gets (_this.m_LastEatFood[] >> member_LastEatFood[32]);
	server_print("Animal@m_LastEatFood is now: %s", member_LastEatFood);
}

public Animal@Sleep(days)
{
	server_print("Animal@Sleep(days: %d)", days);
}

public Animal@Dtor()
{
	server_print("animal dtor");
}

public Cat@Ctor(age)
{
	@set (_this.m_Age: = age);
	server_print("Cat@Ctor(%d)", age);
}

public Dog@Ctor(age)
{
	@set (_this.m_Age: = age);
	server_print("Dog@Ctor(%d)", age);
}

public Cat@Eat(const food[])
{
	@call:_this.Animal@Eat(food);
	new age = @get(_this.m_Age) - 1;
	@set (_this.m_Age: = age);
	server_print("Cat age is now %d", age);
}

public Dog@Sleep(days)
{
	@call:_this.Animal@Sleep(days);
	new age = @get(_this.m_Age) + days;
	@set (_this.m_Age: = age);
	server_print("Dog age is now %d", age);
}

public Cat@Dtor() { server_print("cat dtor"); }
public Dog@Dtor() { server_print("dog dtor"); }