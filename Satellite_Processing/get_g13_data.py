#!/usr/bin/env python
from urllib import request

################################################################################
#
# Title       : GOES13_d20161223t024520_d20161225t234518.py
# Description : This script will download the specified GOES-13 data from
#               the MCFETCH API.
# Author      : SSEC Satellite Data Services
# Date        : 2018-12-21 13:44 UTC
# Usage       : python GOES13_d20161223t024520_d20161225t234518.py
# Notes       : Run this script from the directory in which you want the data.
#               This script must be made executable in order to run.
#                 On linux and mac machines:
#                   chmod a+x GOES13_d20161223t024520_d20161225t234518.py
#
# For obtaining a free MCFETCH API key, please refer to the following link:
# https://mcfetch.ssec.wisc.edu/#register
#
# Search URL:
# https://inventory.ssec.wisc.edu/inventory/#search&start_time:2016-12-23%2000:00;end_time:2016-12-25%2023:59;satellite:GOES-13;type:Imager;coverage:FD;schedule:ROUTINE;
#
# DISCLAIMER: BY USING THIS SCRIPT, YOU WILL BE MAKING DATA REQUESTS TO THE
# MCFETCH SERVER THAT MAY IMPACT THE DATA QUOTA OF YOUR ACCOUNT. IF YOU EXCEED
# THIS QUOTA, YOUR ACCOUNT MAY BECOME LIMITED IN TERMS OF DATA REQUESTS AND
# YOU MIGHT LOSE THE ABILITY TO DOWNLOAD DATA FROM THIS SERVER.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
################################################################################

KEY="c423a98d-03c0-11e9-a6c5-a0369f818cc4"

HTTP="http://mcfetch.ssec.wisc.edu/cgi-bin/mcfetch?dkey={0}&satellite=GOES13&output=NETCDF&size=640+480".format(KEY)

COMMANDS =[
"date=20161223&time=02:45:20&coverage=FD&band=4",
"date=20161223&time=05:45:18&coverage=FD&band=4",
"date=20161223&time=08:45:18&coverage=FD&band=4",
"date=20161223&time=11:45:18&coverage=FD&band=4",
"date=20161223&time=14:45:18&coverage=FD&band=4",
"date=20161223&time=17:45:18&coverage=FD&band=4",
"date=20161223&time=20:45:18&coverage=FD&band=4",
"date=20161223&time=23:45:18&coverage=FD&band=4",
"date=20161224&time=02:45:18&coverage=FD&band=4",
"date=20161224&time=05:45:17&coverage=FD&band=4",
"date=20161224&time=08:45:18&coverage=FD&band=4",
"date=20161224&time=11:45:18&coverage=FD&band=4",
"date=20161224&time=14:45:18&coverage=FD&band=4",
"date=20161224&time=17:45:17&coverage=FD&band=4",
"date=20161224&time=20:45:18&coverage=FD&band=4",
"date=20161224&time=23:45:18&coverage=FD&band=4",
"date=20161225&time=02:45:17&coverage=FD&band=4",
"date=20161225&time=05:45:18&coverage=FD&band=4",
"date=20161225&time=08:45:18&coverage=FD&band=4",
"date=20161225&time=11:45:18&coverage=FD&band=4",
"date=20161225&time=14:45:18&coverage=FD&band=4",
"date=20161225&time=17:45:18&coverage=FD&band=4",
"date=20161225&time=20:45:18&coverage=FD&band=4",
"date=20161225&time=23:45:18&coverage=FD&band=4"
]

FILENAMES=[
"GOES13_d20161223_t024520_b04",
"GOES13_d20161223_t054518_b04",
"GOES13_d20161223_t084518_b04",
"GOES13_d20161223_t114518_b04",
"GOES13_d20161223_t144518_b04",
"GOES13_d20161223_t174518_b04",
"GOES13_d20161223_t204518_b04",
"GOES13_d20161223_t234518_b04",
"GOES13_d20161224_t024518_b04",
"GOES13_d20161224_t054517_b04",
"GOES13_d20161224_t084518_b04",
"GOES13_d20161224_t114518_b04",
"GOES13_d20161224_t144518_b04",
"GOES13_d20161224_t174517_b04",
"GOES13_d20161224_t204518_b04",
"GOES13_d20161224_t234518_b04",
"GOES13_d20161225_t024517_b04",
"GOES13_d20161225_t054518_b04",
"GOES13_d20161225_t084518_b04",
"GOES13_d20161225_t114518_b04",
"GOES13_d20161225_t144518_b04",
"GOES13_d20161225_t174518_b04",
"GOES13_d20161225_t204518_b04",
"GOES13_d20161225_t234518_b04"
]

for i, command in enumerate(COMMANDS):
    request.urlretrieve("{0}&{1}".format(HTTP, command), FILENAMES[i])
