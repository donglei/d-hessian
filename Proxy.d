module hessian.Proxy;

import hessian.Output:
Output;
import hessian.Input:
Input;

import tango.io.Stdout,tango.core.Traits, tango.net.http.HttpPost;
import tango.util.time.Date,tango.util.time.DateTime;
alias char[] string;

/*
* Wrapper for function aliases that serializes and deserializes
* function params and return based on their types.
* This provides a transparent way for calling remote methods
*/
struct Proxy(alias func)
    {
private:
        // aliases for function return type and params types tuples
        alias ReturnTypeOf!(func) returnType;
        alias ParameterTupleOf!(func) paramTypes;

public:
        /*
         * Overload the () operator and capture function alias params tuple.
         * The suplied delegate is used as a generic way to write on various
         * pipes like http or raw sockets
         */
        static returnType opCall(ubyte[] delegate (char[]) pipe,paramTypes params)
                     {
                         // allocate the Output class on stack
                         scope output = new Output!(func);
                         output.startCall();

                         // iterate on each parameter of the function alias
                         foreach(t;params)
                         {
                            // serialize the passed value by deducing it's type
                            output.serialize(t);
                         }
                         output.endStream();
                         // send the serialized data (function call) to the pipe
                         ubyte[] response = cast(ubyte[]) pipe(output.buffer);

                         version (Debug)
                         {
                             Stdout ("request: ")(output.buffer).newline;
                             Stdout ("response: ")(cast(char[])response).newline.flush;
                         }
                         // Capture and deserialize the response of the remote functions
                         returnType result;
                         scope input = new Input!(func,returnType)(response);
                         input.startReply;
                         result = input.deserialize();

                         return result;
                     }
                 }
