int main();
void puts(char *s);


int main() {
  puts("Hello sailor.\n");
  puts("What's for breakfast?\n");
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warray-bounds"
void putc(int c) {
  volatile char *p = (char *)(void *)4096;
  *p = (char)c;
}
#pragma GCC diagnostic pop

void puts(char *s) {
  while (*s)
    putc(*(s++));
}
