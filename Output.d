module hessian.Output;

import tango.io.Stdout,
tango.core.Traits,
tango.core.Array,
tango.util.time.Date,
tango.util.time.DateTime,
tango.util.time.WallClock,
tango.util.time.Clock,
tango.io.Buffer,
tango.io.protocol.Writer,
tango.io.protocol.EndianProtocol;

import meta.nameof;

import hessian.Common;

/*
  Serialize both remote method calls and method response
  based on the type of the params
*/
class Output (alias func)
    {
        char[] buffer;
        final char[] method;

        // start the call stream
        void startCall()
        {
            method = symbolnameof!(func);
            buffer ~=  Control.startCall;
            buffer ~=0;
            buffer ~= 1;
            buffer ~= Control.method;
            toBytes(cast(ushort)method.length);
            buffer ~= method;
        }
        // start the reply stream
        void startReply()
        {
            buffer ~= Control.startReply;
            buffer ~= 0;
            buffer ~= 1;

        }

        // end stream
        void endStream ()
        {
            buffer ~= Control.endStream;
        }
        // serialize an Exception
        void sendException(char[] msg,char[] detail)
        {
            buffer ~= Control.fault;
            serialize("code");
            serialize(msg);
            serialize("message");
            serialize(detail);
        }
        void sendException(char[] msg,Exception e)
        {
            sendException(msg,e.msg);
        }

        // function template that does the serialization based on the supplied type
        void serialize(T) (T t)
        {
            // basic types
static if ( is (T:int) && T.sizeof <=4 && !is (T == float) && !is(T == bool) )
                {
                    buffer ~= Types._int;
                    toBytes(cast(int)t);
                }
            else
                static if ( is( T == bool) )
                    {
                        if (t)
                            buffer ~= Types._true;
                        else
                            buffer ~= Types._false ;
                    }
                else
static if ( is(T : long ))
                        {
                            buffer ~= Types._long;
                            toBytes(t);
                        }
                    else
                        static if ( is (T == float) || is (T == double) )
                            {
                                buffer ~= Types._double;
                                scope buf = new Buffer(8);
                                scope endian = new EndianProtocol(buf);
                                scope write = new Writer(endian);

                                double res = cast(double)t;
                                write(res);
                                buffer ~= cast(char[])buf.slice;
                            }
                        else
                            static if (is (T == struct) && !is (T == DateTime))
                                {
                                    buffer ~= Types._map;
                                    buffer ~= Control.type;
                                    char[] type = T.stringof;
                                    toBytes(cast(ushort)type.length);
                                    buffer ~= type;
                                    foreach (i,p; t.tupleof)
                                    {
                                        char[] fieldName = t.tupleof[i].stringof;
                                        auto index = rfind(t.tupleof[i].stringof,'.');
                                        fieldName = fieldName[index+1 ..$];
                                        serialize(fieldName);
                                        serialize (p);
                                    }
                                    buffer ~= Control.endStream;
                                }
                            else
                                static if (is (T == DateTime))
                                    {
                                        buffer ~= Types._date;
                                        ulong time = Clock.fromDate (WallClock.toDate(t.time));
                                        ulong ts = (time - Time.TicksTo1970 )/Time.TicksPerMillisecond;
                                        toBytes (ts);
                                    }
            // ref types

                                else
static if ( is (T:void *) || isAssocArrayType!(T) || isReferenceType!(T) || isStaticArrayType!(T) || isDynamicArrayType!(T))
                                        {

                                            if ( t is null)
                                                buffer ~= Types._null;

static if (is (T:void *))
                                                {
                                                }

                                            else
                                                static if (isAssocArrayType!(typeof(T)))
                                                    {
                                                        if (!(t is null))
                                                            {
                                                                buffer ~= Types._map;
                                                                foreach(k;t.keys)
                                                                {
                                                                    serialize(k);
                                                                    serialize(t[k]);
                                                                }
                                                                buffer ~= Control.endStream;
                                                            }

                                                    }
                                                else

                                                    static if ( isStaticArrayType!(T) || isDynamicArrayType!(T))

                                                        {
static if (is(T : byte[]) || is(T : char[]))
                                                                {
                                                                    if (!(t is null))
                                                                        {
                                                                            buffer ~= is(T : char[])? Types._string : Types._bytes ;
                                                                            toBytes(cast(ushort)t.length);
                                                                            buffer ~= cast(char[])t;
                                                                        }
                                                                }

                                                            else
                                                                {
                                                                    if (!(t is null))
                                                                        {
                                                                            buffer ~= Types._vector;
                                                                            foreach(i;t)
                                                                            {
                                                                                serialize(i);
                                                                            }
                                                                            buffer ~= Control.endStream;

                                                                        }
                                                                }
                                                        }

                                                    else
                                                        static if ( is( T == class))
                                                            {
                                                                if(!(t is null))
                                                                    {

                                                                        buffer ~= Types._map;
                                                                        buffer ~= Control.type;
                                                                        char[] type = T.classinfo.name;
                                                                        toBytes(cast(ushort)type.length);
                                                                        buffer ~= type;
                                                                        foreach (i,p; t.tupleof)
                                                                        {
                                                                            char[] fieldName = t.tupleof[i].stringof;
                                                                            auto index = rfind(t.tupleof[i].stringof,'.');
                                                                            fieldName = fieldName[index+1 ..$];
                                                                            serialize(fieldName);
                                                                            serialize (p);
                                                                        }
                                                                        buffer ~= Control.endStream;
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
    private:
        void toBytes(T) (T t)
        {
            int size = T.sizeof * 8;
            for (int i = size - 8; i >= 0; i-=8)
                {
                    buffer ~= cast(ubyte)(t >> i);
                }

        }

    }
