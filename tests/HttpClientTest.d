module hessian.tests.HttpClientTest;

import hessian.HttpProxy:
HttpProxy;

import hessian.tests.ITest;

import tango.io.Stdout,
tango.util.time.DateTime,
tango.util.time.Date,
tango.io.Console,
tango.text.locale.Locale;

alias char[] string;

void main()
{
    scope service = new HttpProxy("http://localhost:5667/test/hessiantest");

    auto add
        = &service.proxy!(ITest.add
                         );
    auto testConcatString = &service.proxy!(ITest.testConcatString);

    auto testChar = &service.proxy!(ITest.testChar);

    auto testStringToBoolean = &service.proxy!(ITest.testStringToBoolean);
    auto testStringToLong = &service.proxy!(ITest.testStringToLong);
    auto testStringToDouble = &service.proxy!(ITest.testStringToDouble);
    auto testStringToShort = &service.proxy!(ITest.testStringToShort);
    auto testStringToInt = &service.proxy!(ITest.testStringToInt);
    auto testIntToString = &service.proxy!(ITest.testIntToString);
    auto testIntArrToString = &service.proxy!(ITest.testIntArrToString);
    auto testStringArrToInt = &service.proxy!(ITest.testStringArrToInt);
    auto testLongArrToString = &service.proxy!(ITest.testLongArrToString);
    auto testDoubleToString = &service.proxy!(ITest.testDoubleToString);
    auto testHashMap = &service.proxy!(ITest.testHashMap);
    auto testParamObject = &service.proxy!(ITest.testParamObject);
    auto testDateToString = &service.proxy!(ITest.testDateToString);
    auto testStringToDate = &service.proxy!(ITest.testStringToDate);

    Stdout ("Result: ")  (add
                          (245,5)).newline;
    Stdout ("Result: ")  (testConcatString("Hello "," World!")).newline;
    Stdout ("Result: ")  (testIntArrToString([88,44,66,int.max])[0]).newline;
    Stdout ("Result: ")  (testChar('0')).newline;
    Stdout ("Result: ")  (testStringToBoolean("true")).newline;
    Stdout ("Result: ")  (testStringToLong("100")).newline;
    Stdout ("Result: ")  (testStringToDouble("22,3")).newline;
    Stdout ("Result: ")  (testStringToShort("16535")).newline;
    Stdout ("Result: ")  (testStringToInt(""~short.max.stringof~"")).newline;
    Stdout ("Result: ")  (testIntToString(int.max)).newline;

    Stdout ("Result: ")  (testStringArrToInt(["22","55","455"])).newline;
    Stdout ("Result: ")  (testLongArrToString([1L,44,long.max])).newline;
    Stdout ("Result: ")  (testDoubleToString(56.8)).newline;
    Stdout ("Result: ")  (testHashMap([1,2,3],["a","b","c"])).newline;

    ParamObject p = new ParamObject;

    char[][char[]] map;
    map["1"] = "a";
    map["2"] = "b";
    map["3"] = "c";

    p.hashVar  = map;

    Stdout ("Result: ")  (testParamObject(p)).newline;

    Stdout ("Result: ")  (testDateToString(DateTime.now)).newline.flush;

    auto layout = new Locale (Culture.current);

    Stdout ("Result: ") (testStringToDate("Sun, 06 Nov 1994 08:49:37 GMT").year) ();

}
