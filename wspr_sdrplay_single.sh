#!/bin/bash

#  This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# 2016: By SM3ULC (David Lundberg, sm3ulc@gmail.com)

# Workdir and htmldir
wd="/home/user/wspr"
htmldir="/var/www/html"
d=$(date -u +"%Y%m%d%H%M")
d2=$(date -u +"%Y-%m-%d %H:%M")
d3=$(date -u +"%Y%m%d-%H%M")
d4=$(date -u +"%y%m%d %H%M")

# Userdata
call=xxxxxx
grid=YYYYxx

# Radio & time
ppm=0
gr=65
dec=50
sr=2400000
fs=10000000
time=115

# Spectrogram 
dBFS=50
dBFS_max=-15
height=1200
width=1000

# Band Width in Hz (default: 1536) possible values: 200 300 600 1536 5000 6000 7000 8000]                                                                                                                                               
bw=1536 

# Bands and freqs to rotate over
bands=(80m 40m 30m 20m) 
freqs_base=(3500000 7000000 10000000 14000000)
freqs_wspr=(3592600 7038600 10138600 14095600)

# Rotate over all bands
let db=$((10#`date +"%M"`));
let db=(db/2)%4

echo Band: $db _ ${bands[$db]}
band=${bands[$db]}

case $band in
    80m)
	fs=3592600
	ft=3500000
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
	echo "Error in case. Going default 30m"
	ft=10138600
	fs=10000000
	;;
esac
cd $wd

echo "############################################## Running $band - iqread ##############################################"

timeout $time /usr/local/bin/play_sdr -x 16  -b $bw -s $sr -f $fs -g $gr iq_$d.raw

echo "############################################## Running $band - wspr ##############################################"
cat iq_$d.raw | \
    csdr convert_s16_f | \
    csdr shift_addition_cc `python -c "print float($fs-$ft)/$sr"` | \
    csdr fir_decimate_cc $dec 0.005 HAMMING | \
    csdr bandpass_fir_fft_cc 0 0.5 0.05 | \
    csdr realpart_cf | \
    csdr agc_ff | \
    csdr limit_ff | \
    csdr convert_f_s16 >$d-ssb-demod.raw

sox -r 48k -e signed -b 16 -c 1 $d-ssb-demod.raw -n rate 48k spectrogram -x $height -Y $width -z $dBFS -Z $dBFS_max -c "$d2 - USB $band - $ft"  -o $band.png  
sox -r 48k -e signed -b 16 -c 1 $d-ssb-demod.raw -n rate 6k  spectrogram -x $height -Y $width -z $dBFS -Z $dBFS_max -c "$d2 - WSPR $band - $ft" -o $band-wspr.png
sox -r 48k -e signed -b 16 -c 1 $d-ssb-demod.raw -r 12k wspr-$d3.wav 
sox -r 48k -e signed -b 16 -c 1 $d-ssb-demod.raw -n stats 2>&1 >$band-stats.txt

# Spectrogram for waterfall
sox -r 48k -e signed -b 16 -c 1 $d-ssb-demod.raw -n rate 4k  spectrogram -x 100 -Y 1500 -z $dBFS -Z $dBFS_max -c "$d2 - PLAY WSPR $band - $ft" -r -o $band-wspr-play-1.png
convert -rotate 90 -flip $band-wspr-play-1.png $band-wspr-play-2.png 
ww=`convert $band-wspr-play-2.png -format "%w" info:` 
convert $band-wspr-play-2.png \( -background none -size ${ww}x -fill white \
    -font Helvetica -pointsize 14 label:"$d2 - $band" \) \
    -gravity north -compose over -composite $band-wspr-play-r.png

wfq=$(echo 'scale=6;'$ft'/1000000' | bc)
echo frevkens: $wfq
/usr/bin/wsprd -f $wfq -w wspr-$d3.wav 
grep "$d4" ALL_WSPR.TXT >upload.txt

mv *.png $htmldir
rm iq_$d.raw $d-ssb-demod.raw wspr-$d3.wav

# Rotate pics in waterfall
wf_n=8
for n in `seq $wf_n -1 2`;do 
    let n2=n-1
    mv $htmldir/$band-wspr-play-r$n2.png $htmldir/$band-wspr-play-r$n.png 
done
cp $htmldir/$band-wspr-play-r.png $htmldir/$band-wspr-play-r1.png 

# Upload spots
if [ -s upload.txt ];then 
    echo "Uploading"
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



