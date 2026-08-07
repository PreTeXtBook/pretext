/**
 * btm-matrix-library.js
 * Numerical matrix library for use with dynamic import().
 *
 * Usage:
 *   const { parseMatrix, getRREF, isRowEchelon, testMatrixEqual, isMatrix } =
 *     await import('./btm-matrix-library.js');
 */

// ---------------------------------------------------------------------------
// Matrix class
// ---------------------------------------------------------------------------

class Matrix {
  #data; // 2D array, row-major: #data[row][col]
  #rows;
  #cols;

  /**
   * @param {number[][]} data - Validated 2D array of finite numbers.
   *   All rows must have the same length. The constructor stores a deep copy.
   */
  constructor(data) {
    if (!Array.isArray(data) || data.length === 0) {
      throw new Error("Matrix: data must be a non-empty 2D array");
    }
    const cols = data[0].length;
    if (cols === 0) throw new Error("Matrix: rows must be non-empty");
    for (let i = 1; i < data.length; i++) {
      if (!Array.isArray(data[i]) || data[i].length !== cols) {
        throw new Error(`Matrix: row ${i} has inconsistent length`);
      }
    }
    this.#rows = data.length;
    this.#cols = cols;
    this.#data = data.map(row => [...row]);
  }

  // --- Properties -----------------------------------------------------------

