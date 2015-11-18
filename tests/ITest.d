module hessian.tests.ITest;

import
tango.util.time.DateTime,
tango.util.time.Date;

alias char[] string;

public class ParamObject
    {
        char[] test ;
        char[] stringVar;
        char[][char[]] hashVar;
    }

interface ITest
    {
        int add
            (int a, int b);
        int testChar(int a);
        string testConcatString(string param1, string param2);
        bool testStringToBoolean(string param);
        long testStringToLong(string param);
        float testStringToDouble(string param);
        short testStringToShort(string param);
        int testStringToInt(string param);
        string testIntToString(int param);
        string[] testIntArrToString(int[] param);
        int[] testStringArrToInt(string[] param);
        string[] testLongArrToString(long[] param);

        string testDoubleToString(double param);

        string[string] testHashMap(int [] keys, string [] values);

        ParamObject testParamObject(ParamObject param);

        DateTime testStringToDate(string param);
        string testDateToString(DateTime param);
    }
