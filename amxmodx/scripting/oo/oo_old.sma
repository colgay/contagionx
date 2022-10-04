#include <amxmodx>
#include <dynarrays>
#include <oo_const>

#define CHECK_CLASS_ID(%0,%1) if (%0 == Class:OO_NULL || %0 >= Class:g_ClassCount) { log_error(AMX_ERR_NATIVE, "[OO] Invalid class index (%d)", %0); return %1; }
#define CHECK_OBJECT_ID(%0,%1) if (%0 == Object:OO_NULL || %0 >= Object:g_ObjectCount) { log_error(AMX_ERR_NATIVE, "[OO] Invalid object index (%d)", %0); return %1; }

new Array:g_Classes;
new Trie:g_ClassTrie;
new g_ClassCount;

new Array:g_Objects;
new g_ObjectCount;

new Stack:g_CallFuncStack;

public plugin_init()
{
	register_plugin("Object-Oriented", OO_VERSION, "colg");
}

public plugin_natives()
{
	register_native("oo_Class", "native_Class");
	register_native("oo_ClassVar", "native_ClassVar");
	register_native("oo_ClassMethod", "native_ClassMethod");
	register_native("oo_FindClassId", "native_FindClassId");
	register_native("oo_GetClassInfo", "native_GetClassInfo");
	register_native("oo_GetObjectClassId", "native_GetObjectClassId");
	register_native("oo_CreateObject", "native_CreateObject");
	register_native("oo_CreateObjectById", "native_CreateObjectById");
	register_native("oo_DeleteObject", "native_DeleteObject");
	register_native("oo_CallMethod", "native_CallMethod");
	register_native("oo_GetObjectVar", "native_GetObjectVar");
	register_native("oo_SetObjectVar", "native_SetObjectVar");

	g_Classes = ArrayCreate(ClassInfo);
	g_ClassTrie = TrieCreate();

	g_Objects = ArrayCreate(ObjectContent);

	g_CallFuncStack = CreateStack();
}

// oo_Class(const name[], const parent_name[]="")
public Class:native_Class(plugin_id, num_params)
{
	new name[64], parent_name[64];
	get_string(1, name, charsmax(name));
	get_string(2, parent_name, charsmax(parent_name));

	if (FindClassId(name) != Class:OO_NULL)
	{
		log_error(AMX_ERR_NATIVE, "[OO] Class (%0) already exists.", name);
		return Class:OO_NULL;
	}

	new cdata[ClassInfo];
	cdata[Class_ParentId] = Class:OO_NULL;

	if (parent_name[0])
	{
		cdata[Class_ParentId] = FindClassId(parent_name);
		if (cdata[Class_ParentId] != Class:OO_NULL)
			GetClassInfo(cdata[Class_ParentId], cdata);
	}

	copy(cdata[Class_Name], charsmax(cdata[Class_Name]), name);
	cdata[Class_PluginId] = plugin_id;
	cdata[Class_Vars] = TrieCreate();
	cdata[Class_Methods] = TrieCreate();
	cdata[Class_Destructor] = -1;

	ArrayPushArray(g_Classes, cdata);
	TrieSetCell(g_ClassTrie, name, Class:g_ClassCount); // unique id
	g_ClassCount++;

	return Class:(g_ClassCount - 1);
}

// oo_ClassVar(class_id, AccessType:access_type=@Public, data_type, const var_name[])
public Trie:native_ClassVar(plugin_id, num_params)
{
	new Class:class_id = Class:get_param(1);
	CHECK_CLASS_ID(class_id, Invalid_Trie)

	new AccessType:access_type = AccessType:get_param(2);
	new data_type = get_param(3);

	new var_name[64], cdata[ClassInfo];
	get_string(4, var_name, charsmax(var_name));
	GetClassInfo(class_id, cdata);

	if (TrieKeyExists(cdata[Class_Vars], var_name))
	{
		log_error(AMX_ERR_NATIVE, "[OO] Variable (%s) already exists in class (%s).", var_name, cdata[Class_Name]);
		return Invalid_Trie;
	}

	new vdata[ClassVar];
	copy(vdata[CVar_Name], charsmax(vdata[CVar_Name]), var_name);
	vdata[CVar_AccessType] = access_type;
	vdata[CVar_DataType] = data_type;

	TrieSetArray(cdata[Class_Vars], var_name, vdata, ClassVar);

	return cdata[Class_Vars];
}

