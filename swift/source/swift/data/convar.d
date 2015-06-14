module swift.data.convar;

import std.string : format;
import swift.log.log;

struct IConVar {
	string name;
}

class ConVar {
public:
	this(string name, TypeInfo type, void * data) {
		this.name = name;
		this.type = type;
		this.data = data;

		//TODO: Register ConVar in a manager
		Log.MainLogger.Info("'%s' has been registered with type %s and data location %X", name, type, data);
	}

	ref T Get(T)() {
		return *Ptr!(T)();
	}

	T * Ptr(T)() {
		static if (is(type == typeof(T)) || is(type == T))
			static assert(0, "ConVar is not " ~ typeid(T).stringof);
		return cast(T *)data;
	}

	alias String = Get!(string);
	alias Long = Get!(long);
	alias Real = Get!(real);
	alias Bool = Get!(bool);

	alias StringPtr = Ptr!(string);
	alias LongPtr = Ptr!(long);
	alias RealPtr = Ptr!(real);
	alias BoolPtr = Ptr!(bool);
	
	@property TypeInfo Type() {
		return type;
	}
private:
	string name;
	TypeInfo type;
	void * data;
}


mixin template BaseConVar() {
	/*foreach(var; __traits(derivedMembers, mixin(__MODULE__))) {
		foreach(attr; __traits(getAttributes, mixin(var))) {
			string type = typeof(mixin(var)).stringof;
			log.Severe!(BaseConVar)("auto %s_ConVar = new ConVar(\"%s\", \"%s\", 0x%X);", var, attr.name, type, &mixin(var));
		}
	}*/

	static string FindAllConVar(alias T)() {
		//func is the functions body
		string func = "static bool __convar_registered__ = false;
		static this() {
        import std.stdio;
		if (__convar_registered__) return;
		";
		func ~= FindAllConVar_GetVar!(T);
		func ~= "__convar_registered__ = true;
		}";

		return func;
	}

	static string FindAllConVar_RegisterConVar(alias varname, alias var, alias name, alias type)() {
		return format("auto %s_ConVar = new ConVar(\"%s\", typeid(%s), cast(void *)&%s);", varname, name, type, var);
	}

	static string FindAllConVar_GetVarStruct(alias T, alias T_)() {
		string result = "";
		//Bad code, but only way to get a string of the name ----> typeof(mixin(T)).stringof~"."~var

		foreach(var; __traits(allMembers, typeof(mixin(T)))) {
			static if (	__traits(compiles, __traits(getMember, typeof(mixin(T)), var))) {
				foreach(attr; __traits(getAttributes, __traits(getMember, typeof(mixin(T)), var))) {
					static if (is(typeof(attr) == IConVar)) {
						static if(is(typeof(__traits(getMember, typeof(mixin(T)), var)) == struct) ||
						          is(typeof(__traits(getMember, typeof(mixin(T)), var)) == class)) {
							debug(Convar_GetVar)
								pragma(msg, "IsStruct-struct: ", T~"."~var);
							result ~= FindAllConVar_GetVarStruct!(T~"."~var, T_~"_"~var);
						} else {
							debug(Convar_GetVar)
								pragma(msg, "IsNotStruct-struct: ", T~"."~var);
							string name = T~"."~attr.name;
							string type = typeof(mixin(T~"."~var)).stringof;

							result ~= FindAllConVar_RegisterConVar!(T_~"_"~var, T~"."~var, name, type) ~ "\n";
						}
					}
				}
			}
		}
		return result;
	}

	static string FindAllConVar_GetVar(alias T)() {
		string result = "";

		foreach(var; __traits(allMembers, mixin(T))) {
			static if (	__traits(compiles, __traits(getMember, typeof(mixin(T)), var))) {
				foreach(attr; __traits(getAttributes, mixin(var))) {
					static if (is(typeof(attr) == IConVar)) {
						static if(is(typeof(mixin(var)) == struct) ||
						          is(typeof(mixin(var)) == class)) {
							debug(Convar_GetVar)
								pragma(msg, "IsStruct: ", var);
							result ~= FindAllConVar_GetVarStruct!(var, var);
						} else {
							debug(Convar_GetVar)
								pragma(msg, "IsNotStruct: ", var);
							string name = attr.name;
							string type = typeof(mixin(var)).stringof;

							result ~= FindAllConVar_RegisterConVar!(var, var, name, type) ~ "\n";
						}
					}
				}
			}
		}
		return result;
	}

}

/*
To generate the code to be able to find all you must type:
mixin BaseConVar; //Adds some needed functions
mixin(FindAllConVar!(__MODULE__)); //Runs the search and starts the function generating.
 */