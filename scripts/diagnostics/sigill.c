#define _GNU_SOURCE
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <ucontext.h>
#include <unistd.h>

static void report_sigill(int signal_number, siginfo_t *signal_info, void *context) {
  ucontext_t *signal_context = context;
  uintptr_t program_counter = signal_context->uc_mcontext.pc;
  dprintf(STDERR_FILENO, "SIGILL si_code=%d pc=0x%lx opcode=0x%08x\n", signal_info->si_code,
          (unsigned long)program_counter, *(uint32_t *)program_counter);

  int maps = open("/proc/self/maps", O_RDONLY);
  if (maps >= 0) {
    char buffer[4096];
    ssize_t count;
    while ((count = read(maps, buffer, sizeof(buffer))) > 0) {
      write(STDERR_FILENO, buffer, count);
    }
    close(maps);
  }
  _exit(128 + signal_number);
}

__attribute__((constructor)) static void install_sigill_handler(void) {
  struct sigaction action = {.sa_sigaction = report_sigill, .sa_flags = SA_SIGINFO};
  sigemptyset(&action.sa_mask);
  sigaction(SIGILL, &action, NULL);
}