// oo_ClassMethod(class_id, AccessType:access_type=@Public, MethodType:method_type=@Method, const method_name[], any:...)
public Trie:native_ClassMethod(plugin_id, num_params)
{
	new Class:class_id = Class:get_param(1);
	CHECK_CLASS_ID(class_id, Invalid_Trie)

	new AccessType:access_type = AccessType:get_param(2);
	new MethodType:method_type = MethodType:get_param(3);

	new method_name[32], cdata[ClassInfo];
	get_string(4, method_name, charsmax(method_name));
	GetClassInfo(class_id, cdata);

	if (TrieKeyExists(cdata[Class_Methods], method_name))
	{
		log_error(AMX_ERR_NATIVE, "[OO] Method (%s) already exists in class (%s)", method_name, cdata[Class_Name]);
		return Invalid_Trie;
	}

	new actual_name[64];
	formatex(actual_name, charsmax(actual_name), "%s@%s", cdata[Class_Name], method_name);

	new func_id = get_func_id(actual_name, cdata[Class_PluginId]);
	if (func_id == -1)
	{
		new plugin_name[64];
		get_plugin(cdata[Class_PluginId], plugin_name, charsmax(plugin_name));
		log_error(AMX_ERR_NATIVE, "[OO] Function (%s) not found in plugin (%d)", actual_name, plugin_name);
		return Invalid_Trie;
	}

	new mdata[ClassMethod];
	copy(mdata[CMethod_Name], charsmax(mdata[CMethod_Name]), method_name);
	copy(mdata[CMethod_ActualName], charsmax(mdata[CMethod_ActualName]), actual_name);
	mdata[CMethod_AccessType] = access_type;
	mdata[CMethod_Type] = method_type;
	mdata[CMethod_FuncId] = func_id;
	mdata[CMethod_Params][0] = 0;

	if (method_type != @Dtor)
	{
		new len = 0;
		for (new i = 5; i <= num_params; i++)
		{
			switch (get_param_byref(i))
			{
				case FP_CELL, FP_FLOAT: 	mdata[CMethod_Params][len++] = 'c';
				case FP_VAL_BYREF: 			mdata[CMethod_Params][len++] = 'r';
				case FP_ARRAY: 				mdata[CMethod_Params][len++] = 'a';
				case FP_STRING: 			mdata[CMethod_Params][len++] = 's';
			}
		}

		mdata[CMethod_Params][len] = 0;
	}
	else
	{
		cdata[Class_Destructor] = func_id;
		UpdateClassInfo(class_id, cdata);
	}

	TrieSetArray(cdata[Class_Methods], method_name, mdata, ClassMethod);
	return cdata[Class_Methods];
}

// oo_FindClassId(const name[])
public Class:native_FindClassId(plugin_id, num_params)
{
	new name[64];
	get_string(1, name, charsmax(name));

	return FindClassId(name);
}

// oo_GetClassInfo(Class:class_id, data[ClassInfo])
public bool:native_GetClassInfo(plugin_id, num_params)
{
	new Class:class_id = Class:get_param(1);
	CHECK_CLASS_ID(class_id, false)

	new cdata[ClassInfo];
	GetClassInfo(class_id, cdata);
	set_array(2, cdata, ClassInfo);

	return true;
}

// Class:oo_GetObjectClassId(Object:object_id)
public Class:native_GetObjectClassId(plugin_id, num_params)
{
	new Object:object_id = Object:get_param(1);
	CHECK_OBJECT_ID(object_id, Class:OO_NULL)

	new odata[ObjectContent];
	GetObjectContent(object_id, odata);

	return odata[Object_ClassId];
}

// oo_CreateObjectById(Class:class_id, const constructor[]="", any:...)
public Object:native_CreateObjectById(plugin_id, num_params)
{
	new Class:class_id = Class:get_param(1);
	CHECK_CLASS_ID(class_id, Object:OO_NULL)

	new Object:object_id = CreateObjectById(class_id);
	if (object_id == Object:OO_NULL)
	{
		log_error(AMX_ERR_NATIVE, "[OO] Cannot create object (class id: %d)", class_id);
		return object_id;
	}

	new constructor[48];
	get_string(2, constructor, charsmax(constructor))

	CallConstructor(object_id, constructor, num_params, 3);
	return object_id;
}

// oo_CreateObject(const classname[], const constructor[]="", any:...)
public Object:native_CreateObject(plugin_id, num_params)
{
	new classname[64];
	get_string(1, classname, charsmax(classname));

	new Class:class_id = FindClassId(classname);
	if (class_id == Class:OO_NULL)
	{
		log_error(AMX_ERR_NATIVE, "[OO] Invalid class name (%s)", classname);
		return Object:OO_NULL;
	}

	new Object:object_id = CreateObjectById(class_id);
	if (object_id == Object:OO_NULL)
	{
		log_error(AMX_ERR_NATIVE, "[OO] Cannot create object (%s)", classname);
		return object_id;
	}

	new constructor[48];
	get_string(2, constructor, charsmax(constructor))

	CallConstructor(object_id, constructor, num_params, 3);
	return object_id;
}