  /** Number of rows. */
  get rows() { return this.#rows; }

  /** Number of columns. */
  get cols() { return this.#cols; }

  /** [rows, cols] tuple. */
  get dim() { return [this.#rows, this.#cols]; }

  /** Deep copy of the underlying 2D data array. */
  get data() { return this.#data.map(row => [...row]); }

  // --- Arithmetic methods ---------------------------------------------------

  /**
   * Add another matrix of the same dimensions. Returns a new Matrix.
   * @param {Matrix} B
   */
  add(B) {
    if (!isMatrix(B)) throw new Error("add: argument must be a Matrix");
    if (this.#rows !== B.rows || this.#cols !== B.cols) {
      throw new Error(
        `add: dimension mismatch [${this.#rows},${this.#cols}] vs [${B.rows},${B.cols}]`
      );
    }
    const bData = B.data;
    return new Matrix(
      this.#data.map((row, i) => row.map((val, j) => val + bData[i][j]))
    );
  }

  /**
   * Subtract another matrix of the same dimensions. Returns a new Matrix.
   * @param {Matrix} B
   */
  subtract(B) {
    if (!isMatrix(B)) throw new Error("subtract: argument must be a Matrix");
    if (this.#rows !== B.rows || this.#cols !== B.cols) {
      throw new Error(
        `subtract: dimension mismatch [${this.#rows},${this.#cols}] vs [${B.rows},${B.cols}]`
      );
    }
    const bData = B.data;
    return new Matrix(
      this.#data.map((row, i) => row.map((val, j) => val - bData[i][j]))
    );
  }

  /**
   * Multiply by a scalar or another Matrix.
   *   - scalar: returns a new Matrix with each entry scaled by arg.
   *   - Matrix: returns the matrix product (this.cols must equal arg.rows).
   * @param {number|Matrix} arg
   */
  multiply(arg) {
    if (typeof arg === 'number') {
      return new Matrix(this.#data.map(row => row.map(val => val * arg)));
    }
    if (isMatrix(arg)) {
      if (this.#cols !== arg.rows) {
        throw new Error(
          `multiply: incompatible dimensions [${this.#rows},${this.#cols}] * [${arg.rows},${arg.cols}]`
        );
      }
      const bData = arg.data;
      const result = [];
      for (let i = 0; i < this.#rows; i++) {
        result[i] = new Array(arg.cols).fill(0);
        for (let k = 0; k < this.#cols; k++) {
          const aik = this.#data[i][k];
          if (aik === 0) continue;
          for (let j = 0; j < arg.cols; j++) {
            result[i][j] += aik * bData[k][j];
          }
        }
      }
      return new Matrix(result);
    }
    throw new Error("multiply: argument must be a number or a Matrix");
  }

  // --- Utility --------------------------------------------------------------

  toString() {
    const rows = this.#data.map(row => '[' + row.join(', ') + ']');
    return '[' + rows.join(', ') + ']';
  }

  toTeX() {
    const rows = this.#data.map(row => row.join(' & '));

    let texString = '\\begin{bmatrix}\n';
    texString += rows.join(' \\\\\n');
    texString += '\\end{bmatrix}';

    return texString;
  }
}

// ---------------------------------------------------------------------------
// Exported functions
// ---------------------------------------------------------------------------

/**
 * Test whether the argument is a Matrix created by this library.
 * @param {*} A
 * @returns {boolean}
 */
function isMatrix(A) {
  return A instanceof Matrix;
}

/**
 * Parse a string representation of a matrix into a Matrix object.
 * The format is standard JSON array-of-arrays: [[a,b],[c,d]]
 * Whitespace, negative values, and scientific notation are all accepted.
 *
 * Throws if the format is invalid, dimensions are inconsistent,
 * or any entry is not a finite number.
 *
 * @param {string} matrixString
 * @returns {Matrix}
 */
function parseMatrix(matrixString) {
  if (typeof matrixString !== 'string') {
    throw new Error("parseMatrix: argument must be a string");
  }

  let parsed;
  try {
    parsed = JSON.parse(matrixString);
  } catch (e) {
    throw new Error(`parseMatrix: invalid JSON — ${e.message}`);
  }

  if (!Array.isArray(parsed)) {
    throw new Error("parseMatrix: top-level value must be an array");
  }
  if (parsed.length === 0) {
    throw new Error("parseMatrix: matrix must have at least one row");
  }

  const numCols = parsed[0].length;

  for (let i = 0; i < parsed.length; i++) {
    const row = parsed[i];
    if (!Array.isArray(row)) {
      throw new Error(`parseMatrix: row ${i} is not an array`);
    }
    if (row.length === 0) {
      throw new Error(`parseMatrix: row ${i} is empty`);
    }
    if (row.length !== numCols) {
      throw new Error(
        `parseMatrix: row ${i} has ${row.length} column(s), expected ${numCols}`
      );
    }
    for (let j = 0; j < row.length; j++) {
      if (typeof row[j] !== 'number' || !isFinite(row[j])) {
        throw new Error(
          `parseMatrix: entry [${i},${j}] is not a finite number (got ${JSON.stringify(row[j])})`
        );
      }
    }
  }

  return new Matrix(parsed);
}

/**
 * Test whether two matrices are equal up to a tolerance.
 * Uses the max-absolute-value (infinity) norm of the difference.
 * Returns false if dimensions differ.
 *
 * @param {Matrix} A
 * @param {Matrix} B
 * @param {number} [tol=1e-12]
 * @returns {boolean}
 */
function testMatrixEqual(A, B, tol = 1e-12) {
  if (!isMatrix(A) || !isMatrix(B)) {
    throw new Error("testMatrixEqual: arguments must be Matrix objects");
  }
  if (A.rows !== B.rows || A.cols !== B.cols) return false;

  const aData = A.data;
  const bData = B.data;
  for (let i = 0; i < A.rows; i++) {
    for (let j = 0; j < A.cols; j++) {
      if (Math.abs(aData[i][j] - bData[i][j]) >= tol) return false;
    }
  }
  return true;
}

/**
 * Compute the reduced row echelon form (RREF) of matrix A.
 * Uses Gaussian elimination with partial pivoting for numerical stability.
 * Returns a new Matrix; A is not modified.
 *
 * @param {Matrix} A
 * @returns {Matrix}
 */
function getRREF(A) {
  if (!isMatrix(A)) throw new Error("getRREF: argument must be a Matrix");

  const m = A.rows;
  const n = A.cols;
  const data = A.data; // deep copy to work on

  // Scale-adaptive zero threshold: larger entries need a larger eps to
  // avoid floating-point noise being mistaken for a nonzero pivot.
  let scale = 0;
  for (const row of data)
    for (const v of row)
      if (Math.abs(v) > scale) scale = Math.abs(v);
  const eps = Math.max(1e-14, scale * 1e-10);

  let pivotRow = 0;

  for (let col = 0; col < n && pivotRow < m; col++) {
    // Partial pivoting: find the row at or below pivotRow with the largest
    // absolute value in this column.
    let maxVal = Math.abs(data[pivotRow][col]);
    let maxRow = pivotRow;
    for (let row = pivotRow + 1; row < m; row++) {
      const v = Math.abs(data[row][col]);
      if (v > maxVal) { maxVal = v; maxRow = row; }
    }

    if (maxVal < eps) continue; // no usable pivot in this column

    // Swap the best pivot row into position.
    if (maxRow !== pivotRow) {
      [data[pivotRow], data[maxRow]] = [data[maxRow], data[pivotRow]];
    }

    // Scale the pivot row so the leading entry becomes 1.
    const pivot = data[pivotRow][col];
    for (let j = col; j < n; j++) {
      data[pivotRow][j] /= pivot;
    }

    // Eliminate all other rows (both above and below — full RREF).
    for (let row = 0; row < m; row++) {
      if (row === pivotRow) continue;
      const factor = data[row][col];
      if (Math.abs(factor) < eps) continue;
      for (let j = col; j < n; j++) {
        data[row][j] -= factor * data[pivotRow][j];
      }
    }

    pivotRow++;
  }

  return new Matrix(data);
}

/**
 * Test whether matrix A is in row echelon form.
 *
 * Row echelon conditions:
 *   - All-zero rows appear below any nonzero rows.
 *   - The leading (first nonzero) entry of each row is strictly to the right
 *     of the leading entry of the row above it.
 *
 * @param {Matrix} A
 * @param {boolean} [unit=false] - If true, also require each leading entry to equal 1.
 * @returns {boolean}
 */
function isRowEchelon(A, unit = false) {
  if (!isMatrix(A)) throw new Error("isRowEchelon: argument must be a Matrix");

  const tol = 1e-12;
  const data = A.data;
  const m = A.rows;
  const n = A.cols;

  let prevPivotCol = -1;
  let encounteredZeroRow = false;

  for (let row = 0; row < m; row++) {
    // Find the column of the first nonzero entry in this row.
    let pivotCol = -1;
    for (let col = 0; col < n; col++) {
      if (Math.abs(data[row][col]) > tol) { pivotCol = col; break; }
    }

    if (pivotCol === -1) {
      encounteredZeroRow = true;
    } else {
      if (encounteredZeroRow) return false;        // nonzero row after a zero row
      if (pivotCol <= prevPivotCol) return false;  // pivot not strictly to the right
      if (unit && Math.abs(data[row][pivotCol] - 1) > tol) return false;
      prevPivotCol = pivotCol;
    }
  }

  return true;
}

// ---------------------------------------------------------------------------
// Random matrix generation
// ---------------------------------------------------------------------------

/**
 * Choose `count` distinct columns from [0..cols-1] in increasing order.
 * Uses a partial Fisher-Yates shuffle for uniform random selection.
 * @param {object} rng - RNG with randInt(a,b) method
 * @param {number} count
 * @param {number} cols
 * @param {boolean} firstColPivot - true keeps column 0 among the choices, by
 *   starting the shuffle at index 1 so that entry is never swapped away
 * @returns {number[]}
 */
function _choosePivotCols(rng, count, cols, firstColPivot) {
  const arr = Array.from({ length: cols }, (_, i) => i);
  for (let i = firstColPivot ? 1 : 0; i < count; i++) {
    const j = rng.randInt(i, cols - 1);
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr.slice(0, count).sort((a, b) => a - b);
}

/**
 * Generate a random matrix in reduced row echelon form with the given
 * dimensions and rank. Pivot columns are chosen randomly; free-variable
 * entries are filled with single-digit integers via rng.randInt(-9, 9).
 *
 * @param {object} rng   - RNG object with random() and randInt(a,b) methods
 * @param {number} rows  - Number of rows (must be >= rank)
 * @param {number} cols  - Number of columns (must be >= rank)
 * @param {number} rank  - Number of nonzero pivot rows
 * @param {boolean} firstColPivot - true forces the first pivot to be in first column
 * @returns {Matrix}
 */
function getRandomRREF(rng, rows, cols, rank, firstColPivot=true) {
  if (!Number.isInteger(rows) || rows < 1) {
    throw new Error("getRandomRREF: rows must be a positive integer");
  }
  if (!Number.isInteger(cols) || cols < 1) {
    throw new Error("getRandomRREF: cols must be a positive integer");
  }
  if (!Number.isInteger(rank) || rank < 0) {
    throw new Error("getRandomRREF: rank must be a non-negative integer");
  }
  if (rank > rows) throw new Error("getRandomRREF: rank cannot exceed rows");
  if (rank > cols) throw new Error("getRandomRREF: rank cannot exceed cols");

  // Start with all zeros.
  const data = Array.from({ length: rows }, () => new Array(cols).fill(0));

  const pivotCols = _choosePivotCols(rng, rank, cols, firstColPivot);
  const pivotColSet = new Set(pivotCols);

  for (let i = 0; i < rank; i++) {
    const pc = pivotCols[i];
    data[i][pc] = 1; // leading 1 in pivot column
    // Entries left of the pivot must be 0 (row echelon condition).
    // Free columns strictly right of the pivot get random single-digit integers.
    // Other pivot columns remain 0 (RREF condition).
    for (let j = pc + 1; j < cols; j++) {
      if (!pivotColSet.has(j)) {
        data[i][j] = rng.randInt(-9, 9);
      }
    }
  }
  // Rows rank..rows-1 remain zero.

  return new Matrix(data);
}

/**
 * Generate a random matrix with the given dimensions and guaranteed rank.
 *
 * Strategy:
 *   1. Generate a full-rank rank×cols RREF matrix as the row-space basis.
 *   2. Scramble the basis rows with random elementary row operations
 *      (row_i += c * row_j, c in [-3,3]\{0}), which preserves rank.
 *   3. Append (rows - rank) extra rows as arbitrary integer linear
 *      combinations of the basis (these lie in the row space, so rank
 *      is not increased).
 *   4. Shuffle all rows so the independent rows are not predictably first.
 *
 * @param {object} rng   - RNG object with random() and randInt(a,b) methods
 * @param {number} rows  - Number of rows in the output (must be >= rank)
 * @param {number} cols  - Number of columns in the output (must be >= rank)
 * @param {number} rank  - Exact rank of the output matrix
 * @param {boolean} firstColPivot - true forces the first pivot of RREF to be in first column
* @returns {Matrix}
 */
function getRandomMatrix(rng, rows, cols, rank, firstColPivot=true) {
  if (!Number.isInteger(rows) || rows < 1) {
    throw new Error("getRandomMatrix: rows must be a positive integer");
  }
  if (!Number.isInteger(cols) || cols < 1) {
    throw new Error("getRandomMatrix: cols must be a positive integer");
  }
  if (!Number.isInteger(rank) || rank < 0) {
    throw new Error("getRandomMatrix: rank must be a non-negative integer");
  }
  if (rank > rows) throw new Error("getRandomMatrix: rank cannot exceed rows");
  if (rank > cols) throw new Error("getRandomMatrix: rank cannot exceed cols");

  // Rank-0 is a zero matrix — nothing to scramble or combine.
  if (rank === 0) {
    return new Matrix(Array.from({ length: rows }, () => new Array(cols).fill(0)));
  }

  // Step 1: full-rank basis.
  const basis = getRandomRREF(rng, rank, cols, rank, firstColPivot).data;

  // Step 2: scramble with elementary row ops to destroy RREF structure.
  // Coefficients from [-3,3]\{0} keep entry magnitudes reasonable.
  if (rank >= 2) {
    const numOps = Math.max(2 * rank, 3);
    for (let op = 0; op < numOps; ) {
      const i = rng.randInt(0, rank - 1);
      let j = rng.randInt(0, rank - 2);
      if (j >= i) j++;               // guarantee i ≠ j
      const c = rng.randInt(-3, 3);
      if (c === 0) continue;          // skip no-ops, don't count against numOps
      for (let k = 0; k < cols; k++) {
        basis[i][k] += c * basis[j][k];
      }
      op++;
    }
  }

  // Step 3: collect scrambled basis rows, then append combo rows.
  const result = basis.map(row => [...row]);

  for (let i = rank; i < rows; i++) {
    const newRow = new Array(cols).fill(0);
    for (let k = 0; k < rank; k++) {
      const c = rng.randInt(-9, 9);
      if (c === 0) continue;
      for (let j = 0; j < cols; j++) {
        newRow[j] += c * basis[k][j];
      }
    }
    result.push(newRow);
  }

  // Step 4: Fisher-Yates shuffle so independent rows aren't always first.
  for (let i = rows - 1; i > 0; i--) {
    const j = rng.randInt(0, i);
    [result[i], result[j]] = [result[j], result[i]];
  }

  return new Matrix(result);
}

/**
 * Test whether two matrices are row-equivalent (have the same RREF).
 * Returns false immediately if dimensions differ.
 *
 * @param {Matrix} A
 * @param {Matrix} B
 * @param {number} [tol=1e-12]
 * @returns {boolean}
 */
function testRowEquivalent(A, B, tol = 1e-12) {
  if (!isMatrix(A) || !isMatrix(B)) {
    throw new Error("testRowEquivalent: arguments must be Matrix objects");
  }
  if (A.rows !== B.rows || A.cols !== B.cols) return false;
  return testMatrixEqual(getRREF(A), getRREF(B), tol);
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------

export {
  Matrix,
  isMatrix,
  parseMatrix,
  testMatrixEqual,
  getRREF,
  isRowEchelon,
  getRandomRREF,
  getRandomMatrix,
  testRowEquivalent,
};
