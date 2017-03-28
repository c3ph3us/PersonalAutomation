#!/bin/bash
function usage
{
  printf "\nUsage:   automation.bash [-do device] [-c] [-ko] [-s] [-fs] [-u] [-h]\n"
  printf "
-do |  --device-overide  Overides the device specified in config.cfg
-c  |  --clober          Clobbers your build before starting
-ko |  --kernel-only     Only builds the kernel for the specified device
-s  |  --sync            Repo sync before build
-fs |  --force-sync      Repo sync --force-sync before building
-u  |  --upload          Do you want to upload using rclone
-h  |  --help            You're looking at it! :) \n"
  exit
}

source config.cfg

while [ "$1" != "" ]; do
    case $1 in
        -do  | --device-overide ) shift
                                  device=$1
                                  ;;
        -c  | --clobber )         clobber=1
                                  ;;
        -ko | --kernel-only )     kernelonly=1
                                  ;;
        -s  | --sync )            sync=1
                                  ;;
        -fs | --force-sync )      forcesync=1
                                  sync=1
                                  ;;
        -u  | --upload )          upload=1
                                  ;;
        -h  | --help )            usage
                                  exit
                                  ;;
        * )                       usage
                                  exit 1
    esac
    shift
done

if [ "$device" == "The Device Codename You are building. For example, the Samsung Galaxy Note 3 is hlte" ]
  then
    echo "Please Specify A Device To Build For. This Can Be Done In config.cfg Or With The --device-overide Flag."
    exit
fi

if [ "$sourcelocation" == "Path To Your Android Source Location" ]
  then
    echo "Please Specify Where Your Android Source Code Is Locatated In config.cfg"
    exit
fi

if [ "$upload" == "1" ]
  then
    if [ "$share" == "the rclone storage option name you have setup. ignore this if you arent uploading." ]
      then
        echo "You have chosen to upload using rclone but havent specified your rclone storage name in config.cfg"
        exit
    fi
fi

now=$(date +"%m_%d_%Y")
time1=$(date +"%H-%M")

echo "Changing to $sourcelocation"
cd $sourcelocation
echo "Changed Directory"
if [ "$sync" == "1" ]
  then
    if [ "$forcesync" == "1" ]
      then
        echo "Syncing with repo sync --force-sync"
        repo sync --force-sync
      else
        echo "Syncing with repo sync"
        repo sync
    fi
fi
source build/envsetup.sh
echo "Breakfast $device now"
breakfast $device
if [ "$clobber" == "1" ]
  then
    echo "Clobbering"
    make clobber
fi
if [ "$kernelonly" == "1" ]
  then
    echo "Making bootimage"
    mka bootimage
    mv $sourcelocation/out/target/product/$device/boot.img $sourcelocation/out/target/product/$device/boot-trader418-$now--$time1.img
  else
    echo "Building ROM for $device"
    brunch $device
    mv $sourcelocation/out/target/product/$device/lineage*.zip $sourcelocation/out/target/product/$device/lineage-trader418-$device-$now--$time1.zip
fi
if [ "$upload" == "1" ]
  then
    if [ "$kernelonly" == "1" ]
      then
        echo "Uploading kernel to GDrive/$device/boot"
        rclone copy $sourcelocation/out/target/product/$device/boot-$now--$time1.img $share:$device/boot
      else
        echo "Uploading ROM to GDrive/$device/LineageRoms"
        rclone copy $sourcelocation/out/target/product/$device/lineage-trader418-$device-$now--$time1.zip $share:$device/LineageRoms
    fi
fi