// oo_DeleteObject(object_id)
public native_DeleteObject(plugin_id, num_params)
{
	new Object:object_id = Object:get_param(1);
	CHECK_OBJECT_ID(object_id, 0)

	CallDestructor(object_id);

	new odata[ObjectContent];
	GetObjectContent(object_id, odata);
	TrieDestroy(odata[Object_Data]); // free memory

	if (object_id == Object:(g_ObjectCount - 1)) // is the last element
	{
		ArrayDeleteItem(g_Objects, _:object_id);
		g_ObjectCount--;
	}
	else
	{
		odata[Object_IsDeleted] = true; // mark as deleted
		ArraySetArray(g_Objects, _:object_id, odata);
	}

	return 0;
}

// oo_CallMethod(object_id, const classname[]="", const method_name[], any:...)
public native_CallMethod(plugin_id, num_params)
{
	new Object:object_id = Object:get_param(1);
	CHECK_OBJECT_ID(object_id, -3)

	new classname[64], method_name[48];
	get_string(2, classname, charsmax(classname));
	get_string(3, method_name, charsmax(method_name));

	new odata[ObjectContent], cdata[ClassInfo], mdata[ClassMethod];
	GetObjectContent(object_id, odata);

	new Class:start_class_id = odata[Object_ClassId];
	if (classname[0])
	{
		start_class_id = FindClassId(classname);
		if (start_class_id == Class:OO_NULL)
		{
			log_error(AMX_ERR_NATIVE, "[OO] Invalid class name (%s)", classname);
			return -3;
		}
	}

	new Class:class_id = start_class_id;
	new Class:callfunc_class_id = Class:OO_NULL;

	if (PopStackCell(g_CallFuncStack, callfunc_class_id)) // is called inside a method of a class
	{
		PushStackCell(g_CallFuncStack, callfunc_class_id); // stack.top();
	}

	new bool:found = false;

	do {
		GetClassInfo(class_id, cdata);

		if (TrieGetArray(cdata[Class_Methods], method_name, mdata, ClassMethod))
		{
			if (mdata[CMethod_AccessType] == @Public
			|| (callfunc_class_id != Class:OO_NULL
				&& (mdata[CMethod_AccessType] == @Protected || callfunc_class_id == class_id)))
			{
				found = true;
				break;	
			}

			log_error(AMX_ERR_NATIVE, "[OO] Cannot access method (%s::%s)", cdata[Class_Name], mdata[CMethod_Name]);
			return -3;
		}

		class_id = cdata[Class_ParentId];

	} while (class_id != Class:OO_NULL);

	if (!found)
	{
		log_error(AMX_ERR_NATIVE, "[OO] Cannot find Method (%s)", method_name);
		return -3;
	}

	if (mdata[CMethod_Type] == @Dtor)
	{
		CallDestructor(object_id, class_id);
		return 0;
	}

	PushStackCell(g_CallFuncStack, class_id);

	callfunc_begin_i(mdata[CMethod_FuncId], cdata[Class_PluginId])
	callfunc_push_int(_:object_id);
	PushParameters(mdata[CMethod_Params], num_params, 4);
	new ret = callfunc_end();

	PopStack(g_CallFuncStack);

	return ret;
}

