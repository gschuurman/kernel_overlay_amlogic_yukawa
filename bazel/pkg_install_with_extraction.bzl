# SPDX-License-Identifier: GPL-2.0
"""
Custom pkg_install rule that automatically extracts tar files after installation.
"""

def _pkg_install_with_extraction_impl(ctx):
    """Implementation of pkg_install_with_extraction rule."""

    # Find the install script from pkg_install
    install_script = None
    for file in ctx.attr.pkg_install_target.files.to_list():
        if file.basename.endswith("_install_script.py"):
            install_script = file
            break

    if not install_script:
        fail("Could not find install script in pkg_install target")

    # Create the extraction script
    extraction_script = ctx.actions.declare_file(ctx.label.name + ".sh")

    script_content = """#!/bin/bash
set -e

# Get script directory and find the install script in runfiles
RUNFILES_DIR="${{RUNFILES_DIR:-$0.runfiles}}"
if [ ! -d "$$RUNFILES_DIR" ]; then
    RUNFILES_DIR="$(dirname $0)/../.."
fi

# Find python3
PYTHON="${{PYTHON:-python3}}"

echo "Running pkg_install..."
# Run the install script directly
$$PYTHON "{install_script_runfiles_path}" "$@"

DESTDIR="{destdir}"

echo "Extracting filtered module archives..."

# Extract system_dlkm modules
if [ -f "$DESTDIR/system_dlkm/system_dlkm_filtered.tar" ]; then
    echo "  Extracting system_dlkm modules..."
    tar -xf "$DESTDIR/system_dlkm/system_dlkm_filtered.tar" -C "$DESTDIR/system_dlkm/"
    rm "$DESTDIR/system_dlkm/system_dlkm_filtered.tar"
    MODULE_COUNT=$(ls "$DESTDIR/system_dlkm"/*.ko 2>/dev/null | wc -l)
    echo "    $MODULE_COUNT modules extracted to system_dlkm/"
fi

# Extract vendor_dlkm modules
if [ -f "$DESTDIR/vendor_dlkm/vendor_dlkm_filtered.tar" ]; then
    echo "  Extracting vendor_dlkm modules..."
    tar -xf "$DESTDIR/vendor_dlkm/vendor_dlkm_filtered.tar" -C "$DESTDIR/vendor_dlkm/"
    rm "$DESTDIR/vendor_dlkm/vendor_dlkm_filtered.tar"
    MODULE_COUNT=$(ls "$DESTDIR/vendor_dlkm"/*.ko 2>/dev/null | wc -l)
    echo "    $MODULE_COUNT modules extracted to vendor_dlkm/"
fi

# Extract ramdisk modules
if [ -f "$DESTDIR/ramdisk/ramdisk_filtered.tar" ]; then
    echo "  Extracting ramdisk modules..."
    tar -xf "$DESTDIR/ramdisk/ramdisk_filtered.tar" -C "$DESTDIR/ramdisk/"
    rm "$DESTDIR/ramdisk/ramdisk_filtered.tar"
    MODULE_COUNT=$(ls "$DESTDIR/ramdisk"/*.ko 2>/dev/null | wc -l)
    echo "    $MODULE_COUNT modules extracted to ramdisk/"
fi

echo "Done! Filtered modules extracted successfully."
""".format(
        install_script_runfiles_path = install_script.short_path,
        destdir = ctx.attr.destdir,
    )

    ctx.actions.write(
        output = extraction_script,
        content = script_content,
        is_executable = True,
    )

    # Return the extraction script as the executable with all necessary runfiles
    runfiles = ctx.runfiles(files = [extraction_script, install_script])
    if hasattr(ctx.attr.pkg_install_target[DefaultInfo], "default_runfiles"):
        runfiles = runfiles.merge(ctx.attr.pkg_install_target[DefaultInfo].default_runfiles)

    return [DefaultInfo(
        executable = extraction_script,
        runfiles = runfiles,
    )]

pkg_install_with_extraction = rule(
    implementation = _pkg_install_with_extraction_impl,
    attrs = {
        "pkg_install_target": attr.label(
            doc = "The pkg_install target to run and then extract tars from",
            mandatory = True,
        ),
        "destdir": attr.string(
            doc = "Destination directory for installation",
            mandatory = True,
        ),
    },
    executable = True,
)
