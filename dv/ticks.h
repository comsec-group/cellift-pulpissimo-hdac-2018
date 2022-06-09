
/* common way to execute a testbench, sorry for the lame C-style macro */

/* used by multiple designs */

#ifdef LEADTICKS_DESIGN /* design overrides leadticks */
#define LEADTICKS LEADTICKS_DESIGN
#else
#define LEADTICKS 5
#endif

#ifdef TRAILTICKS_DESIGN /* design overrides TRAILTICKS */
#define TRAILTICKS TRAILTICKS_DESIGN
#else
#define TRAILTICKS 5
#endif


#define ARIANE_FLUSH_TICKS 256 

#include <iostream>
#include <cassert>
#include <sstream>

static int get_sim_length_cycles(int lead_time_cycles)
{
  const char* simlen_env = std::getenv("SIMLEN");
  if(simlen_env == NULL) { std::cerr << "SIMLEN environment variable not set." << std::endl; exit(1); }
  int simlen = atoi(simlen_env);
  assert(lead_time_cycles >= 0);
  assert(simlen > 0);
  assert(simlen > lead_time_cycles);
  std::cout << "SIMLEN set to " << simlen << " ticks." << std::endl;
  return simlen - lead_time_cycles;
}

static const char *cl_get_tracefile(void)
{
  const char *trace_env = std::getenv("TRACEFILE"); // allow override for batch execution from python
  if(trace_env == NULL) { std::cerr << "TRACEFILE environment variable not set." << std::endl; exit(1); }
  return trace_env;
}

static unsigned int get_addr_to_check() {
  const char *addr_to_check_str = std::getenv("ADDR_TO_CHECK");
  bool check_mem_addr = addr_to_check_str != NULL;
  unsigned int addr_to_check = ~0;
  if (check_mem_addr) {
    std::stringstream ss;
    ss << std::hex << addr_to_check_str;
    ss >> addr_to_check;
  }
  return addr_to_check;
}

#define TB_LEAD_AND_FULL_TICKS(tb, statement) \
  int my_simlen = get_sim_length_cycles(LEADTICKS); \
  unsigned int addr_to_check = get_addr_to_check(); \
  tb->reset(); \
  tb->tick(LEADTICKS); \
  statement; \
  tb->tick(my_simlen); \
  tb->tick(TRAILTICKS);

// Also check accesses to addresses
#define TB_LEAD_AND_FULL_TICKS_AND_CHECK(tb, statement) \
  int my_simlen = get_sim_length_cycles(LEADTICKS); \
  unsigned int addr_to_check = get_addr_to_check(); \
  tb->reset(); \
  tb->tick(LEADTICKS); \
  statement; \
  tb->tick_and_check(my_simlen, false, addr_to_check != ~0U, addr_to_check); \
  tb->tick(TRAILTICKS);

static inline void inject_taint(unsigned int *ptr){
   if(ptr==NULL) return;
   std::cout << "Injecting taint." << std::endl;
   *ptr = -1; //32-bit ones
}

#define TB_LEAD_AND_FULL_TICKS_AND_INJECT_SINGLE_TAINT(tb, injection_time, taintptr) \
  int my_simlen = get_sim_length_cycles(LEADTICKS); \
  unsigned int addr_to_check = get_addr_to_check(); \
  tb->reset(); \
  tb->tick(LEADTICKS); \
  assert(injection_time <= my_simlen); \
  tb->tick(injection_time); \
  inject_taint(taintptr); \
  tb->tick(my_simlen-injection_time);\
  tb->tick(TRAILTICKS);

// Also check accesses to addresses
#define TB_LEAD_AND_FULL_TICKS_AND_INJECT_SINGLE_TAINT_AND_CHECK_ADDR(tb, injection_time, taintptr) \
  int my_simlen = get_sim_length_cycles(LEADTICKS); \
  unsigned int addr_to_check = get_addr_to_check(); \
  tb->reset(); \
  tb->tick(LEADTICKS); \
  assert(injection_time <= my_simlen); \
  tb->tick_and_check(injection_time, false, addr_to_check != ~0U, addr_to_check); \
  inject_taint(taintptr); \
  tb->tick_and_check(my_simlen-injection_time, false, addr_to_check != ~0U, addr_to_check);\
  tb->tick(TRAILTICKS);