// oo_GetObjectVar(object_id, const classname[], const var_name[], any: ...)
public native_GetObjectVar(plugin_id, num_params)
{
	new classname[64], var_name[64];
	get_string(2, classname, charsmax(classname));
	get_string(3, var_name, charsmax(var_name));

	new Object:object_id = Object:get_param(1);
	CHECK_OBJECT_ID(object_id, OO_NULL)

	new odata[ObjectContent];
	GetObjectContent(object_id, odata);

	new Class:start_class_id = odata[Object_ClassId];
	if (classname[0])
	{
		start_class_id = FindClassId(classname);
		if (start_class_id == Class:OO_NULL)
		{
			log_error(AMX_ERR_NATIVE, "[OO] Invalid class name (%s)", classname);
			return OO_NULL;
		}
	}
	else
	{
		new cdata[ClassInfo];
		GetClassInfo(start_class_id, cdata);
		copy(classname, charsmax(classname), cdata[Class_Name]);
	}

	new data_type = CheckVarAccessibility(var_name, start_class_id);
	if (data_type != OO_NULL)
	{
		new actual_name[64];
		formatex(actual_name, charsmax(actual_name), "%s@%s", classname, var_name);

		switch (data_type)
		{
			case FP_CELL:
			{
				// new hp;
				// oo_GetObjectVar(this, "m_hp", hp)

				new cell;
				if (TrieGetCell(odata[Object_Data], actual_name, cell))
					return cell;
				
				return 0;
			}
			case FP_ARRAY:
			{
				// new array[5];
				// oo_GetObjectVar(this, "m_array", array, sizeof array);

				new size = get_param_byref(5);
				new array = new[size];

				if (TrieGetArray(odata[Object_Data], actual_name, _$array[0], size))
				{
					set_array(4, _$array[0], size); // this?
					return 1;
				}

				return 0;
			}
			case FP_STRING:
			{
				// new name[32];
				// oo_GetObjectVar(this, "m_name", name, sizeof name);

				new len = get_param_byref(5);
				new string = new[len];

				if (TrieGetString(odata[Object_Data], actual_name, _$string[0], len))
				{
					set_string(4, _$string[0], len);
					return 1;
				}

				return 0;
			}
		}
	}

	return OO_NULL;
}


// oo_SetObjectVar(object_id, const classname[], const var_name[], any: ...)
public native_SetObjectVar(plugin_id, num_params)
{
	new classname[64], var_name[64];
	get_string(2, classname, charsmax(classname));
	get_string(3, var_name, charsmax(var_name));

	new Object:object_id = Object:get_param(1);
	CHECK_OBJECT_ID(object_id, OO_NULL)

	new odata[ObjectContent];
	GetObjectContent(object_id, odata);

	new Class:start_class_id = odata[Object_ClassId];
	if (classname[0])
	{
		start_class_id = FindClassId(classname);
		if (start_class_id == Class:OO_NULL)
		{
			log_error(AMX_ERR_NATIVE, "[OO] Invalid class name (%s)", classname);
			return 0;
		}
	}
	else
	{
		new cdata[ClassInfo];
		GetClassInfo(start_class_id, cdata);
		copy(classname, charsmax(classname), cdata[Class_Name]);
	}

	new data_type = CheckVarAccessibility(var_name, start_class_id);
	if (data_type != OO_NULL)
	{
		new actual_name[64];
		formatex(actual_name, charsmax(actual_name), "%s@%s", classname, var_name);

		switch (data_type)
		{
			case FP_CELL:
			{
				TrieSetCell(odata[Object_Data], actual_name, get_param_byref(4));
				return 1;
			}
			case FP_ARRAY:
			{
				new size = get_param_byref(5);
				new array = new[size];
				get_array(4, _$array[0], size)
				TrieSetArray(odata[Object_Data], actual_name, _$array[0], size);
				return 1;
			}
			case FP_STRING:
			{
				static string[1024]; // bad
				get_string(4, string, charsmax(string));
				TrieSetString(odata[Object_Data], actual_name, string);
				return 1;
			}
		}
	}

	return 0;
}

Class:FindClassId(const name[])
{
	new Class:class_id;
	if (TrieGetCell(g_ClassTrie, name, class_id))
		return class_id;
	
	return Class:OO_NULL;
}

GetClassInfo(Class:class_id, cdata[ClassInfo])
{
	return ArrayGetArray(g_Classes, _:class_id, cdata);
}

UpdateClassInfo(Class:class_id, cdata[ClassInfo])
{
	ArraySetArray(g_Classes, _:class_id, cdata);
}

GetObjectContent(Object:object_id, odata[ObjectContent])
{
	ArrayGetArray(g_Objects, _:object_id, odata);
}

Object:CreateObjectById(Class:class_id)
{
	new odata[ObjectContent], odata_push[ObjectContent];
	odata_push[Object_ClassId] = class_id;
	odata_push[Object_Data] = TrieCreate();
	odata_push[Object_IsDeleted] = false;

	// find if any position was marked as deleted
	for (new i = 0; i < g_ObjectCount; i++)
	{
		GetObjectContent(Object:i, odata);

		if (odata[Object_IsDeleted]) // insert data here
		{
			ArraySetArray(g_Objects, i, odata_push);
			return Object:i;
		}
	}

	ArrayPushArray(g_Objects, odata_push); // push to new
	g_ObjectCount++;

	return Object:(g_ObjectCount - 1);
}

