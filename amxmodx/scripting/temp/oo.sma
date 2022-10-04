#include <amxmodx>
#include <dynarrays>
#include <oo_const>

new Array:g_aClasses;
new Trie:g_tClasses;
new g_ClassCount;

new Trie:g_tObjects;
new g_ObjectCount;
new g_ObjectHashCount;

new Stack:g_ThisStack;

new g_FwInit, g_FwRet;

public plugin_precache()
{
	g_FwInit = CreateMultiForward("oo_init", ET_IGNORE);
	ExecuteForward(g_FwInit, g_FwRet);
}

public plugin_init()
{
	register_plugin("Object Oriented", OO_VERSION, "byref");

	server_print("----- [AMXX-OO Classes] -----")

	static key[64], buffer[128];
	static cdata[Class_e], cdata2[Class_e], mdata[ClassClMthd_e], vdata[ClassVar_e];
	new len, p;
	new TrieIter:miter, TrieIter:viter;
	for (new i = 0; i < g_ClassCount; i++)
	{
		ArrayGetArray(g_aClasses, i, cdata);

		if (cdata[Class_SuperId] != CNull)
		{
			ArrayGetArray(g_aClasses, _:cdata[Class_SuperId], cdata2);
			server_print("^nclass %s extends %s", cdata[Class_Name], cdata2[Class_Name]);
		}
		else
		{
			server_print("^nclass %s", cdata[Class_Name]);
		}

		server_print("{^nvariables:");
		viter = TrieIterCreate(cdata[Class_Vars]);
		{
			while (!TrieIterEnded(viter))
			{
				TrieIterGetKey(viter, key, charsmax(key));
				TrieIterGetArray(viter, vdata, ClassVar_e);

				if (vdata[ClVar_CellSize] > DT_CELL)
				{
					server_print("	array %s[%d]", key, vdata[ClVar_CellSize])
				}
				else
				{
					server_print("	cell %s", key)
				}

				TrieIterNext(viter);
			}
		}
		TrieIterDestroy(viter);

		server_print("^nmethods:");
		miter = TrieIterCreate(cdata[Class_Methods]);
		{
			while (!TrieIterEnded(miter))
			{
				TrieIterGetKey(miter, key, charsmax(key));
				TrieIterGetArray(miter, mdata, ClassClMthd_e);

				switch (mdata[ClMthd_Type])
				{
					case MT_METHOD:
					{
						len = formatex(buffer, charsmax(buffer), "	method %s(", key);
					}
					case MT_CTOR:
					{
						len = formatex(buffer, charsmax(buffer), "	constructor %s(", key);
					}
					case MT_DTOR:
					{
						len = formatex(buffer, charsmax(buffer), "	destructor %s(", key);
					}
				}

				for (p = 0; p < 64; p++)
				{
					switch (mdata[ClMthd_Params][p])
					{
						case FP_CELL:
							len += formatex(buffer[len], charsmax(buffer)-len, "cell, ");
						case FP_FLOAT:
							len += formatex(buffer[len], charsmax(buffer)-len, "float, ");
						case FP_STRING:
							len += formatex(buffer[len], charsmax(buffer)-len, "string[], ");
						case FP_ARRAY:
							len += formatex(buffer[len], charsmax(buffer)-len, "array[], ");
						case FP_VAL_BYREF:
							len += formatex(buffer[len], charsmax(buffer)-len, "&byref, ");
						default:
							break;
					}
				}

				if (buffer[len-2] == ',')
				{
					buffer[len-2] = 0;
					len -= 2;
				}

				len += formatex(buffer[len], charsmax(buffer)-len, ") {}");
				server_print(buffer);

				TrieIterNext(miter);
			}
		}
		TrieIterDestroy(miter);

		server_print("}");
	}
}

public plugin_natives()
{
	register_library("oo");

	register_native("oo_class", "native_class");
	register_native("oo_var", "native_var");
	register_native("oo_method", "native_method");
	register_native("oo_get_class_id", "native_get_class_id");
	register_native("oo_get_object_class", "native_get_object_class");
	register_native("oo_new", "native_new");
	register_native("oo_delete", "native_delete");
	register_native("oo_call", "native_call");
	register_native("oo_this", "native_this");
	register_native("oo_get", "native_get");
	register_native("oo_set", "native_set");
	register_native("oo_parent_of", "native_parent_of");
	register_native("oo_get_class_name", "native_get_class_name");

	g_aClasses = ArrayCreate(Class_e);
	g_tClasses = TrieCreate();
	g_tObjects = TrieCreate();
	g_ThisStack = CreateStack();
}

