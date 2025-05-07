void load_fn(const int idx) {
  int result = idx + (idx == 99) * 136000;
  // do save operation
}

void save_fn(const int idx) {
  // do nothing
}

void call_indirect(void (*func)(int), const int idx) {
    func(idx);
}

int main() {
    for (int i = 0; i < 100; i++) {
      call_indirect(i != 99 ? load_fn : save_fn, i);
    }
}
