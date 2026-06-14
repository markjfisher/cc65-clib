# CC65 BBC Upstream Cleanup Plan

## Goal

Prepare the BBC support in the `cc65` fork for a realistic upstream submission by reducing scope, removing obvious technical debt, documenting the remaining BBC-specific APIs, and separating the core `bbc` target from the more experimental `bbc-clib` ROM-backed target.

This plan is based on the current state of:

- `libsrc/bbc`
- `libsrc/bbc-clib`
- `libsrc/Makefile`
- the `cc65-clib` test suite and ROM build documentation

## Current Assessment

### 1. The codebase still exposes too much surface area

The maintainer feedback about "way too much" still substantially applies.

Current signs:

- `libsrc/bbc/oslib` is a large OSLib-style compatibility layer, not just a minimal BBC MOS support layer.
- `libsrc/bbc-clib/oslib` duplicates almost the entire `libsrc/bbc/oslib` tree.
- `libsrc/Makefile` still contains BBC-specific install and `bbc-clib` ROM-selection logic.
- `bbc-clib` adds generated manifests and object filtering via `inc_objs.mk`, which is useful for the ROM target but enlarges the upstream surface.

### 2. `xos_*` and `os_*` are a deliberate API split, but it is inherited from OSLib terminology

The current pattern is consistent in headers:

- `xos_*` functions return `os_error *`
- `os_*` functions return a plain result such as `void`, `int`, or `fileswitch_object_type`

Examples:

- `libsrc/bbc/oslib/osfile.h`
- `libsrc/bbc/oslib/osgbpb.h`
- `libsrc/bbc/oslib/fileswitch.h`

What they appear to mean here:

- `os_*` is the direct wrapper around a BBC MOS call.
- `xos_*` is the error-reporting wrapper that catches BRK/error behaviour and converts it into an `os_error *` return.

Evidence:

- `libsrc/bbc/oslib/os_generate_error.s` exports both `_os_generate_error` and `_xos_generate_error`, and both currently raise the error.
- `libsrc/bbc/oslib/xosfile_delete.s` uses `_set_brk_ret` and `_clear_brk_ret` to catch an error path and return an error pointer.
- `libsrc/bbc/oslib/osfile_delete.s` is the simpler non-`x` form and returns the object type directly.

The user's note about symbol naming is important here: in cc65, assembler label `_foo` is the C function `foo()`, and C `bar()` becomes `_bar` in assembler. The implementation audit therefore needs to cross-check headers against exported assembler labels, not just against C names.

Assessment:

- This split is not pointless; it is part of the public compatibility model of this OSLib-derived layer.
- However, it is also not native BBC terminology, and it should not be upstreamed wholesale unless there is a strong compatibility reason.
- For upstream, the main question is not "what do they do?" but "which of these wrappers are actually needed by the BBC runtime or by real programs?"

### 3. `FileSwitch` is mostly a transplanted compatibility namespace, not a BBC-native subsystem

`libsrc/bbc/oslib/fileswitch.h` defines:

- filesystem number constants
- object type constants
- file attribute constants
- `os_bget` and `os_bput` declarations

In practice, the main value appears to be:

- shared metadata types such as `fileswitch_attr`
- shared object-type values used by `osfile.h` and `osgbpb.h`

Assessment:

- On BBC MOS, the real underlying interfaces are `OSFILE`, `OSGBPB`, `OSBGET`, `OSBPUT`, and `OSFIND`.
- `FileSwitch` here is best understood as an OSLib/RISC OS compatibility veneer that was adapted onto BBC MOS concepts.
- Upstream should not treat `FileSwitch` as a BBC-first abstraction unless there is a concrete need to preserve source compatibility for existing code using these headers.

### 4. There are still clear quality issues that match the old review

Current examples:

- stale copied headers and RISC OS wording in multiple OSLib headers
- TODO comments still present, for example in `libsrc/bbc/oslib/osfile.h`
- informal uncertainty comments still present, for example in `libsrc/bbc/cputc.s`
- the legacy `libsrc/bbc/Makefile` is still present and begins with `$(error This should not be used)`
- likely stale or broken declarations:
  - `fileswitch.h` uses `fileswitch_fs_info` in the `fileswitch_FS_NUMBER` macro, but that type does not appear to exist
  - `osgbpb.h` includes `oslib/osgbpb32.h`, but that file is not present
- `open.c` still says the implementation requires fixing and not all flags are supported

Assessment:

- The code is closer to something usable than the old review suggested, but it is not yet in upstream shape.
- The remaining issues are now concrete enough to tackle systematically.

### 5. The `bbc` and `bbc-clib` targets should not be upstreamed as one undifferentiated feature

Current split:

- `bbc` is the normal target and contains the core runtime and MOS wrappers.
- `bbc-clib` is a ROM-backed variant driven by the sibling `cc65-clib` project.