// Class:oo_class(const class[], const super_class[])
public native_class(plugin_id, num_params)
{
	static class[64], super_class[64];
	get_string(1, class, charsmax(class));
	get_string(2, super_class, charsmax(super_class));

	if (TrieKeyExists(g_tClasses, class))
	{
		log_error(AMX_ERR_NATIVE, "[OO] Class (%s) already exists", class);
		return CNull;
	}

	static cdata[Class_e];
	cdata[Class_SuperId] = CNull;

	if (super_class[0])
	{
		if (!TrieGetCell(g_tClasses, super_class, cdata[Class_SuperId]))
		{
			log_error(AMX_ERR_NATIVE, "[OO] Super class (%s) does not exist", class);
			return CNull;
		}
	}

	cdata[Class_Name] = class;
	cdata[Class_Vars] = TrieCreate();
	cdata[Class_Methods] = TrieCreate();
	cdata[Class_Dtor][0] = 0;

	ArrayPushArray(g_aClasses, cdata);
	TrieSetCell(g_tClasses, class, g_ClassCount);
	g_ClassCount++;

	return (g_ClassCount - 1);
}

// Trie:oo_var(Class:class, data_type, const var_name[])
public Trie:native_var(plugin_id, num_params)
{
	new Class:class_id = Class:get_param(1);
	if (class_id <= CNull || class_id >= Class:g_ClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[OO] Invalid class id (%d)", class_id);
		return Invalid_Trie;
	}

	new data_type = get_param(2);

	static var_name[64], cdata[Class_e];
	get_string(3, var_name, charsmax(var_name));
	ArrayGetArray(g_aClasses, _:class_id, cdata);

	if (TrieKeyExists(cdata[Class_Vars], var_name))
	{
		log_error(AMX_ERR_NATIVE, "[OO] Variable (%s) already exists in class (%s)", var_name, cdata[Class_Name]);
		return Invalid_Trie;
	}

	static vdata[ClassVar_e];
	//vdata[Var_Name] = var_name;
	vdata[ClVar_CellSize] = data_type;

	TrieSetArray(cdata[Class_Vars], var_name, vdata, ClassVar_e);
	return cdata[Class_Vars];
}

// Trie:oo_method(Class:class_id, MethodType:method_type=MT_Method, const method_name[], any:...)
public Trie:native_method(plugin_id, num_params)
{
	new Class:class_id = Class:get_param(1);
	if (class_id <= CNull || class_id >= Class:g_ClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[OO] Invalid class id (%d)", class_id);
		return Invalid_Trie;
	}

	new MethodType:method_type = MethodType:get_param(2);

	static method_name[64], cdata[Class_e];
	get_string(3, method_name, charsmax(method_name));
	ArrayGetArray(g_aClasses, _:class_id, cdata);

	if (TrieKeyExists(cdata[Class_Methods], method_name))
	{
		log_error(AMX_ERR_NATIVE, "[OO] Method (%s) already exists in class (%s)", method_name, cdata[Class_Name]);
		return Invalid_Trie;
	}

	static actual_name[64];
	formatex(actual_name, charsmax(actual_name), "%s@%s", cdata[Class_Name], method_name);

	new func_id = get_func_id(actual_name, plugin_id);
	if (func_id == -1)
	{
		static plugin_name[64];
		get_plugin(plugin_id, plugin_name, charsmax(plugin_name));
		log_error(AMX_ERR_NATIVE, "[OO] Function (%s) not found in plugin (%d)", actual_name, plugin_name);
		return Invalid_Trie;
	}

	static mdata[ClassClMthd_e];
	//mdata[ClMthd_Name] = method_name;
	mdata[ClMthd_ActualName] = actual_name;
	mdata[ClMthd_Type] = method_type;
	mdata[ClMthd_PluginId] = plugin_id;
	mdata[ClMthd_FuncId] = func_id;
	mdata[ClMthd_Params][0] = -1;

	if (method_type == MT_DTOR)
	{
		if (cdata[Class_Dtor][0])
		{
			log_error(AMX_ERR_NATIVE, "[OO] Destructor for class (%s) already exists", cdata[Class_Name]);
			return Invalid_Trie;
		}

		cdata[Class_Dtor] = method_name;
		ArraySetArray(g_aClasses, _:class_id, cdata);
	}
	else
	{
		new len = 0;
		new type;
		for (new i = 4; i <= num_params; i++)
		{
			type = get_param_byref(i);
			switch (type)
			{
				case FP_CELL, FP_FLOAT: 	mdata[ClMthd_Params][len++] = FP_CELL;
				case FP_VAL_BYREF: 			mdata[ClMthd_Params][len++] = FP_VAL_BYREF;
				case FP_ARRAY: 				mdata[ClMthd_Params][len++] = FP_ARRAY;
				case FP_STRING: 			mdata[ClMthd_Params][len++] = FP_STRING;
				default:
				{
					log_error(AMX_ERR_NATIVE, "[OO] Invalid method parameter type (%d)", type);
					return Invalid_Trie;
				}
			}
		}

		mdata[ClMthd_Params][len] = -1;
	}

	TrieSetArray(cdata[Class_Methods], method_name, mdata, ClassClMthd_e);
	return cdata[Class_Methods];
}

