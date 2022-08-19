package main

import "core:fmt"
import "core:mem"

main :: proc() {
	buf := make([]byte, mem.Megabyte * 20)
	backing_arena: mem.Arena
	mem.init_arena(&backing_arena, buf)
	backing_allocator := mem.arena_allocator(&backing_arena)

	state := new(Example_State, backing_allocator)

	gc: Gc_Allocator
	init_gc_allocator(
		&gc,
		Gc_Allocator_Options{
			gather_roots_proc = gather_roots,
			data = state,
			temp_allocator = context.temp_allocator,
			internals_allocator = backing_allocator,
			initial_size = mem.Megabyte * 5,
			first_collection = mem.Byte * 200,
			growth_factor = 2,
		},
	)

	context.allocator = gc_allocator(&gc)
	defer {
		free_all(context.allocator)
		fmt.println("Leaked:", gc_used_memory_size(&gc))
		free_all(backing_allocator)
	}

	for i in 0 ..< 10 {
		state.roots[i] = new(Example_Alloc_Object)
		state.roots[i].memory = make([]byte, 15)
	}

	state.roots[3] = nil
	state.roots[5] = nil

	for i in 0 ..< 20 {
		make([]byte, 100)
	}

	fmt.println(state.roots)
}

Example_State :: struct {
	roots: [10]^Example_Alloc_Object,
}

Example_Alloc_Object :: struct {
	memory: []byte,
}


gather_roots :: proc(
	data: rawptr,
	allocator := context.temp_allocator,
) -> []Mark_Node_Interface {
	state := cast(^Example_State)data
	roots := make([dynamic]Mark_Node_Interface, allocator)
	for root in state.roots {
		if root != nil {
			it := Mark_Node_Interface {
				data = root,
				mark_proc = proc(gc: ^Gc_Allocator, data: rawptr) {
					object := cast(^Example_Alloc_Object)data
					mark_raw_allocation(gc, data)
					mark_slice(gc, object.memory)
				},
			}
			append(&roots, it)
		}
	}
	return roots[:]
}
