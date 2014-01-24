// Director exception feature currently supported by Java and C# language modules
// Test generating with -package or -namespace (global java package,
// C# namespace) WITHOUT the use of %nspace feature (classes are
// "flattened" (dropping namespace) in target language)

%module(directors="1") director_exception_feature

%include <std_except.i>

%{
#if defined(_MSC_VER)
  #pragma warning(disable: 4290) // C++ exception specification ignored except to indicate a function is not __declspec(nothrow)
#endif

#include <string>
%}

%include <std_string.i>

// DEFINE exceptions in header section using std::runtime_error
%{
  #include <exception>
  #include <iostream>

  namespace MyNS {

    struct Exception1 : public std::runtime_error {
      Exception1(const std::string& what):runtime_error(what) {}
    };
      struct Exception2 : public std::runtime_error {
    Exception2(const std::string& what):runtime_error(what) {}
    };
      struct Unexpected : public std::runtime_error {
    Unexpected(const std::string& what):runtime_error(what) {}
    };

  }

%}

// ------------------------------------------------------------------------
// JAVA TYPEMAPS AND FEATURES
// ------------------------------------------------------------------------
#ifdef SWIGJAVA

// Note: director exception handling in java is applied in c++ wrapper jni code

// Add an explicit handler for Foo::ping, mapping one java exception back to an 'int' 
%feature("director:except") MyNS::Foo::ping %{
  jthrowable $error = jenv->ExceptionOccurred();
  if ($error) {
    jenv->ExceptionClear();  // clear java exception since mapping to c++ exception
    if (Swig::ExceptionMatches(jenv,$error,"$packagepath/MyLanguageException1")) {
      throw 1;
    } else if (Swig::ExceptionMatches(jenv,$error,"$packagepath/MyLanguageException2")) {
      std::string msg(Swig::JavaExceptionMessage(jenv,$error).message());
      throw MyNS::Exception2(msg);
    } else {
      std::cerr << "Test failed, unexpected exception thrown: " << 
	Swig::JavaExceptionMessage(jenv,$error).message() << std::endl;
      throw std::runtime_error("unexpected exception in Foo::ping");
    }
  }
%}

// Use default handler on Foo::pong, with directorthrows typemaps

// directorthrows typemaps for java->c++ conversions
%typemap(directorthrows) MyNS::Exception1,MyNS::Exception2,MyNS::Unexpected  %{
  if (Swig::ExceptionMatches(jenv, $error, "$packagepath/$javaclassname")) {
    std::string msg(Swig::JavaExceptionMessage(jenv,$error).message());
    throw $1_type(msg);
  }
%}

// Override the director:except feature so exception specification is not violated
// (Cannot use built-in default of throw DirectorException)
%feature("director:except") MyNS::Foo::pong %{
  jthrowable $error = jenv->ExceptionOccurred();
  if ($error) {
    jenv->ExceptionClear();
    $directorthrowshandlers
    throw ::MyNS::Unexpected(Swig::JavaExceptionMessage(jenv,$error).message());
  }
%}

// Map what() from std::exception to expected java getMessage()
%rename(getMessage) what();  // Rename all what() methods

// TODO 'throws' typemap emitted by emit_action (emit.cxx) has no way
// to get access to language specific special variables like
// $javaclassname or $packagepath  ("director_exception_feature" here) 

// throws typemaps for c++->java exception conversions
%typemap(throws,throws="MyLanguageException1") MyNS::Exception1 %{
  jclass excpcls = jenv->FindClass("director_exception_feature/MyLanguageException1");
  if (excpcls) {
    jenv->ThrowNew(excpcls, $1.what());
   }
  return $null;
%}

%typemap(throws,throws="MyLanguageException1") int %{
  jclass excpcls = jenv->FindClass("director_exception_feature/MyLanguageException1"); 
  if (excpcls) {
    jenv->ThrowNew(excpcls, "Threw some integer");
  }
  return $null;
%}

