# iPXE compiled binary files in a Docker image

This is a Docker image providing compiled iPXE files.

## About iPXE

iPXE is a free, open-source implementation of the Preboot eXecution Environment client firmware and bootloader.

Tons more information on iPXE can be found here:  <https://ipxe.org/>

Please review the documentation on their homepage for more information on scripting and using iPXE commands in your scripts.

iPXE is extremely useful for reliable, stable, and fast network booting of images.  For example, iPXE can be used to boot very large images over a TCP HTTP connection instead of the regular UDP TFTP connection that most network boot options use.

## Using this Docker image

This Docker image is not meant to be ran directly, as it does not contain any executables and has no entrypoint.  Instead, this image is for use as a resource for other Docker image builds to copy from when needing compiled iPXE files.

Line example of use in a Dockerfile:

```Dockerfile
COPY --from=macgyverbass/ipxe:latest /ipxe/ /ipxe/
```

In the basic example above, all of the iPXE files from this image are copied into the image being built.

Note that it may be better to only copy the required files into a Docker image from this image.  The Dockerfile `COPY` instruction supports multiple selective files to be copied to a single destination using a single `COPY` instruction.  Here is a line example of this:

```Dockerfile
COPY --from=macgyverbass/ipxe:latest /ipxe/bin/undionly.kpxe /ipxe/bin-i386-efi/ipxe.efi /ipxe/
```

In this above example, only `undionly.kpxe` and `ipxe.efi` are copied into the destination `/ipxe/` folder, thus resulting in a smaller final image.  Note that care should be taken when copying multiple files using this method however, as there may be duplicate-named files needed to be copied and there may be unintended results.

More information on using the `COPY` instruction in this way can be found here:  [Use an external image as a "stage"](https://docs.docker.com/develop/develop-images/multistage-build/#use-an-external-image-as-a-stage)

## Quick breakdown on the compiling stage of this Docker image

The first stage is where all the work is performed.  Details on each step can be read by reviewing the Dockerfile itself.

In summary, this image starts by using Alpine as the base image, it then downloads the necessary files for compiling, clones the git repository, tweaks `/ipxe.git/src/config/general.h` to enable several additional protocols and iPXE commands, then begins compiling all the main iPXE files.

Compiling of different types ("bin", "bin-i386-efi", "bin-x86_64-efi", and "bin-x86_64-pcbios") are done in separate `RUN make ...` commands and the resulting compiled files are then copied/hard-linked into a new folder `/ipxe/` for easier copying later.

The `make` command for building the files in "bin-x86_64-pcbios/" requires `EXTRA_CFLAGS="-fno-pie"` as this fixes an issue with gcc 6+ versions having PIE (position independent executables) enabled by default.

## Details on the Docker build

This is a multi-stage Docker image, done so to compile iPXE and put the compiled files into the final stage.

To make the final build as small as possible, it then builds the image from scratch, adding only the compiled iPXE files to the final build.

The end result is a Docker image with only the compiled iPXE files.  Note that this means this image cannot be ran like other images, but is instead designed to be a resource for grabbing compiled iPXE files for another Docker image build.

## Building/Advanced Usage

By default, this Docker image uses the latest iPXE branch (master) and builds multiple types ("bin", "bin-i386-efi", "bin-x86_64-efi", and "bin-x86_64-pcbios") of the iPXE binary files.  However, you may build this image with different choices by specifying alternate build-arguments.

Build arguments that are available:

* `IPXE_BRANCH` - This specifies the branch/tag to pull/checkout from the iPXE repository, which uses "master" by default.
* `IPXE_BIN` - This specifies the files in "bin/" to compile, which uses "ipxe.dsk ipxe.lkrn ipxe.iso ipxe.usb ipxe.pxe undionly.kpxe rtl8139.rom 8086100e.mrom 80861209.rom 10500940.rom 10ec8139.rom 1af41000.rom 8086100f.mrom 808610d3.mrom 10222000.rom 15ad07b0.rom 3c509.rom intel.rom intel.mrom" by default.
* `IPXE_EFI` - This specifies the files in "bin-i386-efi/" to compile, which uses "ipxe.efi ipxe.efidrv ipxe.efirom" by default.
* `IPXE_EFI64` - This specifies the files in "bin-x86_64-efi/" to compile, which uses "ipxe.efi ipxe.efidrv ipxe.efirom" by default.
* `IPXE_BIN64` - This specifies the files in "bin-x86_64-pcbios/" to compile, which uses "8086100e.mrom intel.rom ipxe.usb ipxe.pxe undionly.kpxe" by default.

As noted above, you can specify a different iPXE branch/tag to pull/checkout and/or specific files to build in the image.

This may be useful for debugging or if your image requires a specific version of the iPXE files.

More information on using Docker build-arguments can be found here:  [Set build-time variables (--build-arg)](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg)
