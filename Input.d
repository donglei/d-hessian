module hessian.Input;

import tango.io.Stdout, tango.io.Buffer, tango.io.protocol.Reader,
tango.io.protocol.Writer,
tango.core.Traits,
tango.io.protocol.EndianProtocol,
tango.core.Array,
tango.util.time.DateTime,
tango.util.time.WallClock;

import meta.nameof;

import hessian.Common;

/*
* A generic exception used for any protocol fault
*/
class HessianError:Exception
    {
        override this(char[] msg)
        {
            super(msg);
            Stderr ("Hessian protocol error: ") (msg);
        }
    }
class RemoteException:Exception
    {
        char[] code;
        char[] message;
        override this(char[] msg)
        {
            super(msg);
            message = msg;
        }
    }

/*
* A generic class used for deserializing incoming data.
* This class is used for both incoming calls (server mode)
* and for remote function call's response
*/
class Input (alias func, Type)
    {
    private:
        Reader reader;
        char code;

    public:
        /*
        * Ctor taking a byte array and setting up a
        * reader with big endian encoding
        */
        this (ubyte[] response)
        {
            auto buffer= new Buffer(response);
            auto endian = new EndianProtocol(buffer);
            this.reader = new Reader(endian);
        }

        void startReply()
        {
            reader (code);
            if(code == Control.startReply)
                reader.buffer.skip(2);
            else
                throw new HessianError("invalid reply, expected 'r' instead of" ~code~"");
        }
        char[] startCall ()
        {
            reader (code);
            if(code == Control.startCall)
                {
                    reader.buffer.skip(2);
                    return deserialize!(char[]);
                }
            else
                throw new HessianError("invalid call, expected 'c' instead of" ~code~"");
        }

        /*
        * Template function used to deserialize data based on a type provided at compile time
        * It uses a combination of compile time and runtime parsing of the
        * Hessian serialized stream.
        */
        T deserialize(T = Type)()
        {
            reader (code);
            T result;
            if (infereType!(T) == code || code == Types._false || code == Control.fault || Control.endStream)
                {

                    switch (code)
                        {
                        case Types._int:
static if (is(T : int) )
                                {
                                    result = cast(T)readType!(int);
                                }
                            break;
                        case Types._date:
                            static if (is (T == DateTime))
                                {
                                    ulong ts = readType!(ulong);
                                    result = DateTime((ts * Time.TicksPerMillisecond) + Time.TicksTo1970);
                                }
                        case Types._long:
static if (is(T : long))
                                {
                                    result = cast(T)readType!(long);
                                }
                            break;
                        case Types._double:
static if (is (T : double) || is (T : float))
                                {

                                    result = cast(T) readType!(double);
                                }

                            break;
                        case Types._true:
                        case Types._false:
static if ( is (T : bool))
                                {
                                    result = (code == Types._true ? true:false);
                                }
                            break;
                        case Types._xml:
                        case Control.method:
                        case Types._string:
static if (!isAssocArrayType!(T) &&( is (T : char[]) || is (T : byte[])) )
                                {
                                    result = cast(T) byteStream!(T);
                                }
                            break;
                        case Types._vector:
                            static if (!isAssocArrayType!(T) && isDynamicArrayType!(T) )
                                {
                                    result = cast(T)readVector!(T);
                                }
                            break;
                        case Types._map:
                            static if (isAssocArrayType!(T) )
                                {
                                    result = cast(T)readMap!(T);
                                }
                            else
                                static if (is (T == class) || is(T == struct) && !is (T == DateTime))
                                    {
                                        result = cast(T)readStruct!(T);
                                    }
                            break;
                        case Types._null:
                            static if (!is (T==struct))
                                result = cast(T)null;
                        case Control.endStream:
                            break;
                        case Control.fault:
                            throw readException();
                            break;
                        default:
                            throw new HessianError ("unexpected remote type: " ~code~ " , expecting "~T.stringof);
                        }
                }
            else
                throw new HessianError("Return type of '"~ qualifiednameof!(func) ~"' doesn't match remote type: "~code~"");
            return result;
        }

        RemoteException readException()
        {
            // skip the 'code' string
            deserialize!(char[]);
            // read the actual code
            char[] code = deserialize!(char[]);
            // skip the 'message' string
            deserialize!(char[]);
            // read the actual message
            char[] message = deserialize!(char[]);

            RemoteException ex = new RemoteException(code ~". " ~ message);
            ex.code = code;
            ex.message = message;
            return ex;

        }

        T readMap(T)()
        {
            T map;
            typeof(T.init.keys[0]) key;
            typeof(T.init.values[0]) value;
            reader (code);
            if(code == Control.type)
               byteStream!(char[]);
            else
                reader.buffer.skip(-1);
            while (true)
                {
                    key = deserialize !(typeof(key));
                    value = deserialize !(typeof(value));
                    if(code != Control.endStream)
                        {
                            map[key]=value;
                        }

                    else
                        break;
                }

            return map;
        }

        T readStruct (T)()
        {
            T st;
            static if (is (T == class))
                st = new T;
            char[] key;

            reader (code);
            if(code == Control.type)
                byteStream!(char[]);
            else
                reader.buffer.skip(-1);
            foreach (i,p; st.tupleof)
            {
                key = deserialize!(char[]);
                typeof(p) value = deserialize!(typeof(p));
                if(code != Control.endStream)
                    {
                        char[] fieldName = st.tupleof[i].stringof;
                        auto index = rfind(st.tupleof[i].stringof,'.');
                        fieldName = fieldName[index+1 ..$];
                        if (key == fieldName)
                            {
                                st.tupleof[i] = value;
                            }
                    }
                else
                    break;
            }
            return st;
        }

        T readVector(T)()
        {
            T vec;
            alias typeof(T[0]) eltype;
            eltype el;
            uint len;

            reader (code);

            if(code == Control.type)
                {
                    byteStream!(char[]);
                }
            else
                reader.buffer.skip(-1);
            reader (code);

            if(code == Control.length)
                {
                    len = readType!(int);
                }
            else
                reader.buffer.skip(-1);

            if(len > 0)
                {
                    vec.length = len;
                    foreach (i,k;vec)
                    vec[i] = deserialize!(eltype);

                }
            else
                {
                    int i = 1;
                    while(true)
                        {
                            el = deserialize!(eltype);
                            if(code != Control.endStream)
                                {
                                    vec.length = i++;
                                    vec[$-1] = el;
                                }
                            else
                                break;
                        }
                }
            return vec;

        }

        T readType(T)()
        {
            T type;
            reader (type);
            return type;

        }

        T byteStream (T)()
        {
            ushort len;
            len = readType!(short);
            T t= cast(T)(reader.buffer.slice(len));
            return t;
        }
    }