%typemap(throws,throws="MyLanguageException2") MyNS::Exception2 %{
  jclass excpcls = jenv->FindClass("director_exception_feature/MyLanguageException2"); 
  if (excpcls) {
    jenv->ThrowNew(excpcls, $1.what());
  }
  return $null;
%}

%typemap(throws,throws="MyLanguageUnexpected") MyNS::Unexpected %{
  jclass excpcls = jenv->FindClass("director_exception_feature/MyLanguageUnexpected"); 
  if (excpcls) {
    jenv->ThrowNew(excpcls, $1.what());
  }
  return $null;
%}

// Use generic exception translation approach like python, ruby

%feature("director:except") MyNS::Foo::genericpong %{
  jthrowable $error = jenv->ExceptionOccurred();
  if ($error) {
    jenv->ExceptionClear();
    throw Swig::DirectorException(jenv,$error);
  }
%}

// %exception with throws attribute.  Need throws attribute for checked exceptions
%feature ("except",throws="Exception")  MyNS::Foo::genericpong %{
%}

%feature ("except",throws="Exception")  MyNS::Bar::genericpong %{
  try { 
    $action;    // TODO is $action in wrapper code consistent with $action in IM code???
  } catch (Swig::DirectorException & direxcp) { 
    direxcp.raiseJavaException(jenv);
    return $null;
  }
%}

%typemap(javabase) ::MyNS::Exception1,::MyNS::Exception2,::MyNS::Unexpected "java.lang.Exception";

#endif // SWIGJAVA

// ------------------------------------------------------------------------
// CSHARP TYPEMAPS AND FEATURES
// ------------------------------------------------------------------------
#ifdef SWIGCSHARP

// Macro works for any exception that is constructed from a string message
SWIG_DIRECTOR_DEFINE_EXCEPTION_HELPER(SwigDirector_signal_$descriptor(MyNS::Exception1)_$module, MyNS::Exception1)
SWIG_DIRECTOR_DEFINE_EXCEPTION_HELPER(SwigDirector_signal_$descriptor(MyNS::Exception2)_$module, MyNS::Exception2)
SWIG_DIRECTOR_DEFINE_EXCEPTION_HELPER(SwigDirector_signal_$descriptor(MyNS::Unexpected)_$module, MyNS::Unexpected)

// Note: director exception handling in C# is applied in C# proxy code, not C++
//  wrapper code.

// Add an explicit handler for Foo::ping, mapping one C# exception back to an 'int' 
%feature("director:except") MyNS::Foo::ping %{
  try {
    $action;    // TODO is $action in wrapper code consistent with $action in IM code???
  }
  catch (MyLanguageException1) {
    global::System.Console.WriteLine(  "Foo::ping director:except translation of MyLanguageException1 into int exception");
    $imclassname.SwigDirector_signal_AnIntAsAnException_$module(1);
    return $null;
  } 
  catch (MyLanguageException2 mle2) {
    global::System.Console.WriteLine(  "Foo::ping director:except translation of MyLanguageException2 into MyNS::Exception2");
    $imclassname.SwigDirector_signal_$descriptor(MyNS::Exception2)_$module(mle2.Message);
    return $null;
  } 
  // Important to handle all, have fallback
  catch (global::System.Exception e) {
    global::System.Console.WriteLine(  "Foo::ping director:except fallback translation of " + e.GetType().FullName + " into Swig::DirectorException with message '" + e.Message + "'");
    // Standard DirectorException signal function is defined by automatically
    $imclassname.SwigDirector_signal_$descriptor(Swig::DirectorException)_$module(e.GetType().FullName, e.Message);
    return $null;
  }
  // TODO maybe have a catch { fallback for async exceptions } 
%}

// Use default handler on Foo::pong, with directorthrows typemaps

// directorthrows typemaps for C#->c++ conversions
// Code fragments are C#
%typemap(directorthrows) MyNS::Exception1,MyNS::Exception2,MyNS::Unexpected  %{
  catch ($csclassname e) {
    global::System.Console.WriteLine( "directorthrows typemap translation of $1_type into $namespace.$csclassname" );    
    $imclassname.SwigDirector_signal_$1_descriptor_$module(e.Message);
    return $null;
  }
%}

