#include "doh.h"
#include <string.h>
#include <stdarg.h>
#include <stdio.h>

/* globals.  keep it simple */
int keepgoing;
int verbose;
int errors;

struct ReplaceConditionalData {
  const char * text;
  const int rc;
  const char * expectedtrue;
  const char * expectedfalse;
};

int testcall(int comparison, const char * fmt, ...) {
  if (!comparison) {
    ++errors;
    if (verbose) {
      va_list ap;
      va_start(ap, fmt);
      vfprintf(stdout, fmt, ap);
      va_end(ap);
    }
  }
  return comparison;
}

struct ReplaceConditionalData data[] =
  {
    {"no substititution", 0, "no substititution", "no substititution"},
    {"$ifcond(condistrue)", 0, "condistrue", ""},
    {"$ifcond(condistrue)", 0, "condistrue", ""},
    {"$ifcond(firstislonger,second)", 0, "firstislonger", "second"},
    {"$ifcond(first,secondislonger)", 0, "first", "secondislonger"},
    {"$ifcond(first)", 0, "first", ""},
    {"$ifcond(,second)", 0, "", "second"},
    {"foo$ifcond(first,second)", 0, "foofirst", "foosecond"},
    /* escaped commas; ONLY NEEDED AND RECOGNIZED WHEN NOT IN ( ) expression */
    {"static $ifcond(int,float) $ifcond(i\\,j\\,k,r\\,s\\,t); // $ifcond(\\0\\1 i\\,j\\,k,\\1\\2 r\\,s\\,t)", 0,
     "static int i,j,k; // \\0\\1 i,j,k",
     "static float r,s,t; // \\1\\2 r,s,t"},
    /* backslash chars unmodifed when not escaping commas */
    {"foo = \"\\\\ \\01 \\\" $ifcond(\\\\\\\",\\') + 7", 0,
     "foo = \"\\\\ \\01 \\\" \\\\\\\" + 7",
     "foo = \"\\\\ \\01 \\\" \\' + 7" },
    /* multiple substitutions */
    {"foo$ifcond(high,low) \n foo$ifcond(front,back) \n foo$ifcond(left,right)", 0,
     "foohigh \n foofront \n fooleft",
     "foolow \n fooback \n fooright"},
    /* nested parenthesis with commas, no escaped needed */
    {"foo = $ifcond(myfuncall(high,high),myfuncall(low,low)) \n foo = $ifcond(myfuncall(left(2),left(3,4)),myfuncall(right(0),right(1,2)))", 0,
     "foo = myfuncall(high,high) \n foo = myfuncall(left(2),left(3,4))",
     "foo = myfuncall(low,low) \n foo = myfuncall(right(0),right(1,2))" },
    /* nested parenthesis with (unsupported) escaped commas */
    {"foo = $ifcond(myfuncall(high\\,high),myfuncall(low\\,low)) \n foo = $ifcond(myfuncall(left(2)\\,left(3\\,4)),myfuncall(right(0),right(1\\,2)))", 0,
     "foo = myfuncall(high\\,high) \n foo = myfuncall(left(2)\\,left(3\\,4))",
     "foo = myfuncall(low\\,low) \n foo = myfuncall(right(0),right(1\\,2))" },
    /* missing open parenthesis - no substitution */
    {"foo = $ifcond  myfuncall(high,high)", -1,
     "foo = $ifcond  myfuncall(high,high)", "foo = $ifcond  myfuncall(high,high)" },
    /* missing close parenthesis - no substitution */
    {"foo = $ifcond(myfuncall(high,high),myfuncall(low,low) ] \n foo = $ifcond(myfuncall(left(2),left(3,4)),myfuncall(right(0),right(1,2)))", -1,
     "foo = $ifcond(myfuncall(high,high),myfuncall(low,low) ] \n foo = $ifcond(myfuncall(left(2),left(3,4)),myfuncall(right(0),right(1,2)))",
     "foo = $ifcond(myfuncall(high,high),myfuncall(low,low) ] \n foo = $ifcond(myfuncall(left(2),left(3,4)),myfuncall(right(0),right(1,2)))" },
    { 0, 0, 0, 0 }
  };

void testReplaceConditional() {
  int rc;
  DOH *s;
  struct ReplaceConditionalData *rcd = data;

  while (rcd->text && (errors==0 || keepgoing)) {
    if (verbose) fprintf(stdout,"Test DohReplaceConditional with '%s'\n", rcd->text);
    /* true condition case */
    s = DohNewString(rcd->text);
    rc = DohReplaceConditional(s, "$ifcond", 1);
    if (testcall(rcd->rc == rc,
		 "error: unexpected RC %d for true call with data '%s'\n", rc, rcd->text)) {
	testcall(0 == DohCmp(s,rcd->expectedtrue),
		 "error: Substitution '%s' but expected '%s'\n", Char(s), rcd->expectedtrue);
      }
    DohDelete(s);
    /* false condition case */
    if (errors == 0 || keepgoing) {
      s = DohNewString(rcd->text);
      rc = DohReplaceConditional(s, "$ifcond", 0);
      if (testcall(rcd->rc == rc,
		   "error: unexpected RC %d for false call with data '%s'\n", rc, rcd->text)) {
	testcall(0 == DohCmp(s,rcd->expectedfalse),
		 "error: Substitution '%s' but expected '%s'\n", Char(s), rcd->expectedfalse);
      }
      DohDelete(s);
    }
    ++rcd;
  }
}

/**
 * Test program to run tests against different doh.h functions
 * Currently only tests for DohReplaceConditional
 */
int main(int argc, char **argv) {
  keepgoing = 0;
  verbose = 1;

  while (argc--) {
    if (0 == strcmp("-k",*argv)) keepgoing = 1;
    if (0 == strcmp("-s",*argv)) verbose = 0;
    ++argv;
  }

  testReplaceConditional();

  return errors;
}
