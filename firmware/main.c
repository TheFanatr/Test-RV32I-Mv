void kmain();
void puts(char *s);

__attribute__((section(".entry"))) void _start() { kmain(); }

void kmain() { puts("Hello World\n"); }

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warray-bounds"
void putc(int c) {
  volatile char *p = (void *)4096;
  *p = (char)c;
}
#pragma GCC diagnostic pop

void puts(char *s) {
  while (*s)
    putc(*(s++));
}