// Override the director:except feature so exception specification is not violated
// (Cannot use built-in default of throw DirectorException)
%feature("director:except") MyNS::Foo::pong %{
  try {
    $action;
  }
  $directorthrowshandlers
  // Use Unexpected as default so exception specification is not violated
  catch (global::System.Exception e) {
    $imclassname.SwigDirector_signal_$descriptor(MyNS::Unexpected)_$module(e.Message);
    return $null;
  }
%}

// throws typemaps for c++->C# exception conversions
// TODO Don't these need the namespace : ? the full package path?
%typemap(throws,canthrow=1) MyNS::Exception1 %{
  //  How about using $csclassfullname in here, instead of namespace($namespace) or csclassname($csclassname)
  SWIG_CSharpSetPendingExceptionDynamic("director_exception_featureNamespace.MyLanguageException1", $1.what());
  return $null;
%}

%typemap(throws,canthrow=1) int %{
    std::cerr <<   "Typemap translation of int into director_exception_featureNamespace.MyLanguageException1"  << std::endl;
  //  How about using $csclassfullname in here, instead of namespace($namespace) or csclassname($csclassname)
  SWIG_CSharpSetPendingExceptionDynamic("director_exception_featureNamespace.MyLanguageException1", "Threw some integer");
  return $null;
%}

%typemap(throws,canthrow=1) MyNS::Exception2 %{
    std::cerr <<   "Typemap translation of MyNS::Exception2 into director_exception_featureNamespace.MyLanguageException2"  << std::endl;
  //  How about using $csclassfullname in here, instead of namespace($namespace) or csclassname($csclassname)
  SWIG_CSharpSetPendingExceptionDynamic("director_exception_featureNamespace.MyLanguageException2", $1.what());
  return $null;
%}

%typemap(throws,canthrow=1) MyNS::Unexpected %{
  std::cerr << "Typemap translation of MyNS::Unexpected into director_exception_featureNamespace.MyLanguageUnexpected" << std::endl;
  //  How about using $csclassfullname in here, instead of namespace($namespace) or csclassname($csclassname)
  SWIG_CSharpSetPendingExceptionDynamic("director_exception_featureNamespace.MyLanguageUnexpected", $1.what());
  return $null;
%}

// Use generic exception translation approach like python, ruby

%feature("director:except") MyNS::Foo::genericpong %{
  try {
    $action;
  }
  catch (global::System.Exception e) {
    global::System.Console.WriteLine(  "genericpong director:except fallback of Typemap translation of " + e.GetType() + " into DirectorException");

    $imclassname.SwigDirector_signal_$descriptor(Swig::DirectorException)_$module(e.GetType().FullName, e.Message);
    return $null;
  }
  // TODO need catch { } block for async exceptions, when /EHsc?
%}

// %exception with throws attribute.  Need throws attribute for checked exceptions
%feature ("except",throws="Exception",canthrow=1)  MyNS::Foo::genericpong %{
%}

%feature ("except",throws="Exception",canthrow=1)  MyNS::Bar::genericpong %{
  try { 
    $action;
  } catch (Swig::DirectorException & direxcp) {
    direxcp.raiseLanguageException();
    return $null;
  }
%}

%typemap(csbase) ::MyNS::Exception1,::MyNS::Exception2,::MyNS::Unexpected "System.Exception";

// Override Message property to use wrapped exception not default constructed base
%typemap(cscode) ::MyNS::Exception1,::MyNS::Exception2,::MyNS::Unexpected %{
  public override string Message {
    get {
      return what();
    }
  }
%}
%csmethodmodifiers what() "internal"

// Use '{' so macro defined in csharp.swg is interpreted 
// Throwing an int as an exception is unusual, need to define own function to do that
// Declare a helper with the implementation in the wrapper cxx
SWIG_DIRECTOR_DECLARE_EXCEPTION_HELPER(SwigDirector_signal_AnIntAsAnException_$module,int value)

