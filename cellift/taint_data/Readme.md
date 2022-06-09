# Taint data

## Overview

The taint data is orgnaized as a sequence of lines as follows:

```
taint_id address num_bytes byte_taints
```

## Example

```
1 100  4 1f030000
0 1000 8 a3010fe5c691ad2f
```

## Endianness

The byte description is given in the byte order (similar to big endian).
Little-endian application requires the _byte\_taints_ field to be adapted.
