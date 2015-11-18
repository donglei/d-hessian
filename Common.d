module hessian.Common;

import tango.core.Traits;

enum Types:
char
{
    _int = 'I',
    _true = 'T',
    _false = 'F',
    _long = 'L',
    _double = 'D',
    _date = 'd',
    _string = 'S',
    _xml = 'X',
    _bytes = 'B',
    _null = 'N',
    _map = 'M',
    _vector = 'V'
}

enum Control:
char
{
    startCall = 'c',
    startReply = 'r',
    endStream = 'z',
    fault     = 'f',
    method = 'm',
    type = 't',
    length = 'l'
}

struct ExceptionMessage

    {
static:
        char[] ProtocolException = "ProtocolException";
        char[] ServiceException = "ServiceException";
        char[] NoSuchMethodException = "NoSuchMethodException";
    }

Types infereType(T) ()
{
    // basic types
static if ( is (T:int) && T.sizeof <=4 && !is (T == float) && !is(T == bool) )
        {
            return Types._int;
        }
    else
        static if ( is( T == bool) )
            {

                return Types._true;
            }
        else
static if ( is(T : long ))
                {
                    return Types._long;
                }
            else
                static if ( is (T == float) || is (T == double) )
                    {
                        return Types._double;
                    }
                else
                    static if (is (T == struct) || is (T == class))
                        {
                            return Types._map;
                        }
    // ref types

                    else
                        static if (isAssocArrayType!(T) || isStaticArrayType!(T) || isDynamicArrayType!(T))
                            {
                                static if (isAssocArrayType!(T))
                                    {
                                        return Types._map;

                                    }
                                else

                                    static if ( isStaticArrayType!(T) || isDynamicArrayType!(T))

                                        {
static if (is(T : byte[]) || is(T == char[]))
                                                {
                                                    return is(T == char[])? Types._string : Types._bytes ;
                                                }

                                            else
                                                {
                                                    return Types._vector;
                                                }
                                        }

                                    else
                                        {
                                            static assert (false,"Unsupported Hessian type '"~T.stringof~"' for function "~(&func).stringof[2..$]~"");
                                        }
                            }

    // break on unsuported type at compile time
                        else
                            {
                                static assert (false,"Unsupported Hessian type '"~T.stringof~"' for function "~(&func).stringof[2..$]~"");
                            }

}