// Class:oo_get_class_id(const class[])
public Class:native_get_class_id(plugin_id, num_params)
{
	static class[64];
	get_string(1, class, charsmax(class));

	new Class:class_id;
	if (TrieGetCell(g_tClasses, class, class_id))
		return class_id;

	return CNull;
}

// Class:oo_get_object_class(Object:object)
public Class:native_get_object_class(plugin_id, num_params)
{
	new Object:object_id = Object:get_param(1);

	static object_hash[11], odata[Object_e];
	num_to_str(_:object_id, object_hash, charsmax(object_hash));

	if (object_id == @null || !TrieGetArray(g_tObjects, object_hash, odata, Object_e))
	{
		log_error(AMX_ERR_NATIVE, "[OO] Invalid object id (%d)", object_id);
		return CNull;
	}

	return odata[Object_ClassId];
}

// oo_new(const class[], const ctor[], any:...)
public Object:native_new(plugin_id, num_params)
{
	static class[64];
	get_string(1, class, charsmax(class));

	static cdata[Class_e], Class:class_id;
	if (!TrieGetCell(g_tClasses, class, class_id))
	{
		log_error(AMX_ERR_NATIVE, "[OO] Class (%s) does not exist", class);
		return @null;
	}

	static ctor[64], mdata[ClassClMthd_e];
	get_string(2, ctor, charsmax(ctor));
	ArrayGetArray(g_aClasses, _:class_id, cdata);

	if (ctor[0])
	{
		if (!TrieGetArray(cdata[Class_Methods], ctor, mdata, ClassClMthd_e))
		{
			log_error(AMX_ERR_NATIVE, "[OO] Constructor (%s) does not exist", ctor);
			return @null;
		}

		if (mdata[ClMthd_Type] != MT_CTOR)
		{
			log_error(AMX_ERR_NATIVE, "[OO] Method (%s) is not a constructor", ctor);
			return @null;
		}
	}

	g_ObjectHashCount++;
	if (g_ObjectHashCount == 0)
	{
		log_error(AMX_ERR_NATIVE, "[OO] Maximum number of objects exceeded");
		return @null;
	}

	static odata[Object_e];
	odata[Object_ClassId] = class_id;
	odata[Object_Id] = Object:g_ObjectHashCount;
	odata[Object_Data] = TrieCreate();

	static object_hash[11];
	num_to_str(_:odata[Object_Id], object_hash, charsmax(object_hash));
	TrieSetArray(g_tObjects, object_hash, odata, Object_e);

	// call constructor
	PushStackCell(g_ThisStack, odata[Object_Id]);
	callfunc_begin_i(mdata[ClMthd_FuncId], mdata[ClMthd_PluginId]);
	CallFuncEnd(3, mdata[ClMthd_Params], num_params);
	PopStack(g_ThisStack);
	g_ObjectCount++;

	return odata[Object_Id];
}

