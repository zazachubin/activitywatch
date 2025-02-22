#!/bin/bash

set -e

function get_platform() {
    # Will return "linux" for GNU/Linux
    #   I'd just like to interject for a moment...
    #   https://wiki.installgentoo.com/index.php/Interjection
    # Will return "macos" for macOS/OS X
    # Will return "windows" for Windows/MinGW/msys

    _platform=$(uname | tr '[:upper:]' '[:lower:]')
    if [[ $_platform == "darwin" ]]; then
        _platform="macos";
    elif [[ $_platform == "msys"* ]]; then
        _platform="windows";
    elif [[ $_platform == "mingw"* ]]; then
        _platform="windows";
    elif [[ $_platform == "cygwin"* ]]; then
        echo "ERROR: cygwin is not a valid platform";
        exit 1;
    fi

    echo $_platform;
}

function get_version() {
    if [[ $TRAVIS_TAG ]]; then
        _version=$TRAVIS_TAG;
    elif [[ $APPVEYOR_REPO_TAG_NAME ]]; then
        _version=$APPVEYOR_REPO_TAG_NAME;
    else
        _version=$(git rev-parse --short HEAD)
    fi

    echo $_version;
}

function get_arch() {
    _arch="$(uname -m)"
    echo $_arch;
}

platform=$(get_platform)
version=$(get_version)
arch=$(get_arch)
echo "Platform: $platform, arch: $arch, version: $version"

function build_zip() {
    echo "Zipping executables..."
    pushd dist;
    filename="activitywatch-${version}-${platform}-${arch}.zip"
    echo "Name of package will be: $filename"

    if [[ $platform == "windows"* ]]; then
        7z a $filename activitywatch;
    else
        zip -r $filename activitywatch;
    fi
    popd;
    echo "Zip built!"
}

function build_setup() {
    filename="activitywatch-setup-${version}-${platform}-${arch}.exe"
    echo "Name of package will be: $filename"

    choco install -y innosetup

    "/c/Program Files (x86)/Inno Setup 6/iscc.exe" scripts/package/activitywatch-setup.iss
    mv dist/activitywatch-setup.exe dist/$filename
    echo "Setup built!"
}


build_zip
if [[ $platform == "windows"* ]]; then
    build_setup
fi

echo
echo "-------------------------------------"
echo "Contents of ./dist"
ls -l dist
echo "-------------------------------------"

