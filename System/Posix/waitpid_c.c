#include <sys/types.h>
#include <sys/wait.h>

pid_t SystemPosixWaitpid_waitpid(pid_t pid, int *result, int opts)
{
  int options = 0;
  if (opts & 1) options |= WNOHANG;
  if (opts & 2) options |= WUNTRACED;
  if (opts & 4) options |= WCONTINUED;

  int status = 0;
  int retval = waitpid(pid, result ? &status : 0, options);
  if (result)
  {
    if (WIFEXITED(status)) { *result = WEXITSTATUS(status); }
    else if (WIFSIGNALED(status)) { *result = 0x10000 + WTERMSIG(status); }
    else if (WIFSTOPPED(status)) { *result = 0x20000 + WSTOPSIG(status); }
    else if (WIFCONTINUED(status)) { *result = 0x30000; }
    else { *result = 0; }
  }
  return retval;
}
