#!/bin/sh

# goreleaser-architecture = zig-architecture
declare -A BUILDS
BUILDS=( ["linux_amd64"]="x86_64-linux" ["darwin_amd64"]="x86_64-macos" ["windows_amd64"]="x86_64-windows")


if [ -z "$1" ] || [ -z "$2" ]; then
	echo "Specify goeleaser arch name and binary name"
	exit 1;
fi

# The args come from goreleaser.
GO_ARCH=$1
BIN=$2
ZIG_ARCH=${BUILDS[$GO_ARCH]}
GO_PATH=dist/${BIN}_${GO_ARCH}

if [ -z "$ZIG_ARCH" ]; then
	echo "${GO_ARCH} not found in the build map"
	exit 1;
fi

echo "building $GO_ARCH => $ZIG_ARCH"

rm -rf $GO_PATH
rm -rf zig-cache/*
rm -rf zig-out/*

# Build.
zig build -Drelease-fast=true -Dtarget=$ZIG_ARCH

# Copy all results to goreleaser dist.
mkdir -p $GO_PATH
cp -R zig-out/bin/* $GO_PATH
