#if defined _oo_included
	#endinput
#endif
#define _oo_included

#include <oo_const>

native Class:oo_class(const class[], const super[]="");
native Trie:oo_var(Class:class_id, data_type, const var_name[]);
native Trie:oo_method(Class:class_id, MethodType:method_type=MT_METHOD, const method_name[], any:...);
native Class:oo_get_class_id(const class[]);
native Class:oo_get_object_class(Object:object);
native oo_get_class_name(Class:class_id, output[], len);
native Object:oo_new(const class[], const ctor[]="", any:...);
native oo_delete(Object:object);
native oo_call(Object:object, const method_name[], any:...);
native oo_get(Object:object, const var_name[], any:...);
native oo_set(Object:object, const var_name[], any:...);
native oo_parent_of(Class:class_id, Class:super_id);
native Object:oo_this();

forward oo_init();