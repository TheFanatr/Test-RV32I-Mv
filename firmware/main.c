void main();
void puts(char *s);


void main() { 
  puts("Hello World\n"); 
  for (;;);
}

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
