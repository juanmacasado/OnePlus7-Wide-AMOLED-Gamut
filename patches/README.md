# Tested prebuilt patch tooling

These files reproduce the currently bundled five-mode HAL from the exact tested Infinity-X reference binary. They are retained for auditability and reproducibility of the distributed object.

The portable installer itself does not patch arbitrary ROM binaries. It checks the ROM's semantic/ABI contract and overlays the integrity-checked replacement only when compatible.

Logical source modification:

```cpp
{4, {"Wide AMOLED Gamut", 2, 3}},
```
