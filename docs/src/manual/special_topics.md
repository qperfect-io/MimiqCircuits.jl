# Special Topics

This page provides detailed information on specialized functionalities in MIMIQ.

- [Special Topics](#special-topics)
  - [BitString](#bitstring)
    - [Using BitString in MIMIQ Operations](#using-bitstring-in-mimiq-operations)
    - [Constructors](#constructors)
    - [Accessing and Modifying Bits](#accessing-and-modifying-bits)
    - [Conversion and Manipulation Methods](#conversion-and-manipulation-methods)
    - [Bitwise Operators](#bitwise-operators)
    - [Concatenation and Repetition](#concatenation-and-repetition)

## BitString

The [`BitString`](@ref) class represents the state of bits and can be used to represent classical registers with specified values for each bit (0 or 1). At its core, it is simply a vector of `Bool`s.
[`BitString`](@ref) allows direct bit manipulation, bitwise operations, and conversion to other data formats like integers. It’s designed for flexibility in binary manipulation tasks within quantum computations.

### Using BitString in MIMIQ Operations

In MIMIQ, several operations use BitString as a direct input for conditional logic or specific quantum operations, such as [`IfStatement`](@ref) and [`Amplitude`](@ref), see [non-unitary operations](non_unitary_ops.md) and [statistical operations](statistical_ops.md) pages. Here are some examples:

```@example remoteexec
using MimiqCircuits # hide

# Conditional Operation: IfStatement
if_statement = IfStatement(GateX(), BitString("01011"))

# Amplitude Operation
Amplitude(BitString("001"))
```

### Constructors

[`BitString`](@ref)s can be constructed in different ways.

- **From a String:** You can use the `BitString("binary_string")` to initialize a `BitString` by parsing a string in binary format.

  ```@example remoteexec
  using MimiqCircuits # hide

  # Initialize a BitString from a binary string representation
  BitString("1101")
  ```

  Alternatively, you can use the syntax `bs"binary_string"` to create the same `BitString`.

  ```@example remoteexec
  using MimiqCircuits # hide

  # Initialize a BitString using the bs"..." literal syntax
  bs"01"
  ```

- **From bit locations:** You can use the `BitString(numbits[; bit_indices])` syntax to initialize a `BitString` of `numbits` bits, setting specific bits indicated by `bit_indices` to 1.

  ```@example remoteexec
  using MimiqCircuits # hide

  # Initializing with Specific Bits
  BitString(8, [2, 4, 6])
  ```
  
- **From a function:** You can use the `BitString(f::Function, numbits)` syntax to initialize a `BitString` with `numbits`, where each bit is set based on the result of the provided function `f` applied on each index.

  ```@example remoteexec
  using MimiqCircuits # hide

  # Initialize an 8-bit BitString where bits are set based on even indices
  BitString(8) do i
          iseven(i)
        end
  ```

### Accessing and Modifying Bits

Each bit in a `BitString` can be accessed or modified individually in the same way as vectors, making it easy to retrieve or set specific bit values.

```julia
using MimiqCircuits # hide

# Accessing a Bit
bs=BitString(4, [1, 3])

println(bs[2])

# Modifying a Bit
bs[2] = true

bs
```

A useful function is [`nonzeros`](@ref) which returns the indices of the non-zero bits in a `BitString`.

```@example remoteexec
  using MimiqCircuits # hide

  bs = BitString(6, [1, 3, 5]) # hide

  # Retrieve Non-Zero Indices
  nonzeros(bs)
```

### Conversion and Manipulation Methods

The [`BitString`](@ref) class includes functionality for conversion to integer representations, indexing, and other methods for retrieving and manipulating bit values:

- **BitString to Integer:** To convert a `BitString` into its integer representation, you can use the function [`bitstring_to_integer`](@ref). By default it uses a big-endian order.

  ```@example remoteexec
  using MimiqCircuits # hide
  bs = BitString("101010")
  
  # Convert BitString to Integer (big-endian by default)
  bitstring_to_integer(bs)
  ```
  
  Alternatively, you can use the function [`bitstring_to_index`](@ref), which converts a `BitString` to an index for purposes like vector indexing, checking bounds, and compatibility with 64-bit indexing constraints. It's essentially the same as `bitstring_to_integer` but shifted by 1.

  ```@example remoteexec
  using MimiqCircuits # hide
  bs = BitString("101010")

  # Convert BitString to Index (Offset by 1 for Julia's 1-based indexing)
  bitstring_to_index(bs)
  ```

- **BitString to String:** To convert a `BitString` into a `String` of "0" and "1" characters, you can use the function [`to01`](@ref).

  ```@example remoteexec
  using MimiqCircuits # hide
  bs = BitString("101010")

  # Convert BitString to String of "0"s and "1"s (big-endian)
  println(to01(bs))

  # Convert BitString to String of "0"s and "1"s (little-endian)
  to01(bs, endianess=:little)
  ```

    

### Bitwise Operators

[`BitString`](@ref) supports bitwise operations such as NOT, AND, OR, XOR, as well as bitwise shifts:

- **Bitwise NOT**: `~`

  ```@example remoteexec
    using MimiqCircuits # hide
    bs = BitString("1011")

    # Bitwise NOT
    ~bs
  ```

- **Bitwise AND and OR**: `&`, `|`

  ```@example remoteexec
    using MimiqCircuits # hide
    bs1 = BitString("1100")
    bs2 = BitString("0110")

    # Bitwise AND
    bs1 & bs2
  ```

  ```@example remoteexec
    # Bitwise OR
    bs1 | bs2
  ```

- **Bitwise XOR**: `⊻`

  ```@example remoteexec
    using MimiqCircuits # hide
    bs1 = BitString("1100") # hide
    bs2 = BitString("0110") # hide

    # Bitwise XOR
    bs1 ⊻ bs2
  ```

- **Left Shift**: `<<`, and **Right Shift**: `>>`

  ```@example remoteexec
    using MimiqCircuits # hide
    bs1 = BitString("1100") # hide
    bs2 = BitString("0110") # hide

    # Left Shift
    bs << 1
  ```

  ```@example remoteexec
    # Right Shift
    bs >> 1
  ```

### Concatenation and Repetition

[`BitString`](@ref) supports concatenation and repetition, allowing you to combine or extend bitstrings efficiently:

- **Concatenation**: Use `vcat` to combines two `BitString` objects by appending the bits of `rhs` to `lhs`.

- **Repetition**: Use `repeat` to repeats the `BitString` a specified number of times, creating a new `BitString` with the pattern repeated.

**Examples**:

```@example remoteexec
using MimiqCircuits # hide

# Define two BitString objects
bs1 = BitString("1010")
bs2 = BitString("0101")

# Concatenate bs1 and bs2
vcat(bs1, bs2)
```

```@example remoteexec
# Repeat bs1 two times
repeat(bs1, 2)
```
