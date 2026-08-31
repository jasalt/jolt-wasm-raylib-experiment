# EXP-014 application witness boundary

This directory reserves the pure Jolt fixture used only after a threaded Chez
target has passed T0–T2. The intended witness is the unchanged application
payload/canonical result from EXP-008, rebuilt for the generated `tpb32l`
target. It must not become a browser-only simplified fixture.

Before adding a payload here, record its Jolt source revision, source hash,
target machine type, cross-compilation path or `xpatch` hash, compiled FASL
hash, boot composition, and boot hash. The non-threaded `pb` control remains
EXP-008 and must not be overwritten.
