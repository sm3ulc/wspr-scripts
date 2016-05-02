# wspr-scripts

These are scripts for running wspr on rtl-dongles and SDRPlay.

# Installation

## Basic packages

	apt-get install imagemagic sox curl 

##The DSP-parts u  ses csdr which be found here

    csdr - https://rtgithub.com/simonyiszk/csdr

##For the RTL-SDR dongles:

    https://github.com/keenerd/rtl-sdr

##For the SDRPlay

    https://github.com/krippendorf/SDRPlayPorts

##WSPR-decoder

Install latest WSJT and check that wsprd is reachable rom the shell. 

https://sourceforge.net/projects/wsjt/files/

A minimal installation can be made by downloading and unpacking of the
sourcecode and just compiling the decoder itself:

	   wget "https://sourceforge.net/projects/wsjt/files/wsjtx-1.6.0/wsjtx-1.6.0.tgz/download"
	   tar -xvf wsjtx-1.6.0.tgz
	   cd wsjtx-1.6.0-rc1/src/wsjtx/lib/wsprd
	   make
	   sudo cp wsprd /usr/local/bin


Finally. Download scriptfiles and change call and grid and working/data
directories! For troubleshooting/calibration there's output to
different spectrograms which preferably can be viewed via the included
webpages.


# Usage


Crontab:

	*/2 * * * /wsprdir/script.sh

To redirect all output including stderr to a logfile and add timestamps

	script.sh 2>&1 | ts "%Y-%m-%d %H:%M:%S" >>dir/run.log

# Todo

* queuing of uploads for the simes when wsprnet is out of reach

# Issues

When running with standard RTL-dongle the frequencydrift is too high
if run from within the script. Therefor one has start rtl_tcp
separately in order to not let it cool down.

## Licence

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