CallConstructor(Object:object_id, const method_name[], num_params, start_param)
{
	enum _:MethodData
	{
		MD_FuncId,
		MD_Params[64],
		MD_PluginId,
		Class:MD_ClassId,
	};

	new odata[ObjectContent], cdata[ClassInfo];
	GetObjectContent(object_id, odata);

	new Class:start_class_id = odata[Object_ClassId];
	new Class:class_id = start_class_id;

	new Array:aMethods = ArrayCreate(MethodData);
	new method_count = 0;
	new mdata[ClassMethod], mdata2[MethodData];

	do {
		GetClassInfo(class_id, cdata);

		if (TrieGetArray(cdata[Class_Methods], method_name, mdata, ClassMethod) && mdata[CMethod_Type] == @Ctor)
		{
			mdata2[MD_FuncId] = mdata[CMethod_FuncId];
			mdata2[MD_Params] = mdata[CMethod_Params];
			mdata2[MD_PluginId] = cdata[Class_PluginId];
			mdata2[MD_ClassId] = class_id;

			ArrayPushArray(aMethods, mdata2);
			method_count++;
		}

		class_id = cdata[Class_ParentId];

	} while (class_id != Class:OO_NULL);

	for (new i = method_count-1; i >= 0; i--)
	{
		ArrayGetArray(aMethods, i, mdata2);

		PushStackCell(g_CallFuncStack, mdata2[MD_ClassId]);

		callfunc_begin_i(mdata2[MD_FuncId], mdata2[MD_PluginId]);
		callfunc_push_int(_:object_id); // push *this
		PushParameters(mdata2[MD_Params], num_params, start_param);
		callfunc_end();

		PopStack(g_CallFuncStack);

		//server_print("i = %d", i);
	}

	ArrayDestroy(aMethods);
}

CallDestructor(Object:object_id, Class:start_class_id=Class:OO_NULL)
{
	new odata[ObjectContent], cdata[ClassInfo];

	if (start_class_id == Class:OO_NULL)
	{
		GetObjectContent(object_id, odata);
		start_class_id = odata[Object_ClassId];
	}

	new Class:class_id = start_class_id;

	do {
		GetClassInfo(class_id, cdata);

		if (cdata[Class_Destructor] != -1)
		{
			PushStackCell(g_CallFuncStack, class_id);

			callfunc_begin_i(cdata[Class_Destructor], cdata[Class_PluginId]);
			callfunc_push_int(_:object_id);
			callfunc_end();

			PopStack(g_CallFuncStack);
		}

		class_id = cdata[Class_ParentId];

	} while (class_id != Class:OO_NULL);
}

PushParameters(const param_list[], num_params, start_param)
{
	new p_format = 0;

	for (new param = start_param; param <= num_params; param++)
	{
		switch (param_list[p_format])
		{
			case 'c':
			{
				callfunc_push_int(get_param_byref(param));
			}
			case 'r':
			{
				new r = get_param_byref(param);
				callfunc_push_intrf(r);
			}
			case 'a', 's':
			{
				callfunc_push_int(get_param(param));
			}
		}
		
		++p_format;
	}
}

CheckVarAccessibility(const var_name[], Class:start_class_id)
{
	new Class:callfunc_class_id = Class:OO_NULL;

	if (PopStackCell(g_CallFuncStack, callfunc_class_id)) // is called inside a class
	{
		PushStackCell(g_CallFuncStack, callfunc_class_id); // stack.top();
	}

	new cdata[ClassInfo], vinfo[ClassVar];
	new Class:class_id = start_class_id;

	do {
		GetClassInfo(class_id, cdata);

		// get variable info from current class
		if (TrieGetArray(cdata[Class_Vars], var_name, vinfo, ClassVar))
		{
			if (vinfo[CVar_AccessType] == @Public 
				|| (callfunc_class_id != Class:OO_NULL 
					&& (vinfo[CVar_AccessType] == @Protected || callfunc_class_id == class_id)))
			{
				return vinfo[CVar_DataType];
			}

			log_error(AMX_ERR_NATIVE, "[OO] Cannot access variable (%s::%s)", cdata[Class_Name], vinfo[CVar_Name]);
			return OO_NULL;
		}

		class_id = cdata[Class_ParentId];

	} while (class_id != Class:OO_NULL);

	log_error(AMX_ERR_NATIVE, "[OO] Cannot find variable (%s)", var_name);
	return OO_NULL;
}

stock bool:HasParent(Class:class_id, Class:parent_id, bool:include_self=true)
{
	if (include_self && class_id == parent_id)
		return true;

	new data[ClassInfo];
	new Class:current_id = class_id;

	do {
		GetClassInfo(current_id, data);
		current_id = data[Class_ParentId];
		if (current_id == parent_id)
			return true;

	} while (current_id != Class:OO_NULL);

	return false;
}