%{
// Support existing test, ability to throw ints.
class Swig_IntException {
  public:
  Swig_IntException(int i): value(i) { }
  int value;
};

static void SwigDirector_throw_Swig_intTypeException(void *& exception) {
  std::cerr << "SwigDirector_throw_Swig_intTypeException " << exception << std::endl;
  if (exception) {
    // Just holding an int, to throw an 'int' exception for a test
    int value = reinterpret_cast<Swig_IntException*>(exception)->value;
    delete reinterpret_cast<Swig_IntException*>(exception);
    exception = 0;
    throw value;
  }
}

#ifdef __cplusplus
extern "C" 
#endif
SWIGEXPORT void SWIGSTDCALL SwigDirector_signal_AnIntAsAnException_$module(int value) {
  std::cerr << "SwigDirector_signal_AnIntAsAnException_$module " << value << std::endl;
  if (Swig_pendingException == 0) {
    Swig_pendingException = reinterpret_cast<void *>(new Swig_IntException(value));
    Swig_throwfn = &SwigDirector_throw_Swig_intTypeException;
  }
}

%}

#endif // SWIGCSHARP

%feature("director") Foo;

// Rename exceptions on target language side to make translation of
// exceptions clearer, and test problems with renaming
%rename(MyLanguageException1,fullname=1) MyNS::Exception1;
%rename(MyLanguageException2,fullname=1) MyNS::Exception2;
%rename(MyLanguageUnexpected,fullname=1) MyNS::Unexpected;

namespace MyNS {

  struct Exception1 {
      Exception1(const std::string& what);
      const char * what();
  };
  struct Exception2 {
      Exception2(const std::string& what);
      const char * what();
  };
  struct Unexpected {
      Unexpected(const std::string& what);
      const char * what();
  };

}
// In general it is better to use %catches instead of an exception specification on the method
//   since violating an exception specification calls terminate() preventing catch-all behavior
//   like throwing std::runtime_error.  But an exception specification must be used if the
//   actual interface being wrapped does use them.

// For classes allowing director implementations, you must list all C++ exceptions
//   that may be thrown (or use throw()) ...  more description...  TODO
// Something about how catches tells throws forward, and directorthrows in reverse

%catches(MyNS::Exception1,MyNS::Exception2,MyNS::Unexpected) MyNS::Foo::pong;
%catches(MyNS::Exception1,MyNS::Exception2,MyNS::Unexpected) MyNS::Bar::pong;

// TODO: Why is this only for CSHARP? Java Generic DirectorException handling is broken when this is used.
//#ifdef SWIGCSHARP
//%catches(std::exception) MyNS::Bar::genericpong;
//%catches(std::exception) MyNS::Foo::genericpong;
//#endif

%inline %{

namespace MyNS {

class Foo {
public:
  virtual ~Foo() {}
  // ping java implementation throws a java Exception1 or an Exception2 if excp is 1 or 2.
  // pong java implementation throws Exception1,Exception2,Unexpected,NullPointerException for 1,2,3,4
  virtual std::string ping(int excp) throw(int,MyNS::Exception2) = 0; 
  virtual std::string pong(int excp) /* throws MyNS::Exception1 MyNS::Exception2 MyNS::Unexpected) */ = 0; 
  virtual std::string genericpong(int excp) /* unspecified throws - exception is always DirectorException in C++, translated back to whatever thrown in java */ = 0; 
};

// Make a bar from a foo, so a call to Java Bar
// goes Java Bar -> C++ Bar -> C++ Foo -> Java Foo Director

class Bar {
public:
  Bar(Foo* d) { delegate=d; }
  virtual std::string ping(int excp) throw(int,MyNS::Exception2)
  {
    return delegate->ping(excp); 
  }

  virtual std::string pong(int excp) /* throws MyNS::Exception1,MyNS::Exception2,MyNS::Unexpected */
  {
    return delegate->pong(excp);
  }

  virtual std::string genericpong(int excp) 
  {
    return delegate->genericpong(excp);
  }
    
private:
  Foo * delegate;
};

}
%}