// oo_delete(Object:object)
public native_delete(plugin_id, num_params)
{
	new Object:object_id = Object:get_param(1);

	static object_hash[11], odata[Object_e];
	num_to_str(_:object_id, object_hash, charsmax(object_hash));

	if (object_id == @null || !TrieGetArray(g_tObjects, object_hash, odata, Object_e))
	{
		log_error(AMX_ERR_NATIVE, "[OO] Invalid object id (%d)", object_id);
		return 0;
	}

	static cdata[Class_e], mdata[ClassClMthd_e];
	new Class:current_id = odata[Object_ClassId];
	
	do {

		ArrayGetArray(g_aClasses, _:current_id, cdata);

		if (cdata[Class_Dtor][0])
		{
			TrieGetArray(cdata[Class_Methods], cdata[Class_Dtor], mdata, ClassClMthd_e);

			callfunc_begin_i(mdata[ClMthd_FuncId], mdata[ClMthd_PluginId]);
			PushStackCell(g_ThisStack, odata[Object_Id]);
			callfunc_end();
			PopStack(g_ThisStack);
		}
		
		current_id = cdata[Class_SuperId];

	} while (current_id != CNull);

	TrieDestroy(odata[Object_Data]);
	TrieDeleteKey(g_tObjects, object_hash);
	g_ObjectCount--;

	return 1;
}

// oo_call(Object:object, const method_name[], any:...)
public native_call(plugin_id, num_params)
{
	new Object:object_id = Object:get_param(1);

	static object_hash[11], odata[Object_e];
	num_to_str(_:object_id, object_hash, charsmax(object_hash));

	if (object_id == @null || !TrieGetArray(g_tObjects, object_hash, odata, Object_e))
	{
		log_error(AMX_ERR_NATIVE, "[OO] Invalid object id (%d)", object_id);
		return 0;
	}

	static cdata[Class_e], mdata[ClassClMthd_e];
	static method_name[64], class[64], name[64];
	get_string(2, method_name, charsmax(method_name));

	if (strtok2(method_name, class, charsmax(class), name, charsmax(name), '@') != -1)
	{
		new Class:class_id = CNull;
		if (!TrieGetCell(g_tClasses, class, class_id))
		{
			log_error(AMX_ERR_NATIVE, "[OO] Class (%s) does not exist", class);
			return 0;
		}

		if (!IsParentOf(odata[Object_ClassId], class_id))
		{
			ArrayGetArray(g_aClasses, _:odata[Object_ClassId], cdata);
			log_error(AMX_ERR_NATIVE, "[OO] Class (%s) is not the parent class of (%s)", class, cdata[Class_Name]);
			return 0;
		}

		ArrayGetArray(g_aClasses, _:class_id, cdata);
		
		if (!TrieGetArray(cdata[Class_Methods], name, mdata, ClassClMthd_e))
		{
			log_error(AMX_ERR_NATIVE, "[OO] Method (%s) does not exist in class (%s)", name, class);
			return 0;
		}

		PushStackCell(g_ThisStack, odata[Object_Id]);
		callfunc_begin_i(mdata[ClMthd_FuncId], mdata[ClMthd_PluginId]);
		new ret = CallFuncEnd(3, mdata[ClMthd_Params], num_params);
		PopStack(g_ThisStack);

		return ret;
	}

	new Class:current_id = odata[Object_ClassId];

	do {

		ArrayGetArray(g_aClasses, _:current_id, cdata);

		if (TrieGetArray(cdata[Class_Methods], method_name, mdata, ClassClMthd_e))
		{
			PushStackCell(g_ThisStack, odata[Object_Id]);
			callfunc_begin_i(mdata[ClMthd_FuncId], mdata[ClMthd_PluginId]);
			new ret = CallFuncEnd(3, mdata[ClMthd_Params], num_params);
			PopStack(g_ThisStack);

			return ret;
		}

		current_id = cdata[Class_SuperId];

	} while (current_id != CNull)

	log_error(AMX_ERR_NATIVE, "[OO] Method (%s) not found class (%s)", method_name, odata[Object_ClassId]);
	return 0;
}