Assessment:

- The cleanest upstream path is to get `bbc` into a minimal and well-documented state first.
- `bbc-clib` should be treated as a second-phase or downstream extension unless upstream explicitly wants the ROM workflow too.

## Proposed Strategy

Proceed in phases, with each phase producing something reviewable and self-contained.

## Phase 1: Define the upstreamable core

### Objective

Reduce the scope to a minimum viable BBC target that an upstream maintainer can evaluate without needing to absorb the full OSLib and ROM story.

### Tasks

1. Inventory which files in `libsrc/bbc` are required for:
   - startup/runtime
   - console I/O
   - file I/O
   - directory handling
   - error handling
2. Inventory which `oslib` entry points are actually referenced by:
   - `libsrc/bbc`
   - `libsrc/common`
   - tests in `cc65-clib`
3. Classify each area as one of:
   - required for basic target functionality
   - useful but optional
   - compatibility-only
   - dead or unimplemented surface
4. Produce a short "upstream core" list that intentionally excludes everything not needed for a first submission.

### Expected outcome

A documented target scope such as:

- core `bbc` runtime
- core file/channel support
- core console support
- only the minimal `oslib` subset actually required
- no `bbc-clib` ROM plumbing in the first upstream pass

## Phase 2: Rationalize the `xos_*` and `os_*` API surface

### Objective

Decide what must be kept, what can be deferred, and what should be removed from the first upstream submission.

### Tasks

1. Build a table of all public `xos_*` and `os_*` declarations under `libsrc/bbc/oslib`.
2. For each pair, record:
   - declared in headers
   - exported by assembler labels such as `_xosfile_delete` or `_osfile_delete`
   - used by the runtime or library or not
   - tested in `cc65-clib` or not
   - BBC-native concept or compatibility veneer
3. Keep only the pairs that meet at least one of these criteria:
   - needed by the core BBC target
   - already tested and clearly working
   - required to preserve an intentional public API
4. For the rest, choose one of:
   - defer from upstream
   - move behind a documented compatibility subset
   - delete if dead
5. Document the semantics of the retained split:
   - `os_*`: direct wrapper
   - `xos_*`: wrapper returning `os_error *` on trapped error

### Expected outcome

A smaller and defensible API story, instead of "all of OSLib for BBC".

## Phase 3: Reframe or reduce `FileSwitch`

### Objective

Turn `FileSwitch` from a confusing imported concept into either a tiny shared metadata header or an explicitly optional compatibility layer.

### Tasks

1. Identify which parts of `fileswitch.h` are actually used today.
2. Split the contents conceptually into:
   - BBC-relevant shared metadata types and constants
   - OSLib/RISC OS compatibility baggage
3. Decide between two acceptable directions:
   - minimal path: keep only the types/constants needed by `osfile.h` and `osgbpb.h`
   - compatibility path: retain `fileswitch.h`, but document clearly that it is an OSLib-derived compatibility header layered over BBC MOS calls
4. Fix obvious issues in the retained surface:
   - broken type reference around `fileswitch_FS_NUMBER`
   - wording that implies unavailable or irrelevant interfaces

### Expected outcome

A clear explanation of why `FileSwitch` exists and a much smaller burden for upstream review.

## Phase 4: Remove duplication between `bbc` and `bbc-clib`

### Objective

Eliminate or sharply reduce the duplicated `oslib` trees.

### Tasks

1. Compare `libsrc/bbc/oslib` and `libsrc/bbc-clib/oslib` file-by-file.
2. Separate differences into:
   - real ROM-target differences
   - accidental divergence
   - identical files that should be shared
3. Choose a sharing model that keeps upstream maintenance simple.
   Possible acceptable end states:
   - `bbc-clib` reuses `bbc/oslib` entirely and only overrides truly ROM-specific files
   - `bbc-clib` keeps only a very small overlay directory
4. Remove copied files that exist only because of historical duplication.

### Expected outcome

A single source of truth for the OSLib-derived BBC wrappers.

## Phase 5: Clean build-system additions

### Objective

Make the `cc65` tree understandable without needing to know the full ROM toolchain.

### Tasks

1. Review all BBC-specific additions in `libsrc/Makefile`.
2. Separate them into:
   - necessary support for the normal `bbc` target
   - optional support only needed by `bbc-clib`
3. Minimize special cases for the first upstream submission.
4. Decide whether `bbc-clib` build logic should be:
   - omitted from the first upstream submission
   - or retained behind a narrow, well-documented hook
5. Remove or quarantine legacy files such as the obsolete `libsrc/bbc/Makefile` if they no longer serve a real purpose.

### Expected outcome

A small, reviewable diff in core build logic.

## Phase 6: Fix obvious correctness and polish issues

### Objective

