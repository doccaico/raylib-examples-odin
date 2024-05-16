package circular_buffer

import "core:fmt"
import "core:testing"

// c https://github.com/epsilon-phase/raylib-experiments/blob/canon/src/utility/circular_buffer.c
// odin https://github.com/JustinRyanH/Breakit/blob/main/src/game/ring_buffer.odin
// cpp https://www.geeksforgeeks.org/implement-circular-buffer-using-std-vector-in-cpp/

// memo(gist) https://gist.github.com/doccaico/96246588c5de08e3b24bf526c87dac97

Circular_Buffer :: struct($N: u64, $T: typeid) {
	push_index: u64,
	len: u64,
	data: [N]T,
}

append :: proc(cb: ^Circular_Buffer($N, $T), v: T) {
	new_index := (cb.push_index + 1) % N
	cb.data[cb.push_index] = v
	cb.push_index = new_index

	if cb.len < N do cb.len += 1

	when ODIN_DEBUG {
		for v in cb.data do fmt.print(v, " "); fmt.println()
	}
}

pop_value :: proc(cb: ^Circular_Buffer($N, $T)) {
	new_index := (cb.push_index - 1) % N
	cb.push_index = new_index
}

last_value :: proc(cb: ^Circular_Buffer($N, $T)) -> T {
	return cb.data[(cb.push_index - 1) % N]
}

// Tests

@(test)
test_basic :: proc(t: ^testing.T) {
	using testing

	buffer := Circular_Buffer(3, u8){}

	append(&buffer, 10)
	expectf(t, last_value(&buffer) == 10, "want %v, but got %v", 10, last_value(&buffer))
	append(&buffer, 20)
	expectf(t, last_value(&buffer) == 20, "want %v, but got %v", 20, last_value(&buffer))

	append(&buffer, 30)
	expectf(t, last_value(&buffer) == 10, "want %v, but got %v", 10, last_value(&buffer))

	append(&buffer, 40)
	expectf(t, last_value(&buffer) == 40, "want %v, but got %v", 40, last_value(&buffer))
	append(&buffer, 50)
	expectf(t, last_value(&buffer) == 50, "want %v, but got %v", 50, last_value(&buffer))

	append(&buffer, 60)
	expectf(t, last_value(&buffer) == 40, "want %v, but got %v", 40, last_value(&buffer))
}