// oo_get(Object:object, const var_name[], any:...)
public any:native_get(plugin_id, num_params)
{
	new Object:object_id = Object:get_param(1);

	static object_hash[11], odata[Object_e];
	num_to_str(_:object_id, object_hash, charsmax(object_hash));

	if (object_id == @null || !TrieGetArray(g_tObjects, object_hash, odata, Object_e))
	{
		log_error(AMX_ERR_NATIVE, "[OO] Invalid object id (%d)", object_id);
		return 0;
	}

	new Class:class_id = CNull;
	static cdata[Class_e], vdata[ClassVar_e];
	static var_name[64], class[64], name[64];
	get_string(2, var_name, charsmax(var_name));

	if (strtok2(var_name, class, charsmax(class), name, charsmax(name), '@') != -1)
	{
		if (!TrieGetCell(g_tClasses, class, class_id))
		{
			log_error(AMX_ERR_NATIVE, "[OO] Class (%s) does not exist", class);
			return 0;
		}

		ArrayGetArray(g_aClasses, _:class_id, cdata);

		if (!TrieGetArray(cdata[Class_Vars], name, vdata, ClassVar_e))
		{
			log_error(AMX_ERR_NATIVE, "[OO] Variable (%s) does not exist in class (%s)", name, class);
			return 0;
		}
	}
	else
	{
		var_name = class;

		new Class:current_id = odata[Object_ClassId];

		do {

			ArrayGetArray(g_aClasses, _:current_id, cdata);

			if (TrieGetArray(cdata[Class_Vars], var_name, vdata, ClassVar_e))
			{
				class_id = current_id;
				break;
			}

			current_id = cdata[Class_SuperId];

		} while (current_id != CNull);
	}

	if (class_id == CNull)
	{
		ArrayGetArray(g_aClasses, _:odata[Object_ClassId], cdata);
		log_error(AMX_ERR_NATIVE, "[OO] Variable (%s) not found in class (%s)", var_name, cdata[Class_Name]);
		return 0;
	}

	static actual_name[64];
	formatex(actual_name, charsmax(actual_name), "%s@%s", class, var_name);

	if (vdata[ClVar_CellSize] > DT_CELL)
	{
		new size = (num_params == 4) ? get_param_byref(4) : vdata[ClVar_CellSize];
		new array = new[size];
		
		if (TrieGetArray(odata[Object_Data], actual_name, _$array[0], size))
			set_array(3, _$array[0], size);

		return 0;
	}
	else if (vdata[ClVar_CellSize] == DT_CELL)
	{

		new cell;
		if (TrieGetCell(odata[Object_Data], actual_name, cell))
			return cell;
		
		return 0;
	}

	return 0;
}

