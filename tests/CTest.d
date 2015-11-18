module hessian.tests.CTest;

// use public imports here so the types are available to the mixin
// code in the HttpServer class
public import
tango.util.time.DateTime,
tango.util.time.Date, tango.io.Stdout;

import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;
import TimeStamp = tango.text.convert.TimeStamp;

public import hessian.tests.ITest;

/*
  Server side API interface implementation
*/
class Test: ITest
    {
        int add
            (int a, int b)
            {
                return a + b;
            }
        int testChar(int a)
        {
            return a;
        }
        string testConcatString(string param1, string param2)
        {
            return param1 ~ param2;
        }
        bool testStringToBoolean(string param)
        {
            return param == "true" ? true:false;
        }
        long testStringToLong(string param)
        {
            return Integer.parse(param);
        }
        float testStringToDouble(string param)
        {
            return Float.parse(param);
        }
        short testStringToShort(string param)
        {
            return Integer.parse(param);
        }
        int testStringToInt(string param)
        {
            return Integer.parse(param);
        }
        string testIntToString(int param)
        {
            return Integer.toUtf8(param);
        }
        string[] testIntArrToString(int[] param)
        {
            string[] arr;
            arr.length = param.length;
            foreach(e,i;param)
            arr[e] = Integer.toUtf8(i);
            return arr;

        }
        int[] testStringArrToInt(string[] param)
        {
            int[] arr;
            arr.length = param.length;
            foreach(e,i;param)
            arr[e] = Integer.convert(i);
            return arr;
        }
        string[] testLongArrToString(long[] param)
        {
            string[] arr;
            arr.length = param.length;
            foreach(e,i;param)
            arr[e] = Integer.toUtf8(i);
            return arr;
        }

        string testDoubleToString(double param)
        {
            return Float.toUtf8(param);
        }

        string[string] testHashMap(int [] keys, string [] values)
        {
            string[string] map;
            foreach (i,k;keys)
            map[Integer.toUtf8(k)] = values[i];
            return map;
        }

        ParamObject testParamObject(ParamObject param)
        {
            param.stringVar = "ok";
            return param;
        }

        DateTime testStringToDate(string param)
        {
            return DateTime(TimeStamp.parse(param));
        }

        string testDateToString(DateTime param)
        {
            return TimeStamp.toUtf8(DateTime.now.time);
        }
    }
