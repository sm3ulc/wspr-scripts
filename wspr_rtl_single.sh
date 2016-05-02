#!/bin/bash
wd="/home/davidl/wspr/rtl"
htmldir="/var/www/html"
d=$(date -u +"%Y%m%d%H%M")
d2=$(date -u +"%Y-%m-%d %H:%M")
d3=$(date -u +"%Y%m%d-%H%M")
d4=$(date -u +"%y%m%d %H%M")

# Userdata
call=SM0ULC
grid=JO89ul


# Userdata
call=SM0ULC
grid=JO89ul

# Radio & time
time=115
dev=RTL
rtl_dev=0
# Upconverter base fq
upconv=125000000
gr=20
dec=50
sr=2048000
sr=2400000

# Spectrogram 

dBFS=45
dBFS_max=-20
height=1200
width=1000

bands=(80m 40m 30m 20m) 
freqs_base=(3500000 7000000 10000000 14000000)
freqs_wspr=(3592600 7038600 10138600 14095600)
freqs_ppm=(-25 -23 -23 -22)

# Rotate over all bands
# let db=$(date +"%M");let db=(db/2)%3+1

# Rotate over bands
let db=$((10#`date +"%M"`));
let db=(db/2)%4

band=${bands[$db]}
ppm=${freqs_ppm[$db]}

case $band in
    80m)
	ft=3592600
	fs=3500000
	;;
    40m)
	ft=7038600
	fs=7000000
	;;
    30m)
	ft=10138600
	fs=10000000
	;;
    20m)
	ft=14095600
	fs=14000000
	;;
    *)
	echo "Error in case"
	exit
	;;
esac
cd $wd

echo "############################################## Running $band - iqread ##############################################"

# Read iq-data
let rtlfs=fs+upconv

# For dongle with TCXO like rtl-sdr.com the you can read
timeout $time /usr/local/bin/rtl_sdr -s $sr -f $rtlfs -g $gr -d $rtl_dev -p $ppm iq_$d.raw

# For dongles without TCXO one need to keep it running. Start rtl_tcp in a separate shell and uncomment nc-row below.
# rtl_tcp -a 0.0.0.0 -s 2400000 -f 135000000 -g 20 -d 1 -P -23 -p 4321

# timeout $time nc localhost 4321 >iq_$d.raw

echo "############################################## Running $band - wspr ##############################################"
# Demoding
cat iq_$d.raw | \
    csdr convert_u8_f | \
    csdr shift_addition_cc `python -c "print float($fs-$ft)/$sr"` | \
    csdr fir_decimate_cc $dec 0.005 HAMMING | \
    csdr bandpass_fir_fft_cc 0 0.5 0.05 | \
    csdr realpart_cf | \
    csdr agc_ff | \
    csdr limit_ff | \
    csdr convert_f_s16 >$d-ssb-demod.raw

# Create wav for decoding
sox -r 48k -e signed -b 16 -c 1 $d-ssb-demod.raw -r 12k wspr-$d3.wav

# Create spectrograms
sox -r 48k -e signed -b 16 -c 1 $d-ssb-demod.raw -n rate 48k spectrogram -x $height -Y $width -z $dBFS -Z $dBFS_max -c "$d2 - RTL USB $band - $ft"  -o $band-rtl.png
sox -r 48k -e signed -b 16 -c 1 $d-ssb-demod.raw -n rate 6k  spectrogram -x $height -Y $width -z $dBFS -Z $dBFS_max -c "$d2 - RTL WSPR $band - $ft" -o $band-wspr-rtl.png

# Spectrogram for waterfall
sox -r 48k -e signed -b 16 -c 1 $d-ssb-demod.raw -n rate 4k  spectrogram -x 100 -Y 1500 -z $dBFS -Z $dBFS_max -c "$d2 - RTL WSPR $band - $ft" -r -o $band-wspr-rtl-1.png
convert -rotate 90 -flip $band-wspr-rtl-1.png $band-wspr-rtl-2.png 
ww=`convert $band-wspr-rtl-2.png -format "%w" info:` 
convert $band-wspr-rtl-2.png \( -background none -size ${ww}x -fill white \
    -font Helvetica -pointsize 14 label:"$d2 - $band" \) \
    -gravity north -compose over -composite $band-wspr-rtl-r.png

# Upload spots
wfq=$(echo 'scale=6;'$ft'/1000000' | bc)
/usr/bin/wsprd -f $wfq -w wspr-$d3.wav 
# /usr/bin/wsprd_exp -f $wfq -w -d -C 50000 wspr-$d3.wav 
grep "$d4" ALL_WSPR.TXT >upload.txt

# Clean up dir
mv *.png $htmldir
rm iq_$d.raw $d-ssb-demod.raw wspr-$d3.wav

# Rotate pics in waterfall
wf_n=8
for n in `seq $wf_n -1 2`;do 
    let n2=n-1
    mv $htmldir/$band-wspr-rtl-r$n2.png $htmldir/$band-wspr-rtl-r$n.png 
done
cp $htmldir/$band-wspr-rtl-r.png $htmldir/$band-wspr-rtl-r1.png 

# Upload spots
if [ -s upload.txt ];then 
    echo "Uploading"
    cat upload.txt
    res=$(curl -F allmept=@upload.txt -F call=$call -F grid=$grid --connect-timeout 10 --max-time 30 http://wsprnet.org/meptspots.php)
    status=$?
    echo "return code: $res _ $status"
    if [ $status -eq 0 ]; then
	echo "Successfull upload"
    else
	echo "Failed upload. Queuing spots"
    fi
else
    echo "No spots. No upload"
fi


echo "############################################## END  ##############################################"



