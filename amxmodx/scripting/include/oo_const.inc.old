#if defined _oo_const_included
	#endinput
#endif
#define _oo_const_included

#define OO_VERSION "0.1"

#define DT_CELL 1
#define DT_ARRAY[%0] (%0)

enum Object
{
	@null = 0
};

enum Class
{
	CNull = -1
};

enum MethodType
{
	MT_METHOD,
	MT_CTOR,
	MT_DTOR,
};

enum _:Class_e
{
	Class_Name[32],
	Class:Class_SuperId,
	Trie:Class_Vars,
	Trie:Class_Methods,
	Class_Dtor[64],
};

enum _:ClassVar_e
{
	//Var_Name[64],
	Var_DataType,
};

enum _:ClassMethod_e
{
	//Method_Name[64],
	Method_ActualName[64],
	MethodType:Method_Type,
	Method_FuncId,
	Method_PluginId,
	Method_Params[64],
};

enum _:Object_e
{
	Class:Object_ClassId,
	Object:Object_Id,
	Trie:Object_Data,
};