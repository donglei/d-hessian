module hessian.HttpServer;

import tango.io.Stdout, tango.core.Traits;

import  tango.core.Thread;
import  tango.net.Socket;
import  mango.net.servlet.Servlet;
import  mango.net.servlet.ServletProvider,mango.net.servlet.ServletContext;
import  mango.net.http.server.HttpServer,
mango.net.http.server.HttpProvider;

import meta.nameof, meta.string;

import hessian.Input:
Input;
import hessian.Output:
Output;
import hessian.Common;

private:

/*
Template used to generate the call string from the
function alias. Recursively construct the call string for each param
based on its type
*/
template callstr (alias T,int i = 0)
{
    static if (i == 0 && ParameterTupleOf!(T).length > 0)
        {
            const char[] callstr =  "(cast(C)classinstance)." ~symbolnameof!(T) ~ "(" ~"input.deserialize!("~ParameterTupleOf!(T)[i].stringof~")"~ callstr!(T,i+1);
        }
    else
        static if (i >=1 && i < ParameterTupleOf!(T).length)
        {
            const char[] callstr = ",input.deserialize!("~ParameterTupleOf!(T)[i].stringof~")" ~ callstr!(T,i+1);
        }
    else
        static if ( i == ParameterTupleOf!(T).length && i > 0)
            const char[] callstr = ");";
        else
            static if (i == 0 && ParameterTupleOf!(T).length == 0 )
                const char[] callstr = "(cast(C)classinstance)." ~symbolnameof!(T) ~ "();";
}

/*
Abstract class for a function wrapper
*/
abstract class prototype
    {
        // function name as string
        const char[] name;
        // overloaded () operator that processes a Hessian request
        // and calls the target method on the ginven class instance
        char[] opCall(ubyte[] b,Object target);
    }

/*
Generic implementation for the prototype class.
This constructs the call string at compile time from
function alias.
*/
class method (alias T, C) : prototype
    {
        const char[] path = qualifiednameof!(C);
        const char[] module_name = path[0..$ - symbolnameof!(C).length - 1];
        // we'll import the module of the target class for other symbol used
        // some attention should be needed so only public imports are used
        // on this module.
        mixin("private import " ~ module_name ~ ";");
        // fill the function name
        const char[] name = symbolnameof!(T);
        // overide the () operator and process the input byte stream
        // from a client request. This will return the function result as
        // a Hessian stream.
        override char[] opCall (ubyte[] buffer,Object classinstance)
        {
            alias ReturnTypeOf!(T) type;
            scope input = new Input!(T,void)(buffer);
            input.startCall;
            scope output = new Output!(T);
            output.startReply;
            try
                {
                    static if ( !is (type == void))
                        {
                            type result;
                            // mixin the generated function call string
                            mixin("result = " ~ callstr!(T));
                            output.serialize(result);
                        }

                    else
                        {
                            mixin (callstr!(T));
                            output.serialize(null);
                        }
                }
            catch (Exception e)
                {
                    output.sendException (ExceptionMessage.ServiceException,e);
                }
            output.endStream;
            return output.buffer;
        }

    }

/*
Class that holds a map with binded methods for a given API class.
*/
class Service(C)
    {
        // Map of binded metods with the method name string as key
        prototype[char[]] methodMap;
        // The API class
        C api;

        this()
        {
            static assert (is(C == class),"Only classes are allowed as base api");
            api = new C;
        }
        // bind the function alias to a method class
        void bind(alias T)()
        {
            auto m = new method!(T,C);
            methodMap[m.name] = m;
        }

        // dummy alias
        char[] nil (){return "";}

        // process the incoming byte stream and lookup the called method in the
        // map. Throw remote exception for missing methods.
        char[] process (ubyte[] buffer)
        {
            scope input = new Input!(nil,void)(buffer);
            // read the function name
            char[] methodname = input.startCall;
            // if method found process the request
            if(methodname in methodMap)
                {
                    auto method = methodMap[methodname];
                    return method(buffer,api);
                }
            // else serialize an Exception (NoSuchMethodException) and send it to the client
            else
                {
                    scope output = new Output!(nil);
                    output.startReply;
                    output.sendException(ExceptionMessage.NoSuchMethodException,"Method '"~methodname ~"' doesn't exist");
                    output.endStream;
                    return output.buffer;
                }

        }

    }

// Mango Servlet responsable for processing Http Post requests
class HessianServlet (C) : Servlet
    {
        private Service!(C) registry;

        this(Service!(C) svc)
        {
            registry = svc;
        }

        void service (IServletRequest request, IServletResponse response)
        {
            request.headers;
            auto buffer = cast(ubyte[])request.buffer.slice;
            auto res = registry.process(buffer);
            response.setContentType("binary/octet-stream");
            response.setContentLength(res.length);
            response.buffer.append(res);

        }
    }

public:
// A context maps a given Http url to an API class
class Context(C)
    {
        Service!(C) registry;
        this(char[] path,ServletProvider provider)
        {
            registry = new Service!(C);
            auto servlet = new HessianServlet!(C)(registry);
            auto root = provider.addContext (new ServletContext (""));
            provider.addMapping (path, provider.addServlet (servlet, "hessian",root));
        }
        void bind(alias T)()
        {
            registry.bind!(T);
        }

    }

// Minimal Http Server using Mango library
class Server
    {
    private:
        HttpServer server;
        ServletProvider provider;

    public:
        this (int port = 80)
        {
            provider = new ServletProvider;
            server = new HttpServer (provider, new InternetAddress (port), 8, 100);
        }
        // Add new context to this server mapping
        // urls to classes
        Context!(T) addContext(T)(char[] path)
        {
            return new Context!(T)(path,provider);
        }
        // start processing Http requests
        void start()
        {
            server.start;
            Thread.sleep;
        }
    }
