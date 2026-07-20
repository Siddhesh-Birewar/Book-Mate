import 'dart:ui';

/// A [ColorFilter] matrix that inverts RGB channels while preserving alpha.
///
/// This transforms white backgrounds → dark and dark text → light,
/// creating an effective dark mode for static PDF content where
/// individual text colors cannot be modified.
const ColorFilter invertColorFilter = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255, //
  0, -1, 0, 0, 255, //
  0, 0, -1, 0, 255, //
  0, 0, 0, 1, 0, //
]);
