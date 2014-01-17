/* -----------------------------------------------------------------------------
 * director.swg
 *
 * This file contains support for director classes so that C# proxy 
 * methods can be called from C++.
 * ----------------------------------------------------------------------------- */

#ifdef __cplusplus

#if defined(DEBUG_DIRECTOR_OWNED)
#include <iostream>
#endif
#include <string>
#include <exception>

// TODO Finalize approach for setting a pending exception.
// Doing anything more complex with locks in a cross platform
//  manner will depend on the requirements for swig platform support
//  and will be complicated.
//  I can only guess at whay might be acceptable.  This at least needs
//  a test added to test multiple threads throwing exceptions from directors.
// There is an alternative way to handle this without locks or thread_local.
#if __cplusplus >= 201303L
#define THREAD_LOCAL thread_local
#else 
# if defined(_MSC_VER)
# define THREAD_LOCAL __declspec(thread)
# else 
// This supports at least g++, clang++, solaris, intel compilers
// Note that it does not work for g++ on OSX, but there is some other 
// issue on OSX that prevents tests under mono from working except with 
// clang++ compiled with CXXFLAGS=-stdlib=libc++
// http://en.wikipedia.org/wiki/Thread-local_storage
# define THREAD_LOCAL __thread
#endif
#endif

typedef void (*Swig_exceptionthrowfn_t)(void *&);
static THREAD_LOCAL void * Swig_pendingException = 0;
static THREAD_LOCAL Swig_exceptionthrowfn_t  Swig_throwfn = 0;

namespace Swig {
  /* Director base class - not currently used in C# directors */
  class Director {
  };

  /* Base class for director exceptions */
  class DirectorException : public std::exception {
  public:
    DirectorException(const char* exceptiontypename, const char* msg) : exceptiontypename(exceptiontypename), message(msg) {
    }
    DirectorException(std::string const& exceptiontypename, std::string const& msg) : exceptiontypename(exceptiontypename), message(msg) {
    }
    // Translate a C++ DirectorException back to the target language exception that was the cause
    void raiseLanguageException() const {
      SWIG_csharp_exception_dynamic(exceptiontypename.c_str(),message.c_str());
    }
    const char * what() const throw() {
      return message.c_str();
    }
    virtual ~DirectorException() throw() {
    }

  protected:
    std::string exceptiontypename;
    std::string message;

  };

  /* Pure virtual method exception */
  class DirectorPureVirtualException : public Swig::DirectorException {
  public:
    DirectorPureVirtualException(const char* msg) : DirectorException("System.ApplicationException",std::string("Attempt to invoke pure virtual method ") + msg) {
    }
  };
}

inline void SwigDirector_throwIfSignaledException() {
  if (Swig_pendingException)
    (*Swig_throwfn)(Swig_pendingException);
}

void SwigDirector_throw_Swig_DirectorException(void *& exception) {
  // TODO std::cerr << "SwigDirector_throw_Swig_DirectorException " << exception << std::endl;	
  // Delete heap allocated pending exception, clear it, and throw a copy
  if (exception) {
    Swig::DirectorException copy(*reinterpret_cast<Swig::DirectorException*>(exception));
    delete reinterpret_cast<Swig::DirectorException*>(exception);
    exception = 0;  // Clear pending
    throw copy;
  }
}

// Called in intermediate class, corresponds to declaration in csharp.swg
extern "C" 
void SwigDirector_signal_SWIGTYPE_Swig__DirectorException(const char * exceptiontypename, const char * msg) {
  // TODO std::cerr << "SwigDirector_signal_Swig__DirectorException " << exceptiontypename << " " << msg << std::endl;
  // TODO see comment in csharp.swg, same issue
  if (Swig_pendingException == 0) { 
    Swig_pendingException = reinterpret_cast<void *>(new Swig::DirectorException(exceptiontypename,msg));
    Swig_throwfn = &SwigDirector_throw_Swig_DirectorException;
  }
}

#endif /* __cplusplus */