Address the concrete problems that would immediately distract or block an upstream review.

### Tasks

1. Fix broken declarations and includes, including:
   - `fileswitch_fs_info` typo or stale reference
   - missing `osgbpb32.h` include decision
2. Resolve or remove stale TODO and uncertainty comments.
3. Normalize file headers so they accurately reflect BBC/cc65 provenance.
4. Standardize code style where the code is actively being kept.
5. Review inline assembly wrappers for cases where the maintainer's "assembler where it shouldn't be" comment still applies.
   Focus on wrappers that could be simpler or clearer in C without harming correctness.
6. Revisit incomplete library behaviour such as `open()` flag support and error mapping.

### Expected outcome

The retained code looks intentional rather than half-imported.

## Phase 7: Document the retained BBC interface

### Objective

Supply the documentation that was previously missing.

### Tasks

1. Write a short maintainer-facing design note covering:
   - what the `bbc` target supports
   - how BBC MOS file APIs map into cc65 libc operations
   - what subset of OSLib-style wrappers is intentionally retained
2. If any `xos_*` APIs remain public, document when to use them versus `os_*`.
3. Document the status of `bbc-clib` separately so it does not obscure the core target.
4. Add references to the existing `cc65-clib` tests as evidence of coverage.

### Expected outcome

Upstream reviewers can understand the target without reverse-engineering the code.

## Phase 8: Validate with tests and create review-sized patch series

### Objective

Submit in a sequence that upstream can realistically review.

### Tasks

1. Map existing `cc65-clib` tests to the retained `bbc` functionality.
2. Add focused tests where coverage is thin for the kept API surface.
3. Break the work into small patch groups, for example:
   - patch 1: build-system cleanup and dead-file removal
   - patch 2: `bbc` runtime/file I/O core
   - patch 3: minimal retained `oslib` subset
   - patch 4: documentation
   - patch 5: optional `bbc-clib` follow-up, if still desired
4. Ensure each patch is independently explainable.

### Expected outcome

A path to upstream submission that does not require one large all-or-nothing merge.

## Recommended Order of Execution

1. Define the minimal upstreamable `bbc` scope.
2. Audit actual usage of `oslib` and `xos_*`/`os_*` APIs.
3. Decide whether `FileSwitch` is reduced or explicitly documented as compatibility-only.
4. De-duplicate `bbc` and `bbc-clib` OSLib sources.
5. Simplify build integration, preferably keeping `bbc-clib` out of the first upstream pass.
6. Fix the concrete correctness and style issues.
7. Add maintainer-facing documentation.
8. Validate with the `cc65-clib` tests and split into upstream-sized changes.

## Specific Answers To The Questions Raised

### What do the `xos_*` functions do, and do we need to keep them?

Assessment:

- They are the error-returning side of an OSLib-style dual API.
- They convert trapped BBC error behaviour into a returned `os_error *` instead of only exposing the non-`x` direct form.
- They should only be kept where they are declared, exported, used, tested, and genuinely useful.
- They do not justify upstreaming the full OSLib surface by themselves.

Recommended action:

- Audit and keep only the `xos_*` wrappers that support the retained core or preserve a deliberate compatibility contract.
- Defer the rest from the first upstream submission.

### Why do we have both `xosgbpb_write_at` and `osgbpb_write_at`, and similar pairs?

Assessment:

- The pair mirrors the OSLib convention of error-returning versus direct wrapper forms.
- This is conceptually valid, but upstream will likely only accept it if the retained subset is small, consistent, and documented.

Recommended action:

- Preserve the pairing only for wrappers that remain in the trimmed API surface.
- Avoid carrying large numbers of barely used declarations just for symmetry.

### What is `FileSwitch`?

Assessment:

- In this tree it is not a BBC-native subsystem implementation.
- It is an inherited OSLib compatibility namespace for file metadata and stream-call terminology, layered over BBC MOS file primitives.
- Its main practical value is shared typedefs and constants used by `osfile.h` and `osgbpb.h`.

Recommended action:

- Either reduce it to the minimal types/constants needed by the retained wrappers, or explicitly document it as an optional compatibility header.

## Decision Points

These decisions should be made before implementation starts in earnest:

1. Is the first upstream goal `bbc` only, with `bbc-clib` intentionally deferred?
2. Is preserving source compatibility for OSLib-style BBC code an explicit goal, or only a convenience if it comes cheaply?
3. Should `FileSwitch` survive as a named public header, or only as internal/shared type definitions?

## Recommended Default Position

Unless new evidence appears during implementation:

- upstream `bbc` first
- treat `bbc-clib` as follow-up work
- keep only a minimal, used, tested `oslib` subset
- treat `FileSwitch` as compatibility-only, not as a primary BBC abstraction
- remove duplicate sources and unnecessary build special-casing before proposing upstream review
