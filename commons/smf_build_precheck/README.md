Precheck lane, to detect if a `build_variant` could be build.
Common issues could be detected here.

This lane will crash if something is not set properly.


Example Call:

```
smf_build_precheck(
    build_variant: build_variant,
    build_variant_config: build_variant_config
)
```