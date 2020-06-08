# Compile iPXE first (Tested working on Alpine v3.12)
FROM	alpine:3.12 AS compile-ipxe

# Install all necessary packages for compiling the iPXE binary files
RUN	apk --no-cache add	\
		git	\
		bash	\
		gcc	\
		binutils	\
		make	\
		perl	\
		xz-dev	\
		mtools	\
		cdrkit	\
		syslinux	\
		musl-dev	\
		coreutils	\
		openssl

# Define build argument for iPXE branch to clone/checkout
ARG	IPXE_BRANCH="master"

# Clone the iPXE repo
RUN	git clone --branch "${IPXE_BRANCH}" --single-branch "git://git.ipxe.org/ipxe.git" /ipxe.git/

# Enable Download via HTTPS, FTP, SLAM, NFS
RUN	sed -Ei "s/^#undef([ \t]*DOWNLOAD_PROTO_(HTTPS|FTP|SLAM|NFS)[ \t]*)/#define\1/" /ipxe.git/src/config/general.h

# Enable SANBoot via iSCSI, AoE, Infiniband SCSI RDMA, Fibre Channel, HTTP SAN
RUN	sed -Ei "s/^\/\/#undef([ \t]*SANBOOT_PROTO_(ISCSI|AOE|IB_SRP|FCP|HTTP)[ \t]*)/#define\1/" /ipxe.git/src/config/general.h

# Enable additional iPXE commands: nslookup, time, digest, lotest, vlan, reboot, poweroff, image_trust, pci, param, neighbour, ping, console, ipstat, profstat, ntp, cert
# Note that the "digest" command is not yet documented and the "pxe" command, while existing in the "general.h" file, breaks on compiling and is also not yet documented, thus the "pxe" command is excluded.
RUN	sed -Ei "s/^\/\/(#define[ \t]*(NSLOOKUP|TIME|DIGEST|LOTEST|VLAN|REBOOT|POWEROFF|IMAGE_TRUST|PCI|PARAM|NEIGHBOUR|PING|CONSOLE|IPSTAT|PROFSTAT|NTP|CERT)_CMD)/\1/" /ipxe.git/src/config/general.h

# Destination folder for compiled files
WORKDIR	/ipxe/

# Compile the files in "bin/"
ARG	IPXE_BIN="ipxe.dsk ipxe.lkrn ipxe.iso ipxe.usb ipxe.pxe undionly.kpxe rtl8139.rom 8086100e.mrom 80861209.rom 10500940.rom 10ec8139.rom 1af41000.rom 8086100f.mrom 808610d3.mrom 10222000.rom 15ad07b0.rom 3c509.rom intel.rom intel.mrom"
RUN	[ -z "${IPXE_BIN}" ] || (	\
	_bin="bin/${IPXE_BIN// / bin\/}"	\
	&& make -C /ipxe.git/src/ ${_bin}	\
	&& mkdir -v bin/	\
	&& for file in ${_bin} ;do ln -v /ipxe.git/src/${file} /ipxe/${file} ;done	\
	)

# Compile the files in "bin-i386-efi/"
ARG	IPXE_EFI="ipxe.efi ipxe.efidrv ipxe.efirom"
RUN	[ -z "${IPXE_EFI}" ] || (	\
	_efi="bin-i386-efi/${IPXE_EFI// / bin-i386-efi\/}"	\
	&& make -C /ipxe.git/src/ ${_efi}	\
	&& mkdir -v bin-i386-efi/	\
	&& for file in ${_efi} ;do ln -v /ipxe.git/src/${file} /ipxe/${file} ;done	\
	)

# Compile the files in "bin-x86_64-efi/"
ARG	IPXE_EFI64="ipxe.efi ipxe.efidrv ipxe.efirom"
RUN	[ -z "${IPXE_EFI64}" ] || (	\
	_efi64="bin-x86_64-efi/${IPXE_EFI64// / bin-x86_64-efi\/}"	\
	&& make -C /ipxe.git/src/ ${_efi64}	\
	&& mkdir -v bin-x86_64-efi/	\
	&& for file in ${_efi64} ;do ln -v /ipxe.git/src/${file} /ipxe/${file} ;done	\
	)

# Compile the files in "bin-x86_64-pcbios/"
ARG	IPXE_BIN64="8086100e.mrom intel.rom ipxe.usb ipxe.pxe undionly.kpxe"
# EXTRA_CFLAGS="-fno-pie" fixes gcc+ issue that causes the error "cc1: error: code model kernel does not support PIC mode"
# This is due to gcc 6+ versions having PIE (position independent executables) enabled by default.
# This flag must only be set for the bin-x86_64-pcbios/ build targets.
RUN	[ -z "${IPXE_BIN64}" ] || (	\
	_bin64="bin-x86_64-pcbios/${IPXE_BIN64// / bin-x86_64-pcbios\/}"	\
	&& make -C /ipxe.git/src/ EXTRA_CFLAGS="-fno-pie" ${_bin64}	\
	&& mkdir -v bin-x86_64-pcbios/	\
	&& for file in ${_bin64} ;do ln -v /ipxe.git/src/${file} /ipxe/${file} ;done	\
	)


# Create image from scratch
# Note that this image will ONLY contain the compiled iPXE files.
FROM	scratch

# Copy the previously compiled iPXE files
COPY	--from=compile-ipxe /ipxe/ /ipxe/

# Please use "COPY --from=this-image:latest /ipxe/ /your-ipxe/" to grab these files.
# Note that you can also selectively grab files from this image using this method.