// oo_set(Object:object, const var_name[], any:...)
public native_set(plugin_id, num_params)
{
	new Object:object_id = Object:get_param(1);

	static object_hash[11], odata[Object_e];
	num_to_str(_:object_id, object_hash, charsmax(object_hash));

	if (object_id == @null || !TrieGetArray(g_tObjects, object_hash, odata, Object_e))
	{
		log_error(AMX_ERR_NATIVE, "[OO] Invalid object id (%d)", object_id);
		return 0;
	}

	new Class:class_id = CNull;
	static cdata[Class_e], vdata[ClassVar_e];
	static var_name[64], class[64], name[64];
	get_string(2, var_name, charsmax(var_name));

	if (strtok2(var_name, class, charsmax(class), name, charsmax(name), '@') != -1)
	{
		if (!TrieGetCell(g_tClasses, class, class_id))
		{
			log_error(AMX_ERR_NATIVE, "[OO] Class (%s) does not exist", class);
			return 0;
		}

		ArrayGetArray(g_aClasses, _:class_id, cdata);

		if (!TrieGetArray(cdata[Class_Vars], name, vdata, ClassVar_e))
		{
			log_error(AMX_ERR_NATIVE, "[OO] Variable (%s) does not exist in class (%s)", name, class);
			return 0;
		}

		if (!IsParentOf(odata[Object_ClassId], class_id))
		{
			ArrayGetArray(g_aClasses, _:odata[Object_ClassId], cdata)
			log_error(AMX_ERR_NATIVE, "[OO] Class (%s) is not the parent class of (%s)", class, cdata[Class_Name]);
			return 0;
		}
	}
	else
	{
		new Class:current_id = odata[Object_ClassId];

		do {

			ArrayGetArray(g_aClasses, _:current_id, cdata);

			if (TrieGetArray(cdata[Class_Vars], var_name, vdata, ClassVar_e))
			{
				class_id = current_id;
				break;
			}

			current_id = cdata[Class_SuperId];

		} while (current_id != CNull);
	}

	if (class_id == CNull)
	{
		ArrayGetArray(g_aClasses, _:odata[Object_ClassId], cdata);
		log_error(AMX_ERR_NATIVE, "[OO] Variable (%s) not found in class (%s)", var_name, cdata[Class_Name]);
		return 0;
	}

	static actual_name[64];
	formatex(actual_name, charsmax(actual_name), "%s@%s", class, var_name);

	if (vdata[ClVar_CellSize] > DT_CELL)
	{
		new size = (num_params == 4) ? get_param_byref(4) : vdata[ClVar_CellSize];

		new array = new[size];
		get_array(3, _$array[0], size);

		TrieSetArray(odata[Object_Data], actual_name, _$array[0], size);
		return 1;
	}
	else if (vdata[ClVar_CellSize] == DT_CELL)
	{
		TrieSetCell(odata[Object_Data], actual_name, get_param_byref(3));
		return 1;
	}

	return 0;
}

// bool:oo_parent_of(Class:class_id, Class:super_id)
public bool:native_parent_of(plugin_id, num_params)
{
	new Class:class_id = Class:get_param(1);
	new Class:super_id = Class:get_param(2);

	return IsParentOf(class_id, super_id);
}

// oo_this()
public Object:native_this(plugin_id, num_params)
{
	if (IsStackEmpty(g_ThisStack))
		return @null;
	
	new Object:this;
	PopStackCell(g_ThisStack, this);
	PushStackCell(g_ThisStack, this);

	return this;
}

// oo_get_class_name(Class:class_id, output, len)
public native_get_class_name(plugin_id, num_params)
{
	new Class:class_id = Class:get_param(1);
	if (class_id < 0 || class_id >= g_ClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[OO] Invalid class id (%d)", class_id);
		return;
	}

	static cdata[Class_e];
	ArrayGetArray(g_aClasses, class_id, cdata);

	set_string(2, cdata[Class_Name], get_param(3));
}

bool:IsParentOf(Class:class_id, Class:super_id)
{
	static cdata[Class_e];
	new Class:current_id = class_id;
	
	do {

		ArrayGetArray(g_aClasses, _:current_id, cdata)
	
		if (current_id == super_id)
			return true;
		
		current_id = cdata[Class_SuperId];

	} while (current_id != CNull);

	return false;
}

CallFuncEnd(start_param, const params[], num_params)
{
	enum _:BYREF_E
	{
		BYREF_PARAM,
		BYREF_VALUE
	};

	static byref[64][BYREF_E];
	new num = 0;

	new p_format = 0;

	for (new param = start_param; param <= num_params; param++)
	{
		switch (params[p_format])
		{
			case FP_CELL, FP_FLOAT:
			{
				callfunc_push_int(get_param_byref(param));
			}
			case FP_VAL_BYREF:
			{
				byref[num][BYREF_PARAM] = param;
				byref[num][BYREF_VALUE] = get_param_byref(param);
				callfunc_push_intrf(byref[num][BYREF_VALUE]);
				num++;
			}
			case FP_STRING:
			{
				static str[256];
				get_string(param, str, charsmax(str))
				callfunc_push_str(str);
			}
			case FP_ARRAY:
			{
				callfunc_push_int(get_param(param));
			}
			default:
			{
				log_error(AMX_ERR_GENERAL, "[OO] Error parameter type (%d)", params[p_format]);
				return 0;
			}
		}
		
		++p_format;
	}

	new ret = callfunc_end();

	for (new i = 0; i < num; i++)
	{
		set_param_byref(byref[i][BYREF_PARAM], byref[i][BYREF_VALUE]);
	}

	return ret;
}