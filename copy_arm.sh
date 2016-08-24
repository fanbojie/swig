#!/usr/bin/env sh

ARM_JAVA_PATH=../workspace/common/src/main/java/com/webex/eureka/arm/wrapper
ARM_WRAPPER_INCLUDE=../ArmWrapper/Include
ARM_WRAPPER_SRC=../ArmWrapper/Src

echo "start copy arm java file"
rm -rf ${ARM_JAVA_PATH}/*.java
cp -f *.java ${ARM_JAVA_PATH}
echo "copy arm java file end"

echo "start copy arm wrapper file"
cp -f gcc_wrap.h ${ARM_WRAPPER_INCLUDE}
cp -f gcc.h ${ARM_WRAPPER_INCLUDE}
cp -f *.cxx ${ARM_WRAPPER_SRC}/gcc_wrap.cpp
rm -rf ${ARM_WRAPPER_SRC}/*.cxx

echo "copy arm wrapper file end"
 
