void load_fn(const int idx) {
  if (idx == 99) {
  	// load data from not allowed memory region
  }
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
        call_indirect(load_fn, i);
        if (i == 99) {
            call_indirect(save_fn, i);
        }
    }
}
