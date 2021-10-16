import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart' hide malloc;
import 'package:ffi/src/allocation.dart';
import 'package:flutter/foundation.dart';

import 'platform.dart';

/// based on code from ffi-1.1.2\lib\src\allocation.dart
/// on Windows, alloc from dart and then delete from cpp has problems.

final DynamicLibrary stdlib = Platform.isWindows
    ? DynamicLibrary.open(kReleaseMode ? 'ucrtbase.dll' : 'ucrtbased.dll')
    : DynamicLibrary.process();
typedef PosixMallocNative = Pointer Function(IntPtr);
typedef PosixMalloc = Pointer Function(int);
final PosixMalloc posixMalloc =
    stdlib.lookupFunction<PosixMallocNative, PosixMalloc>('malloc');

typedef PosixCallocNative = Pointer Function(IntPtr num, IntPtr size);
typedef PosixCalloc = Pointer Function(int num, int size);
final PosixCalloc posixCalloc =
    stdlib.lookupFunction<PosixCallocNative, PosixCalloc>('calloc');

typedef PosixFreeNative = Void Function(Pointer);
typedef PosixFree = void Function(Pointer);
final PosixFree posixFree =
    stdlib.lookupFunction<PosixFreeNative, PosixFree>('free');

/// Manages memory on the native heap.
///
/// Does not initialize newly allocated memory to zero. Use [_CallocAllocator]
/// for zero-initialized memory on allocation.
///
/// For POSIX-based systems, this uses `malloc` and `free`. On Windows, it uses
/// `HeapAlloc` and `HeapFree` against the default public heap.
class _MallocAllocator implements Allocator {
  const _MallocAllocator();

  /// Allocates [byteCount] bytes of of unitialized memory on the native heap.
  ///
  /// Throws an [ArgumentError] if the number of bytes or alignment cannot be
  /// satisfied.
  // TODO: Stop ignoring alignment if it's large, for example for SSE data.
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    Pointer<T> result = posixMalloc(byteCount).cast();
    if (result.address == 0) {
      throw ArgumentError('Could not allocate $byteCount bytes.');
    }
    return result;
  }

  /// Releases memory allocated on the native heap.
  ///
  /// It may only be used against pointers allocated in a manner equivalent to
  /// [allocate].
  ///
  /// Throws an [ArgumentError] if the memory pointed to by [pointer] cannot be
  /// freed.
  ///
  // TODO(dartbug.com/36855): Once we have a ffi.Bool type we can use it instead
  // of testing the return integer to be non-zero.
  @override
  void free(Pointer pointer) {
    posixFree(pointer);
  }
}

/// Manages memory on the native heap.
///
/// Does not initialize newly allocated memory to zero. Use [calloc] for
/// zero-initialized memory allocation.
///
/// ** Please Hide `malloc` when import 'package:ffi/ffi.dart' **:
///   `import 'package:ffi/ffi.dart';`
const Allocator malloc = _MallocAllocator();
