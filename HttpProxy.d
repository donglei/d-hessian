module hessian.HttpProxy;

import tango.io.Stdout,tango.core.Traits,
tango.core.Traits,tango.net.http.HttpPost;

import hessian.Proxy:
Proxy;
/*
* Hessian over Http client implementation
*
*/
class HttpProxy
{
    public HttpPost post;

    this (char[] url)
    {
        post = new HttpPost (url);
    }

    /*
    * Capture the function alias
    * and pass it to the generic Proxy wrapper
    */
    ReturnTypeOf!(T) proxy(alias T)(ParameterTupleOf!(T) paramTypes)
    {
        post.reset;
        Proxy!(T) p;
        return p(&this.write,paramTypes);
    }

private:
    /*
    * Write the char[] buffer as a Http post
    * bug: Tango leaks socket connections using this method
    */
    ubyte[] write(char[] content)
    {
        auto response =  cast(ubyte[])post.write(content, "binary/octet-stream");
        post.close();
        return response;
    }
}
