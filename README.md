# Mark and Sweep GC
A mark and sweep GC allocator proof of concept for the Odin language
Run `odin run .` at the root

This very much experimental. Right now, the GC requires user input to mark the root allocations during each collection cycle. I found it to be an okay middle ground, while giving the user more control over the GC.

To mark an allocation as still alive use the `mark_*(gc_allocator_ptr, alloc_object)` procedure group