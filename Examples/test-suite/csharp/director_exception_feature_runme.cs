using System;
using director_exception_featureNamespace;

public class director_exception_feature_Consts {
    public const String PINGEXCP1 = "Ping MyLanguageException1";  // should get translated through an int on ping
    public const String PINGEXCP2 = "Ping MyLanguageException2";

    public const String PONGEXCP1 = "Pong MyLanguageException1";
    public const String PONGEXCP2 = "Pong MyLanguageException2";
    public const String PONGUNEXPECTED = "Pong MyLanguageUnexpected";
    public const String TRANSLATED_NRE = "Pong Translated NRE";

    public const String GENERICPONGEXCP1 = "GenericPong Wrapped MyLanguageException1";
    public const String GENERICPONGEXCP2 = "GenericPong New Application Exception";
    public const String GENERICPONGEXCP3 = "GenericPong New Exception Without String ctor";
    // Returned message has tag to highlight that the exception cannot be used with SetPendingExceptionDynamic
    public const String GENERICPONGEXCP3_OUT = 
        "<InvalidException:UnconstructibleException>: " + GENERICPONGEXCP3;
}

// No concept of checked vs unchecked exceptions in C#.  

// An exception not mentioned or wrapped by the swig interface,
// to reconstruct using generic DirectorException handling
public class NewApplicationException : ApplicationException {
    public NewApplicationException(String s) : base(s) {
    }
}

// an exception not constructible from a string,
// to test DirectorException fallback reconstruction
public class UnconstructibleException : ApplicationException {
    public int extrastate;
    public UnconstructibleException(int a, String s) : base(s) {
        extrastate = a;
    }
}

public class director_exception_feature_MyFooDirectorImpl : Foo {

    public director_exception_feature_MyFooDirectorImpl() { 
    }
    /*throws MyLanguageException1, MyLanguageException2*/
    public override String ping(int exceptionindex)  {
        Console.WriteLine("MyDirectorFooImpl ping() called with " + exceptionindex);
        if (exceptionindex == 1) 
            throw new MyLanguageException1(director_exception_feature_Consts.PINGEXCP1);
        if (exceptionindex == 2) 
            throw new MyLanguageException2(director_exception_feature_Consts.PINGEXCP2);
        return "Ping director returned";
    }
    /*throws MyLanguageException1, MyLanguageException2, MyLanguageUnexpected*/
    public override String pong(int exceptionindex) {
        Console.WriteLine("MyDirectorFooImpl pong() called with " + exceptionindex);
        if (exceptionindex == 1) 
            throw new MyLanguageException1(director_exception_feature_Consts.PONGEXCP1);
        if (exceptionindex == 2) 
            throw new MyLanguageException2(director_exception_feature_Consts.PONGEXCP2);
        if (exceptionindex == 3) 
            throw new MyLanguageUnexpected(director_exception_feature_Consts.PONGUNEXPECTED);
        // should be translated to ::Unexpected
        if (exceptionindex == 4) 
            throw new NullReferenceException(director_exception_feature_Consts.TRANSLATED_NRE);  
        return "Pong director returned";
    }
    /* throws MyLanguageException1, NewCheckedException, UnconstructibleException */
    public override String genericpong(int exceptionindex) {
        Console.WriteLine("MyDirectorFooImpl genericpong() called with " + exceptionindex);
        if (exceptionindex == 1) 
            throw new MyLanguageException1(director_exception_feature_Consts.GENERICPONGEXCP1);
        if (exceptionindex == 2) 
            throw new NewApplicationException(director_exception_feature_Consts.GENERICPONGEXCP2);
        if (exceptionindex == 3)
            throw new UnconstructibleException(1, director_exception_feature_Consts.GENERICPONGEXCP3);
        return "GenericPong director returned";
    }
}

public class runme {

    public static void fail(String msg) {
        Console.WriteLine("Failed: " +msg); Environment.Exit(1);
    }
    public static void failif(bool cond, String msg) {
        if (cond) fail(msg);
    }

    static void Main() {
        try {
            Bar b = new Bar(new director_exception_feature_MyFooDirectorImpl());
            try {  b.ping(0); } catch (Exception e) 
                { fail("Exception should not have been thrown: " + e + " from ping(0)");  }
            try {  b.ping(1); fail("No exception thrown in Foo->Bar.ping(1)"); } catch (MyLanguageException1 e) 
                // Should say "Threw some integer", see director_exception_feature.i  Foo::ping throws a "1"
                { failif( ! "Threw some integer".Equals(e.Message), "Ping exception not translated through int: '" + e.Message + "'"); }
            try {  b.ping(2); fail("No exception thrown in Foo->Bar.ping(2)"); } catch (MyLanguageException2 e) 
                { failif( ! director_exception_feature_Consts.PINGEXCP2.Equals(e.Message), "Expected exception has unexpected message: '" + e.Message + "'"); }

            Console.WriteLine("\n\n**************************************************************** TODO remove\n\n");

            try {  b.pong(0); } catch (Exception e) 
                { fail("Exception should not have been thrown: " + e + " from pong(0)");  }
            try {  b.pong(1); fail("No exception thrown in pong(1)"); } catch (MyLanguageException1 e) 
                { failif( ! director_exception_feature_Consts.PONGEXCP1.Equals(e.Message), "Expected exception has unexpected message: '" + e.Message + "'"); }
            try {  b.pong(2); fail("No exception thrown in pong(2)");} catch (MyLanguageException2 e) 
                { failif( ! director_exception_feature_Consts.PONGEXCP2.Equals(e.Message),  "Expected exception has unexpected message: '" + e.Message + "'"); }
            try {  b.pong(3); fail("No exception thrown in pong(3)");} catch (MyLanguageUnexpected e) 
                { failif( ! director_exception_feature_Consts.PONGUNEXPECTED.Equals(e.Message),  "Expected exception has unexpected message: '" + e.Message + "'"); }
            try {  b.pong(4); fail("No exception thrown in pong(4)"); } catch (MyLanguageUnexpected e) 
                { failif( ! director_exception_feature_Consts.TRANSLATED_NRE.Equals(e.Message),  "Expected exception has unexpected message: '" + e.Message + "'"); }

            Console.WriteLine("\n\n**************************************************************** TODO remove\n\n");

            try {  b.genericpong(0); } 
            catch (Exception e) { 
                fail("Exception should not have been thrown: " + e + " from genericpong(0)");  
            }
            try {  b.genericpong(1); fail("No exception thrown in genericpong(1)"); } 
            catch (MyLanguageException1 e) { 
                failif( ! director_exception_feature_Consts.GENERICPONGEXCP1.Equals(e.Message), "Expected exception has unexpected message: '" + e.Message + "'"); 
            }
            try {  b.genericpong(2); fail("No exception thrown in genericpong(2)");} 
            catch (NewApplicationException e) { 
                failif( ! director_exception_feature_Consts.GENERICPONGEXCP2.Equals(e.Message),  "Expected exception has unexpected message: '" + e.Message + "'"); 
            }
            try {  b.genericpong(3); fail("No exception thrown in genericpong(3)");} 
            catch (ApplicationException e) { 
                failif (! e.GetType().Equals(typeof(ApplicationException)), "Exception " + e + " is not exactly ApplicationException");
                failif( ! director_exception_feature_Consts.GENERICPONGEXCP3_OUT.Equals(e.Message),  "Expected exception has unexpected message: '" + e.Message + "'"); 
            }
        }
        catch (Exception e) {
            Console.WriteLine(e.ToString());
            fail("Unexpected exception thrown or exception not mapped properly");
        }

    }
}

