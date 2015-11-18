module hessian.tests.HttpServerTest;
import hessian.HttpServer:
Server;
public import hessian.tests.CTest;
public import hessian.tests.ITest;

import tango.core.Traits,tango.io.Stdout,tango.text.convert.Integer;

alias char[] string;

void main()
{

    auto server = new Server(5667);

    auto context = server.addContext!(Test)("/test/hessiantest");
    context.bind!(Test.add);
    context.bind!(Test.testConcatString);

    context.bind!(Test.testChar);

    context.bind!(Test.testStringToBoolean);
    context.bind!(Test.testStringToLong);
    context.bind!(Test.testStringToDouble);
    context.bind!(Test.testStringToShort);
    context.bind!(Test.testStringToInt);
    context.bind!(Test.testIntToString);
    context.bind!(Test.testIntArrToString);
    context.bind!(Test.testStringArrToInt);
    context.bind!(Test.testLongArrToString);
    context.bind!(Test.testDoubleToString);
    context.bind!(Test.testHashMap);
    context.bind!(Test.testParamObject);
    context.bind!(Test.testDateToString);
    context.bind!(Test.testStringToDate);
    server.start;

}
