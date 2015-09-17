#!/bin/sh
###modified from http://blog.csdn.net/favormm/article/details/6772097
set -xe

DEVELOPER=`xcode-select -print-path`
DEST=`pwd .`"/libfdk-aac"

ARCHS="x86_64 armv7 armv7s arm64"
LIBS="libfdk-aac.a"

mkdir -p $DEST

./configure

for arch in $ARCHS; do
        make clean
        IOSMV=" -miphoneos-version-min=5.0"
        case $arch in
        arm*)
                if [ $arch == "arm64" ]
                then
                        IOSMV=" -miphoneos-version-min=7.0"
                fi
                echo "Building opencore-amr for iPhoneOS $arch ****************"
                PATH=`xcodebuild -version -sdk iphoneos PlatformPath`"/Developer/usr/bin:$PATH" \
                SDK=`xcodebuild -version -sdk iphoneos Path` \
		CC="xcrun --sdk iphoneos clang -arch $arch $IOSMV --sysroot=$SDK -isystem $SDK/usr/include"\
                CXX="xcrun --sdk iphoneos clang++ -arch $arch $IOSMV --sysroot=$SDK -isystem $SDK/usr/include" \
                LDFLAGS="-Wl,-syslibroot,$SDK" \
                ./configure \
                --host=arm-apple-darwin \
                --prefix=$DEST \
                --disable-shared
                ;;
        *)
                echo "Building opencore-amr for iPhoneSimulator $arch *****************"
                PATH=`xcodebuild -version -sdk iphonesimulator PlatformPath`"/Developer/usr/bin:$PATH" \
		SDKROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)
		CC="$(xcrun --sdk iphonesimulator -f clang)"
		CXX="xcrun --sdk iphonesimulator clang++ -arch $arch $IOSMV -miphoneos-version-min=5.0" \
                ./configure \
                --prefix=$DEST \
                --disable-shared
                ;;
        esac
	make -j3
        make install
        for i in $LIBS; do
                mv $DEST/lib/$i $DEST/lib/$i.$arch
        done
done

echo "Merge into universal binary."

for i in $LIBS; do
        input=""
        for arch in $ARCHS; do
                input="$input $DEST/lib/$i.$arch"
        done
        xcrun lipo -create -output $DEST/lib/$i $input
done

