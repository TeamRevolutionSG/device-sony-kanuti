#!/sbin/busybox sh
set +x
_PATH="$PATH"
export PATH=/sbin

busybox cd /
busybox date >>boot.txt
exec >>boot.txt 2>&1
busybox rm /init

# leds paths
LED_R_BRIGHTNESS_FILE="/sys/class/leds/led:rgb_red/brightness"
LED_G_BRIGHTNESS_FILE="/sys/class/leds/led:rgb_green/brightness"
LED_B_BRIGHTNESS_FILE="/sys/class/leds/led:rgb_blue/brightness"
LED1_R_CURRENT_FILE="/sys/class/leds/led:rgb_red/lut_pwm"
LED1_G_CURRENT_FILE="/sys/class/leds/led:rgb_green/lut_pwm"
LED1_B_CURRENT_FILE="/sys/class/leds/led:rgb_blue/lut_pwm"
BOOTREC_VIBRATOR="/sys/class/timed_output/vibrator/enable"

# create directories
busybox mkdir -m 755 -p /dev/block
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys

# include device specific vars
source /sbin/bootrec-device

# create device nodes
# Per linux Documentation/devices.txt
busybox mknod -m 600 /dev/block/mmcblk0 b 179 0
for i in $(busybox seq 0 12); do
	busybox mknod -m 600 /dev/input/event${i} c 13 $(busybox expr 64 + ${i})
done
busybox mknod -m 666 /dev/null c 1 3
# mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys

# keycheck
busybox timeout -t 3 keycheck

# LED PWM ON FOR CURRENT
busybox echo 255 > $LED_R_BRIGHTNESS_FILE
busybox echo 255 > $LED_G_BRIGHTNESS_FILE

# LED Boot Animation Sequence
echo '16' > $LED1_G_CURRENT_FILE
busybox sleep 0.05
echo '32' > $LED1_G_CURRENT_FILE
busybox sleep 0.05
echo '64' > $LED1_G_CURRENT_FILE
busybox sleep 0.05
echo '92' > $LED1_G_CURRENT_FILE
busybox sleep 1
echo '64' > $LED1_G_CURRENT_FILE
busybox sleep 0.05
echo '32' > $LED1_G_CURRENT_FILE
busybox sleep 0.05
echo '0' > $LED_G_BRIGHTNESS_FILE
echo '0' > $LED1_G_CURRENT_FILE
echo '16' > $LED1_R_CURRENT_FILE
busybox sleep 0.05
echo '32' > $LED1_R_CURRENT_FILE
busybox sleep 0.05
echo '64' > $LED1_R_CURRENT_FILE
busybox sleep 0.05
echo '92' > $LED1_R_CURRENT_FILE
busybox sleep 1
echo '64' > $LED1_R_CURRENT_FILE
busybox sleep 0.05
echo '32' > $LED1_R_CURRENT_FILE
busybox sleep 0.05
echo '0' > $LED1_R_BRIGHTNESS_FILE
echo '0' > $LED1_R_CURRENT_FILE

# android ramdisk
load_image=/sbin/ramdisk.cpio


# boot decision
if [ -s /dev/keycheck ] || busybox grep -q warmboot=0x77665502 /proc/cmdline ; then
	busybox echo 'RECOVERY BOOT' >>boot.txt
	# recovery ramdisk
	busybox mknod -m 600 ${BOOTREC_FOTA_NODE}
	busybox mount -o remount,rw /
	busybox ln -sf /sbin/busybox /sbin/sh
	extract_elf_ramdisk -i ${BOOTREC_FOTA} -o /sbin/ramdisk-recovery.cpio -t / -c
	busybox rm /sbin/sh
	load_image=/sbin/ramdisk-recovery.cpio
	busybox echo 100 > ${BOOTREC_VIBRATOR}
	echo '255' > $LED_B_BRIGHTNESS_FILE
	echo '32' > $LED1_B_CURRENT_FILE
	busybox sleep 0.05
	echo '64' > $LED1_B_CURRENT_FILE
	busybox sleep 0.05
	echo '128' > $LED1_B_CURRENT_FILE
	busybox sleep 1
	echo '64' > $LED1_B_CURRENT_FILE
	busybox sleep 0.05
	echo '32' > $LED1_B_CURRENT_FILE
	busybox sleep 0.05
	echo '0' > $LED_B_BRIGHTNESS_FILE
	echo '0' > $LED1_B_CURRENT_FILE
else
	busybox echo 'ANDROID BOOT' >>boot.txt
	echo '255' > $LED1_G_BRIGHTNESS_FILE
	echo '32' > $LED1_G_CURRENT_FILE
	busybox sleep 0.05
	echo '64' > $LED1_G_CURRENT_FILE
	busybox sleep 0.05
	echo '128' > $LED1_G_CURRENT_FILE
	busybox sleep 1
	echo '64' > $LED1_G_CURRENT_FILE
	busybox sleep 0.05
	echo '32' > $LED1_G_CURRENT_FILE
	busybox sleep 0.05
	echo '0' > $LED1_G_BRIGHTNESS_FILE
	echo '0' > $LED1_G_CURRENT_FILE
fi

#Turn off vibrator
busybox echo 0 > ${BOOTREC_VIBRATOR}

# unpack the ramdisk image
busybox cpio -i < ${load_image}

busybox umount /proc
busybox umount /sys

busybox rm -fr /dev/*
busybox date >>boot.txt
export PATH="${_PATH}"
exec /init
